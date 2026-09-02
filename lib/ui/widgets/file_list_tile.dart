import 'package:flutter/material.dart';
import '../../models/pdf_item.dart';
import '../../services/pdf_compressor_service.dart';
import '../theme/app_theme.dart';

/// Widget item list file PDF terdeteksi dengan badge status, progress, dan tombol Buka File
class FileListTile extends StatelessWidget {
  final PdfItemModel item;

  const FileListTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isOverLimit = item.isOverLimit;
    final bool isDone = item.status == ProcessingStatus.completed ||
        item.status == ProcessingStatus.skipped;

    Color badgeBgColor;
    Color badgeTextColor;
    IconData statusIcon;

    switch (item.status) {
      case ProcessingStatus.completed:
        badgeBgColor = AppTheme.emeraldSuccess.withOpacity(0.15);
        badgeTextColor = AppTheme.emeraldSuccess;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ProcessingStatus.skipped:
        badgeBgColor = Colors.blue.shade50;
        badgeTextColor = AppTheme.royalBlue;
        statusIcon = Icons.info_rounded;
        break;
      case ProcessingStatus.compressing:
      case ProcessingStatus.copying:
        badgeBgColor = AppTheme.electricBlue.withOpacity(0.15);
        badgeTextColor = AppTheme.electricBlue;
        statusIcon = Icons.sync_rounded;
        break;
      case ProcessingStatus.failed:
        badgeBgColor = AppTheme.roseError.withOpacity(0.15);
        badgeTextColor = AppTheme.roseError;
        statusIcon = Icons.error_rounded;
        break;
      case ProcessingStatus.pending:
      default:
        badgeBgColor = isOverLimit
            ? AppTheme.amberWarning.withOpacity(0.15)
            : Colors.grey.shade200;
        badgeTextColor = isOverLimit ? AppTheme.amberWarning : Colors.grey.shade700;
        statusIcon = isOverLimit ? Icons.compress_rounded : Icons.copy_all_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverLimit
                  ? AppTheme.amberWarning.withOpacity(0.12)
                  : AppTheme.electricBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: isOverLimit ? AppTheme.amberWarning : AppTheme.electricBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Awal: ${item.originalMb.toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (item.compressedSize > 0 && item.compressedSize != item.originalSize) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.emeraldSuccess),
                      const SizedBox(width: 4),
                      Text(
                        '${item.compressedMb.toStringAsFixed(2)} MB (${item.savedPercent.toStringAsFixed(0)}% hemat)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldSuccess,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Badge Status Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: badgeTextColor),
                const SizedBox(width: 6),
                Text(
                  item.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Buka File (jika sudah selesai)
          if (isDone) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Buka lokasi file di Explorer / Finder',
              icon: const Icon(Icons.folder_open_rounded, size: 20, color: AppTheme.electricBlue),
              onPressed: () {
                PdfCompressorService.openInFileExplorer(item.outputPath, selectFile: true);
              },
            ),
          ],
        ],
      ),
    );
  }
}
