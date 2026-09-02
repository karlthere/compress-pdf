class ScanStatsModel {
  int totalScanned;
  int totalOverLimit;
  int totalDirectCopy;
  int totalProcessed;
  int totalSuccess;
  int totalFailed;
  int totalOriginalBytes;
  int totalCompressedBytes;
  double elapsedSeconds;

  ScanStatsModel({
    this.totalScanned = 0,
    this.totalOverLimit = 0,
    this.totalDirectCopy = 0,
    this.totalProcessed = 0,
    this.totalSuccess = 0,
    this.totalFailed = 0,
    this.totalOriginalBytes = 0,
    this.totalCompressedBytes = 0,
    this.elapsedSeconds = 0.0,
  });

  void reset() {
    totalScanned = 0;
    totalOverLimit = 0;
    totalDirectCopy = 0;
    totalProcessed = 0;
    totalSuccess = 0;
    totalFailed = 0;
    totalOriginalBytes = 0;
    totalCompressedBytes = 0;
    elapsedSeconds = 0.0;
  }

  double get originalMb => totalOriginalBytes / (1024 * 1024);
  double get compressedMb => totalCompressedBytes / (1024 * 1024);
  double get savedMb => (totalOriginalBytes - totalCompressedBytes) / (1024 * 1024);

  double get savedPercentage {
    if (totalOriginalBytes <= 0 || totalCompressedBytes >= totalOriginalBytes) {
      return 0.0;
    }
    return ((totalOriginalBytes - totalCompressedBytes) / totalOriginalBytes) * 100;
  }
}
