import 'dart:io';

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
    final destination = File(p.join(root.path, 'avatar$extension'));
    final staging = File('${destination.path}.tmp');
    try {
      await source.copy(staging.path);
      await staging.rename(destination.path);
      await _removeOtherAvatars(root, keep: destination.path);
      return destination.path;
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
      if (p.basenameWithoutExtension(entity.path) == 'avatar') {
        await entity.delete();
      }
    }
  }

  String _safeExtension(String path) {
    final extension = p.extension(path).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}
