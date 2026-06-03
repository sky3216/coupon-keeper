import 'image_copy_store.dart';

class FakeImageCopyStore implements ImageCopyStore {
  final Map<String, String> _copies = {};
  final Map<String, String> _fingerprintPaths = {};
  int _nextId = 0;
  Object? copyError;

  Map<String, String> get copies => Map.unmodifiable(_copies);

  @override
  Future<ImageCopyResult> copyIntoAppStorage(
    String sourceRef, {
    required String fingerprint,
    String? id,
  }) async {
    final error = copyError;
    if (error != null) {
      if (error is Exception) {
        throw error;
      }
      throw StateError(error.toString());
    }
    final existingPath = _fingerprintPaths[fingerprint];
    if (existingPath != null && _copies.containsKey(existingPath)) {
      return ImageCopyResult(path: existingPath, created: false);
    }

    final copyId = id ?? 'copy-${_nextId++}';
    final path = 'app://copies/$copyId.jpg';
    _copies[path] = sourceRef;
    _fingerprintPaths[fingerprint] = path;
    return ImageCopyResult(path: path, created: true);
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
    _fingerprintPaths.removeWhere((_, path) => path == imageCopyPath);
  }
}
