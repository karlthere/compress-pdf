import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/pdf_item.dart';

/// Engine Pemroses Kompresi PDF Native Berbasis PyMuPDF & Physical File Sync
class PdfCompressorService {
  /// Resolusi Path Script Python compress_engine.py secara absolut & robust (Debug & Release Bundle)
  static String _resolveEngineScriptPath() {
    final exeDir = p.dirname(Platform.resolvedExecutable);

    // 1. Path pada Windows Release App Bundle (data/flutter_assets/compress_engine.py)
    final winAssetPath = p.join(exeDir, 'data', 'flutter_assets', 'compress_engine.py');
    if (File(winAssetPath).existsSync()) return winAssetPath;

    // 2. Path pada macOS Release App Bundle (../Resources/flutter_assets/compress_engine.py)
    final macAssetPath = p.canonicalize(p.join(exeDir, '..', 'Resources', 'flutter_assets', 'compress_engine.py'));
    if (File(macAssetPath).existsSync()) return macAssetPath;

    // 3. Cek di Directory.current (Project Root)
    final candidate1 = p.join(Directory.current.path, 'compress_engine.py');
    if (File(candidate1).existsSync()) return candidate1;

    // 4. Absolute fallback ke lokasi project local
    const candidate2 = r'd:\Coder\Project\compress-pdf\compress_engine.py';
    if (File(candidate2).existsSync()) return candidate2;

    return candidate1;
  }

  /// Buka folder atau sorot file spesifik di File Explorer (Windows) atau Finder (macOS)
  static Future<void> openInFileExplorer(String path, {bool selectFile = false}) async {
    try {
      final target = FileSystemEntity.typeSync(path);
      if (target == FileSystemEntityType.notFound) return;

      if (Platform.isWindows) {
        if (selectFile && target == FileSystemEntityType.file) {
          await Process.run('explorer.exe', ['/select,', path]);
        } else {
          final dirPath = (target == FileSystemEntityType.file) ? p.dirname(path) : path;
          await Process.run('explorer.exe', [dirPath]);
        }
      } else if (Platform.isMacOS) {
        if (selectFile && target == FileSystemEntityType.file) {
          await Process.run('open', ['-R', path]);
        } else {
          final dirPath = (target == FileSystemEntityType.file) ? p.dirname(path) : path;
          await Process.run('open', [dirPath]);
        }
      } else if (Platform.isLinux) {
        final dirPath = (target == FileSystemEntityType.file) ? p.dirname(path) : path;
        await Process.run('xdg-open', [dirPath]);
      }
    } catch (e) {
      stderr.writeln('Gagal membuka file explorer: $e');
    }
  }

  /// Memproses kompresi fisik PDF secara nyata di disk dan membaca ukuran fisik file asli
  static Future<bool> compressPdfItem({
    required PdfItemModel item,
    required Function(PdfItemModel updatedItem) onItemUpdate,
  }) async {
    // 1. Buat folder direktori tujuan jika belum ada
    final targetDir = Directory(p.dirname(item.outputPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final double limitMb = item.maxMbLimit;
    final int limitInBytes = (limitMb * 1024 * 1024).round();

    // 2. Jika ukuran file awal sudah <= limit MB, salin langsung tanpa perlu kompresi
    if (item.originalSize <= limitInBytes) {
      item.status = ProcessingStatus.copying;
      item.statusText = 'Disalin (≤ ${limitMb.toStringAsFixed(1)} MB)';
      item.tierLabel = 'Direct Copy';
      onItemUpdate(item);

      await File(item.inputPath).copy(item.outputPath);

      final realFile = File(item.outputPath);
      item.compressedSize = await realFile.exists() ? await realFile.length() : item.originalSize;
      item.status = ProcessingStatus.skipped;
      item.statusText = 'Aman (≤ ${limitMb.toStringAsFixed(1)} MB)';
      item.progress = 1.0;
      onItemUpdate(item);
      return true;
    }

    // 3. Jalankan Kompresi Fisik dengan Engine PyMuPDF Loop Terus Hingga <= Target MB
    item.status = ProcessingStatus.compressing;
    item.statusText = 'Mengompresi PDF (Target ≤ ${limitMb.toStringAsFixed(1)} MB)...';
    item.tierLabel = 'PyMuPDF Engine Loop';
    item.progress = 0.3;
    onItemUpdate(item);

    final scriptPath = _resolveEngineScriptPath();

    try {
      // Coba jalankan dengan 'python3', 'python', atau 'py'
      ProcessResult result;
      try {
        result = await Process.run('python3', [
          scriptPath,
          item.inputPath,
          item.outputPath,
          limitMb.toString(),
        ]);
      } catch (_) {
        try {
          result = await Process.run('python', [
            scriptPath,
            item.inputPath,
            item.outputPath,
            limitMb.toString(),
          ]);
        } catch (_) {
          result = await Process.run('py', [
            scriptPath,
            item.inputPath,
            item.outputPath,
            limitMb.toString(),
          ]);
        }
      }

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final Map<String, dynamic> jsonResult = jsonDecode(result.stdout.toString().trim());

        final String tier = jsonResult['tier'] ?? 'Compressed';

        // BACA UKURAN FISIK ASLI PADA DISK WINDOWS / MACOS (DIJAMIN 100% SAMA DENGAN FILE MANAGER)
        final outputFile = File(item.outputPath);
        if (await outputFile.exists()) {
          item.compressedSize = await outputFile.length();
        } else {
          item.compressedSize = jsonResult['compressed_bytes'] ?? item.originalSize;
        }

        item.tierLabel = tier;
        item.progress = 1.0;

        if (item.compressedSize <= limitInBytes) {
          item.status = ProcessingStatus.completed;
          item.statusText = 'Sukses ($tier)';
          onItemUpdate(item);
          return true;
        } else {
          item.status = ProcessingStatus.completed;
          item.statusText = 'Hasil Maksimal (${item.compressedMb.toStringAsFixed(2)} MB)';
          onItemUpdate(item);
          return false;
        }
      } else {
        stderr.writeln('Python Exec Error: ${result.stderr}');
        await File(item.inputPath).copy(item.outputPath);
        final outputFile = File(item.outputPath);
        item.compressedSize = await outputFile.exists() ? await outputFile.length() : item.originalSize;
        item.status = ProcessingStatus.failed;
        item.statusText = 'Gagal Kompresi (File Asli Disalin)';
        item.progress = 1.0;
        onItemUpdate(item);
        return false;
      }
    } catch (e) {
      stderr.writeln('Error invoking python process: $e');
      await File(item.inputPath).copy(item.outputPath);
      final outputFile = File(item.outputPath);
      item.compressedSize = await outputFile.exists() ? await outputFile.length() : item.originalSize;
      item.status = ProcessingStatus.failed;
      item.statusText = 'Fallback (File Asli Disalin)';
      item.progress = 1.0;
      onItemUpdate(item);
      return false;
    }
  }
}
