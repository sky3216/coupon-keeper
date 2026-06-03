class ImageCopyResult {
  const ImageCopyResult({required this.path, required this.created});

  final String path;
  final bool created;
}

abstract class ImageCopyStore {
  Future<ImageCopyResult> copyIntoAppStorage(
    String sourceRef, {
    required String fingerprint,
    String? id,
  });
  Future<String?> resolveImagePath(String imageCopyPath);
  Future<void> deleteCopy(String imageCopyPath);
}
