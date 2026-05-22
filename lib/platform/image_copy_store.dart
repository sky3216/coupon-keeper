abstract class ImageCopyStore {
  Future<String> copyIntoAppStorage(String sourceRef, {String? id});
  Future<String?> resolveImagePath(String imageCopyPath);
  Future<void> deleteCopy(String imageCopyPath);
}
