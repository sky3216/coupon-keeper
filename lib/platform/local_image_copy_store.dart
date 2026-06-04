import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/sqlite_image_copy_registry.dart';
import 'image_copy_store.dart';

class LocalImageCopyStore implements ImageCopyStore {
  LocalImageCopyStore({
    required this.registry,
    Future<Directory> Function()? supportDirectory,
    String Function()? nextId,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _nextId = nextId ?? _defaultNextId;

  final SqliteImageCopyRegistry registry;
  final Future<Directory> Function() _supportDirectory;
  final String Function() _nextId;

  @override
  Future<ImageCopyResult> copyIntoAppStorage(
    String sourceRef, {
    required String fingerprint,
    String? id,
  }) async {
    final existing = await registry.findByFingerprint(fingerprint);
    if (existing != null) {
      final existingFile = _fileFromStoredPath(existing.path);
      if (await existingFile.exists()) {
        return ImageCopyResult(path: existing.path, created: false);
      }
      await registry.deleteByFingerprint(fingerprint);
    }

    final source = _fileFromSourceRef(sourceRef);
    final root = await _supportDirectory();
    final copiesDir = Directory(p.join(root.path, 'coupon-images'));
    await copiesDir.create(recursive: true);

    final copyId = id ?? _nextId();
    final destination = File(p.join(copiesDir.path, '$copyId.image'));
    await source.copy(destination.path);
    final storedPath = destination.uri.toString();
    await registry.save(fingerprint: fingerprint, path: storedPath);
    return ImageCopyResult(path: storedPath, created: true);
  }

  @override
  Future<String?> resolveImagePath(String imageCopyPath) async {
    final file = _fileFromStoredPath(imageCopyPath);
    if (await file.exists()) {
      return file.uri.toString();
    }
    return null;
  }

  @override
  Future<void> deleteCopy(String imageCopyPath) async {
    final file = _fileFromStoredPath(imageCopyPath);
    if (await file.exists()) {
      await file.delete();
    }
    await registry.deleteByPath(imageCopyPath);
  }

  File _fileFromSourceRef(String sourceRef) {
    final uri = Uri.tryParse(sourceRef);
    if (uri == null || uri.scheme != 'file') {
      throw ArgumentError.value(
        sourceRef,
        'sourceRef',
        'LocalImageCopyStore expects a staged file:// source reference.',
      );
    }
    return File.fromUri(uri);
  }

  File _fileFromStoredPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return File.fromUri(uri);
    }
    return File(path);
  }

  static String _defaultNextId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
