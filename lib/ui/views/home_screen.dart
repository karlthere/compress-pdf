import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../models/pdf_item.dart';
import '../../models/scan_stats.dart';
import '../../services/file_scanner_service.dart';
import '../../services/pdf_compressor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/stat_item_card.dart';
import '../widgets/file_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PdfItemModel> _tasks = [];
  final ScanStatsModel _stats = ScanStatsModel();
  final ScrollController _fileListScrollController = ScrollController();

  bool _isScanning = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = 'Pilih File atau Folder untuk memulai pemindaian.';
  String? _selectedSourcePath;
  String? _lastOutputFolderPath;

  // Ukuran aman dinamis (Default 2.0 MB)
  double _selectedMaxMbLimit = 2.0;
  final TextEditingController _customLimitController = TextEditingController(text: '2.0');

  final List<double> _presetMbLimits = [1.0, 2.0, 5.0, 10.0];

  @override
  void dispose() {
    _customLimitController.dispose();
    _fileListScrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // RESET SELECTION & UPLOAD BARU
  // ===========================================================================
  void _resetSelection() {
    setState(() {
      _tasks.clear();
      _stats.reset();
      _isScanning = false;
      _isProcessing = false;
      _progress = 0.0;
      _selectedSourcePath = null;
      _lastOutputFolderPath = null;
      _statusMessage = 'Pilihan dibersihkan. Silakan upload atau pilih file/folder baru.';
    });
    _showSnackbar('Siap memilih file atau folder baru!');
  }

  /// Update limit MB dinamis dan hitung ulang status item
  void _updateMaxMbLimit(double newLimit) {
    setState(() {
      _selectedMaxMbLimit = newLimit;
      _customLimitController.text = newLimit.toStringAsFixed(1);

      int overLimit = 0;
      int directCopy = 0;
      for (var item in _tasks) {
        item.maxMbLimit = newLimit;
        if (item.isOverLimit) {
          overLimit++;
        } else {
          directCopy++;
        }
      }
      _stats.totalOverLimit = overLimit;
      _stats.totalDirectCopy = directCopy;
    });
  }

  // ===========================================================================
  // HANDLERS: USER PATH INPUT
  // ===========================================================================

  Future<void> _handlePickFiles() async {
    try {
      debugPrint('Tombol Pilih File diklik!');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pilih File PDF Target',
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.paths.isNotEmpty) {
        final validPaths = result.paths.whereType<String>().toList();
        if (validPaths.isNotEmpty) {
          await _executeScan(paths: validPaths, isDirectory: false);
        }
      }
    } catch (e) {
      debugPrint('Error pickFiles: $e');
      _showSnackbar('Error membuka file picker: $e', isError: true);
    }
  }

  Future<void> _handlePickFolder() async {
    try {
      debugPrint('Tombol Pilih Folder diklik!');
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Folder Direktori PDF',
      );
      debugPrint('Hasil folder picker: $selectedDirectory');
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        await _executeScan(paths: [selectedDirectory], isDirectory: true);
      }
    } catch (e) {
      debugPrint('Error getDirectoryPath: $e');
      _showSnackbar('Error membuka folder picker: $e', isError: true);
    }
  }

  /// Eksekusi pemindaian Asynchronous 100% tanpa limit
  Future<void> _executeScan({required List<String> paths, required bool isDirectory}) async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Memindai 100% direktori & file tanpa batas...';
      _tasks.clear();
      _stats.reset();
      _progress = 0.0;
      _selectedSourcePath = paths.length == 1 ? paths.first : '${paths.length} file dipilih';
    });

    final scannedItems = await FileScannerService.scanTarget(
      paths: paths,
      isDirectory: isDirectory,
      maxMbLimit: _selectedMaxMbLimit,
      onProgress: (count, currentPath) {
        setState(() {
          _statusMessage = 'Memindai: $count file PDF terdeteksi...';
        });
      },
    );

    int overLimit = 0;
    int directCopy = 0;
    int totalOrigBytes = 0;

    for (var item in scannedItems) {
      totalOrigBytes += item.originalSize;
      if (item.isOverLimit) {
        overLimit++;
      } else {
        directCopy++;
      }
    }

    String outputFolder = isDirectory
        ? p.join(paths.first, 'Compressed')
        : p.join(p.dirname(paths.first), 'Compressed');

    setState(() {
      _tasks = scannedItems;
      _lastOutputFolderPath = outputFolder;
      _stats.totalScanned = scannedItems.length;
      _stats.totalOverLimit = overLimit;
      _stats.totalDirectCopy = directCopy;
      _stats.totalOriginalBytes = totalOrigBytes;
      _isScanning = false;
      _statusMessage = scannedItems.isEmpty
          ? 'Tidak ada file PDF ditemukan.'
          : 'Pemindaian 100% selesai. Terdeteksi ${scannedItems.length} file PDF.';
    });
  }

  // ===========================================================================
  // EXECUTE PHYSICAL PDF COMPRESSION PIPELINE (REAL DISK SYNC)
  // ===========================================================================

  Future<void> _startCompressionProcess() async {
    if (_tasks.isEmpty || _isProcessing) return;

    final stopwatch = Stopwatch()..start();

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = '🚀 Memulai Kompresi Fisik Nyata (Target ≤ ${_selectedMaxMbLimit.toStringAsFixed(1)} MB)...';
    });

    int totalItems = _tasks.length;
    int totalCompressedBytes = 0;

    for (int i = 0; i < totalItems; i++) {
      final item = _tasks[i];

      setState(() {
        _statusMessage = 'Mengompresi (${i + 1}/$totalItems): ${item.fileName}...';
        _progress = (i) / totalItems;
      });

      // Panggil PyMuPDF Engine fisik nyata yang melakukan Pass 1 & Pass 2 Progressive Loop
      await PdfCompressorService.compressPdfItem(
        item: item,
        onItemUpdate: (updatedItem) {
          setState(() {
            _tasks[i] = updatedItem;
          });
        },
      );

      totalCompressedBytes += item.compressedSize;

      setState(() {
        _progress = (i + 1) / totalItems;
        _stats.totalProcessed = i + 1;
        _stats.totalCompressedBytes = totalCompressedBytes;
      });
    }

    // VERIFIKASI FISIK ULANG FISIK PADA DISK 100% UNTUK METRIK UTAMA
    int finalOverLimit = 0;
    int finalBytesOnDisk = 0;
    for (var item in _tasks) {
      final file = File(item.outputPath);
      if (await file.exists()) {
        final realSize = await file.length();
        item.compressedSize = realSize;
        finalBytesOnDisk += realSize;
        if (item.isOverLimit) {
          finalOverLimit++;
        }
      }
    }

    stopwatch.stop();

    setState(() {
      _isProcessing = false;
      _progress = 1.0;
      _stats.totalProcessed = totalItems;
      _stats.totalOverLimit = finalOverLimit;
      _stats.totalCompressedBytes = finalBytesOnDisk;
      _stats.elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      _statusMessage = '🎉 Selesai! Ukuran file fisik terverifikasi sama di File Explorer (${_stats.savedMb.toStringAsFixed(2)} MB dihemat).';
    });

    _showSnackbar('Seluruh file terkompresi secara fisik & terverifikasi 100% dengan File Explorer!');
  }

  Future<void> _openOutputFolder() async {
    if (_lastOutputFolderPath != null && _lastOutputFolderPath!.isNotEmpty) {
      await PdfCompressorService.openInFileExplorer(_lastOutputFolderPath!);
    } else {
      _showSnackbar('Folder hasil belum tersedia. Lakukan pemindaian dahulu.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppTheme.roseError : AppTheme.electricBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===========================================================================
  // BENTO DASHBOARD UI BUILD (RESPONSIVE SCROLLABLE LAYOUT)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.pearlGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. TOP HEADER & BRANDING
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.electricGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x330066FF),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'web/favicon.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.white,
                                  size: 28,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PDF Squeezer Desktop',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            Text(
                              'Help you compress PDF files quickly and easily',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Version Tag & Quick Action Buka Folder Output
                    Row(
                      children: [
                        if (_lastOutputFolderPath != null) ...[
                          GlassButton(
                            label: 'Buka Folder Hasil',
                            icon: Icons.folder_special_rounded,
                            isPrimary: false,
                            onPressed: _openOutputFolder,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 16, color: AppTheme.electricBlue),
                              SizedBox(width: 6),
                              Text(
                                'v1.2 Native Desktop',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.royalBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 2. INPUT CONTROL CARD (File, Folder, Reset & Setting Limit MB)
                // -------------------------------------------------------------
                BentoCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GlassButton(
                            label: 'Pilih File',
                            icon: Icons.insert_drive_file_rounded,
                            isPrimary: true,
                            isLoading: _isScanning,
                            onPressed: (_isScanning || _isProcessing) ? null : _handlePickFiles,
                          ),
                          const SizedBox(width: 12),

                          GlassButton(
                            label: 'Pilih Folder',
                            icon: Icons.folder_open_rounded,
                            isPrimary: false,
                            isLoading: _isScanning,
                            onPressed: (_isScanning || _isProcessing) ? null : _handlePickFolder,
                          ),
                          const SizedBox(width: 12),

                          Tooltip(
                            message: 'Bersihkan pilihan dan upload file/folder baru',
                            child: GlassButton(
                              label: 'Pilih Ulang',
                              icon: Icons.refresh_rounded,
                              isPrimary: false,
                              onPressed: (_isScanning || _isProcessing) ? null : _resetSelection,
                            ),
                          ),

                          const SizedBox(width: 16),
                          const SizedBox(
                            height: 28,
                            child: VerticalDivider(width: 1, color: AppTheme.glassBorder),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TARGET PATH SEKARANG:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedSourcePath ?? 'Belum ada file/folder terpilih',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.glassBorder),
                      const SizedBox(height: 12),

                      // SETTING LIMIT UKURAN AMAN DINAMIS (MB)
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: AppTheme.electricBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Batas Ukuran Aman (MB):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 14),

                          ..._presetMbLimits.map((preset) {
                            final bool isSelected = _selectedMaxMbLimit == preset;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('${preset.toStringAsFixed(0)} MB'),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  if (selected) _updateMaxMbLimit(preset);
                                },
                                selectedColor: AppTheme.electricBlue,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.electricBlue : AppTheme.glassBorder,
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            height: 36,
                            child: TextField(
                              controller: _customLimitController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Kustom MB',
                                labelStyle: const TextStyle(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSubmitted: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  _updateMaxMbLimit(parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(File > ${_selectedMaxMbLimit.toStringAsFixed(1)} MB akan dikompresi)',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // 3. BENTO BOX STATISTICS GRID (4 Cards)
                // -------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: StatItemCard(
                        title: 'Total Scanned',
                        value: '${_stats.totalScanned}',
                        subtitle: '100% File PDF Terbaca',
                        icon: Icons.search_rounded,
                        accentColor: AppTheme.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: StatItemCard(
                        title: 'Perlu Kompresi',
                        value: '${_stats.totalOverLimit}',
                        subtitle: 'Ukuran > ${_selectedMaxMbLimit.toStringAsFixed(1)} MB',
                        icon: Icons.tune_rounded,
                        accentColor: AppTheme.amberWarning,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: StatItemCard(
                        title: 'Langsung Disalin',
                        value: '${_stats.totalDirectCopy}',
                        subtitle: 'Aman ≤ ${_selectedMaxMbLimit.toStringAsFixed(1)} MB',
                        icon: Icons.file_copy_rounded,
                        accentColor: AppTheme.emeraldSuccess,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: StatItemCard(
                        title: 'Ruang Dihemat',
                        value: '${_stats.savedMb.toStringAsFixed(1)} MB',
                        subtitle: '${_stats.savedPercentage.toStringAsFixed(0)}% Penghematan',
                        icon: Icons.speed_rounded,
                        accentColor: AppTheme.royalBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // 4. PROGRESS & STATUS BAR CARD
                // -------------------------------------------------------------
                BentoCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (_isProcessing || _isScanning)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.electricBlue),
                                  ),
                                )
                              else
                                const Icon(Icons.info_outline_rounded,
                                    size: 18, color: AppTheme.royalBlue),
                              const SizedBox(width: 10),
                              Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_lastOutputFolderPath != null && !_isProcessing) ...[
                                TextButton.icon(
                                  onPressed: _openOutputFolder,
                                  icon: const Icon(Icons.folder_special_rounded, size: 18),
                                  label: const Text(
                                    'Buka Folder Hasil',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.electricBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.electricBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: Colors.blue.shade50,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // 5. DAFTAR FILE PDF TERDETEKSI (FIXED SPACIOUS SCROLLABLE CONTAINER)
                // -------------------------------------------------------------
                BentoCard(
                  padding: const EdgeInsets.all(18),
                  height: 460, // Ketinggian luas & lega untuk daftar file
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.list_alt_rounded, color: AppTheme.electricBlue, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Daftar File PDF Terdeteksi (${_tasks.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_lastOutputFolderPath != null && !_isProcessing) ...[
                                GlassButton(
                                  label: 'Buka Folder Output',
                                  icon: Icons.folder_open_rounded,
                                  isPrimary: false,
                                  onPressed: _openOutputFolder,
                                ),
                                const SizedBox(width: 10),
                              ],
                              GlassButton(
                                label: 'Mulai Kompresi PDF',
                                icon: Icons.play_arrow_rounded,
                                isPrimary: true,
                                isLoading: _isProcessing,
                                onPressed: (_tasks.isEmpty || _isProcessing || _isScanning)
                                    ? null
                                    : _startCompressionProcess,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.glassBorder),
                      const SizedBox(height: 12),

                      Expanded(
                        child: _tasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'web/favicon.png',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.folder_zip_outlined,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada file yang dipindai.',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Klik [Pilih File] atau [Pilih Folder] di atas.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Scrollbar(
                                controller: _fileListScrollController,
                                thumbVisibility: true, // Selalu menampilkan scrollbar di desktop
                                trackVisibility: true,
                                child: ListView.builder(
                                  controller: _fileListScrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _tasks.length,
                                  itemBuilder: (context, index) {
                                    return FileListTile(item: _tasks[index]);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}