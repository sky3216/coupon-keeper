import 'image_copy_store.dart';

class FakeImageCopyStore implements ImageCopyStore {
  final Map<String, String> _copies = {};
  int _nextId = 0;

  @override
  Future<String> copyIntoAppStorage(String sourceRef, {String? id}) async {
    final copyId = id ?? 'copy-${_nextId++}';
    final path = 'app://copies/$copyId.jpg';
    _copies[path] = sourceRef;
    return path;
  }

  @override
  Future<String?> resolveImagePath(String imageCopyPath) async {
    if (_copies.containsKey(imageCopyPath)) {
      return imageCopyPath;
    }
    return null;
  }

  @override
  Future<void> deleteCopy(String imageCopyPath) async {
    _copies.remove(imageCopyPath);
  }
}
