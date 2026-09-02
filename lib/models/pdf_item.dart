import 'package:path/path.dart' as p;

enum ProcessingStatus {
  pending,
  copying,
  compressing,
  completed,
  failed,
  skipped
}

class PdfItemModel {
  final String inputPath;
  final String outputPath;
  final int originalSize;
  int compressedSize;
  ProcessingStatus status;
  String statusText;
  String tierLabel;
  double progress;
  double maxMbLimit; // Dynamic limit set by user in MB

  PdfItemModel({
    required this.inputPath,
    required this.outputPath,
    required this.originalSize,
    this.compressedSize = 0,
    this.status = ProcessingStatus.pending,
    this.statusText = 'Diantrean',
    this.tierLabel = 'Pending',
    this.progress = 0.0,
    this.maxMbLimit = 2.0, // Default 2.0 MB
  });

  /// True jika ukuran file melebihi limit MB dinamis yang ditentukan user
  bool get isOverLimit => originalSize > (maxMbLimit * 1024 * 1024);
  
  String get fileName => p.basename(inputPath);
  
  String get relativePath {
    final parent = p.basename(p.dirname(inputPath));
    return p.join(parent, fileName);
  }

  double get originalMb => originalSize / (1024 * 1024);
  double get compressedMb => compressedSize / (1024 * 1024);

  double get savedPercent {
    if (originalSize == 0 || compressedSize == 0 || compressedSize >= originalSize) {
      return 0.0;
    }
    return ((originalSize - compressedSize) / originalSize) * 100;
  }
}
