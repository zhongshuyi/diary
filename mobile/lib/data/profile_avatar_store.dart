import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProfileAvatarStore {
  ProfileAvatarStore({this.rootDirectory});

  final Directory? rootDirectory;

  Future<String> importFile(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('头像文件不可用', sourcePath);
    }
    final root = await _root();
    await root.create(recursive: true);
    final extension = _safeExtension(source.path);
    final destination = File(p.join(root.path, _fileName(extension)));
    final staging = File('${destination.path}.tmp');
    try {
      await source.copy(staging.path);
      return await _commit(root, destination, staging);
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

  Future<String> savePng(Uint8List bytes) async {
    if (bytes.isEmpty) throw ArgumentError.value(bytes, 'bytes', '头像数据为空');
    final root = await _root();
    await root.create(recursive: true);
    final destination = File(p.join(root.path, _fileName('.png')));
    final staging = File('${destination.path}.tmp');
    try {
      await staging.writeAsBytes(bytes, flush: true);
      return await _commit(root, destination, staging);
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

  Future<void> clear() async {
    final root = await _root();
    if (!await root.exists()) return;
    await _removeOtherAvatars(root);
  }

  Future<Directory> _root() async {
    return rootDirectory ??
        Directory(
          p.join(
            (await getApplicationSupportDirectory()).path,
            'diary',
            'profile-avatar',
          ),
        );
  }

  Future<void> _removeOtherAvatars(Directory root, {String? keep}) async {
    await for (final entity in root.list()) {
      if (entity is! File ||
          p.normalize(entity.path) == p.normalize(keep ?? '')) {
        continue;
      }
      if (_isAvatarFile(entity.path)) {
        await entity.delete();
      }
    }
  }

  Future<String> _commit(Directory root, File destination, File staging) async {
    await staging.rename(destination.path);
    await _removeOtherAvatars(root, keep: destination.path);
    return destination.path;
  }

  String _fileName(String extension) =>
      'avatar-${DateTime.now().microsecondsSinceEpoch}$extension';

  bool _isAvatarFile(String path) {
    final name = p.basenameWithoutExtension(path);
    return name == 'avatar' || name.startsWith('avatar-');
  }

  String _safeExtension(String path) {
    final extension = p.extension(path).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}
