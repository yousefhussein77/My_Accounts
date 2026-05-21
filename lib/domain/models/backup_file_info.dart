class BackupFileInfo {
  const BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.modifiedAt,
    required this.sizeBytes,
    required this.isEncrypted,
    required this.isSafetyCopy,
  });

  final String path;
  final String fileName;
  final DateTime modifiedAt;
  final int sizeBytes;
  final bool isEncrypted;
  final bool isSafetyCopy;
}
