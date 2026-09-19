import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/attachment.dart';

class MobileAttachmentStore {
  MobileAttachmentStore({this.rootDirectory});

  final Directory? rootDirectory;

  Future<Attachment> importFile(
    String sourcePath, {
    AttachmentKind? kind,
    String? mimeType,
  }) async {
    final source = File(sourcePath);
    final bytes = await source.readAsBytes();
    if (bytes.length > 128 * 1024 * 1024)
      throw const FileSystemException('附件不能超过 128 MB');
    final hash = crypto.sha256.convert(bytes).toString();
    final root =
        rootDirectory ??
        Directory(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'diary',
            'attachments',
          ),
        );
    await root.create(recursive: true);
    final resolvedKind = kind ?? _kindFor(source.path);
    final extension = p.extension(source.path).toLowerCase();
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : resolvedKind == AttachmentKind.image
        ? '.jpg'
        : '';
    final destination = File(p.join(root.path, '$hash$safeExtension'));
    if (!await destination.exists())
      await destination.writeAsBytes(bytes, flush: true);
    return Attachment(
      assetId: 'asset-$hash',
      sha256: hash,
      kind: resolvedKind,
      mimeType: mimeType ?? _mimeFor(resolvedKind, source.path),
      byteSize: bytes.length,
      originalName: p.basename(source.path),
      localPath: destination.path,
      remoteState: AttachmentRemoteState.localOnly,
      createdAt: DateTime.now(),
    );
  }

  Future<List<int>> readBytes(Attachment attachment) async {
    if (attachment.localPath == null)
      throw const FileSystemException('附件本地路径不存在');
    return File(attachment.localPath!).readAsBytes();
  }

  Future<String> storeDownloadedBytes({
    required String sha256,
    required String extension,
    required List<int> bytes,
  }) async {
    final normalizedHash = sha256.toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(normalizedHash) ||
        bytes.length > 128 * 1024 * 1024) {
      throw const FileSystemException('附件内容无效');
    }
    if (crypto.sha256.convert(bytes).toString() != normalizedHash) {
      throw const FileSystemException('附件校验失败');
    }
    final root =
        rootDirectory ??
        Directory(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'diary',
            'attachments',
          ),
        );
    await root.create(recursive: true);
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,16}$').hasMatch(extension)
        ? extension.toLowerCase()
        : '.bin';
    final destination = File(
      p.join(root.path, '$normalizedHash$safeExtension'),
    );
    if (await destination.exists()) {
      if (crypto.sha256.convert(await destination.readAsBytes()).toString() !=
          normalizedHash) {
        throw const FileSystemException('附件校验失败');
      }
      return destination.path;
    }
    final staging = File(
      '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await staging.writeAsBytes(bytes, flush: true);
      await staging.rename(destination.path);
      return destination.path;
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

  AttachmentKind _kindFor(String path) {
    final extension = p.extension(path).toLowerCase();
    if (['.mp4', '.mov', '.webm', '.mkv'].contains(extension))
      return AttachmentKind.video;
    if (['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(extension))
      return AttachmentKind.audio;
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension))
      return AttachmentKind.image;
    return AttachmentKind.file;
  }

  String _mimeFor(AttachmentKind kind, String path) {
    final extension = p.extension(path).toLowerCase();
    const known = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.mp4': 'video/mp4',
      '.mov': 'video/quicktime',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.m4a': 'audio/mp4',
      '.aac': 'audio/aac',
      '.ogg': 'audio/ogg',
    };
    return known[extension] ??
        (kind == AttachmentKind.file
            ? 'application/octet-stream'
            : '${kind.name}/*');
  }
}
