import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/pdf_item.dart';

/// Service untuk memindai file dan folder secara Asynchronous (100% Full Scan Tanpa Limit)
class FileScannerService {
  /// Memindai 100% direktori atau list file secara komprehensif dengan limit MB dinamis
  static Future<List<PdfItemModel>> scanTarget({
    required List<String> paths,
    required bool isDirectory,
    double maxMbLimit = 2.0,
    Function(int scannedCount, String currentPath)? onProgress,
  }) async {
    final List<PdfItemModel> taskList = [];
    int scannedCount = 0;

    if (!isDirectory) {
      // Memindai berkas-berkas spesifik yang dipilih via File Picker
      for (final filePath in paths) {
        final file = File(filePath);
        if (await file.exists() && filePath.toLowerCase().endsWith('.pdf')) {
          try {
            final size = await file.length();
            final outputDir = p.join(p.dirname(filePath), 'Compressed');
            final outputPath = p.join(outputDir, p.basename(filePath));

            taskList.add(PdfItemModel(
              inputPath: filePath,
              outputPath: outputPath,
              originalSize: size,
              maxMbLimit: maxMbLimit,
            ));
            
            scannedCount++;
            if (onProgress != null) {
              onProgress(scannedCount, filePath);
            }
          } catch (e) {
            // Lewati file yang terkunci/gagal dibaca
          }
        }
      }
    } else if (paths.isNotEmpty) {
      // Memindai folder secara rekursif 100% tanpa pembatasan kuota
      final targetFolder = paths.first;
      final dir = Directory(targetFolder);
      final outputFolder = p.join(targetFolder, 'Compressed');

      if (await dir.exists()) {
        // PERBAIKAN UTAMA: .handleError() mencegah scanning berhenti akibat permission error
        final stream = dir.list(recursive: true, followLinks: false).handleError((error) {
          stderr.writeln('Akses dilewati (Permission/Lock Error): $error');
        });

        await for (final entity in stream) {
          if (entity is File) {
            final path = entity.path;

            // Abort jika path berada di dalam folder output Compressed itu sendiri
            if (p.split(path).contains('Compressed')) continue;

            // Filter file PDF
            if (path.toLowerCase().endsWith('.pdf') && !path.endsWith('.temp')) {
              try {
                final size = await entity.length();
                final relativePath = p.relative(path, from: targetFolder);
                final outputPath = p.join(outputFolder, relativePath);

                taskList.add(PdfItemModel(
                  inputPath: path,
                  outputPath: outputPath,
                  originalSize: size,
                  maxMbLimit: maxMbLimit,
                ));

                scannedCount++;
                if (onProgress != null) {
                  onProgress(scannedCount, path);
                }
              } catch (e) {
                // Lewati file individual yang corrupt/terkunci
              }
            }
          }
        }
      }
    }

    return taskList;
  }
}