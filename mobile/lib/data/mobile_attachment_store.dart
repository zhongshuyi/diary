import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/attachment.dart';

class _ImportedFile {
  const _ImportedFile(this.attachment, this.sourceStat, this.storedStat);

  final Attachment attachment;
  final FileStat sourceStat;
  final FileStat storedStat;
}

bool _sameFileVersion(FileStat left, FileStat right) =>
    left.type == FileSystemEntityType.file &&
    right.type == FileSystemEntityType.file &&
    left.size == right.size &&
    left.modified == right.modified &&
    left.changed == right.changed;

// Keep attachment bytes and digest work in the worker. Only small metadata is
// returned to the UI isolate, even for large videos.
Future<({String hash, int byteSize})> _importFileInBackground(
  String sourcePath,
  String rootPath,
  String extension,
) async {
  final source = File(sourcePath);
  if (await source.length() > 128 * 1024 * 1024) {
    throw const FileSystemException('附件不能超过 128 MB');
  }
  final bytes = await source.readAsBytes();
  if (bytes.length > 128 * 1024 * 1024) {
    throw const FileSystemException('附件不能超过 128 MB');
  }
  final hash = crypto.sha256.convert(bytes).toString();
  final destination = File(p.join(rootPath, '$hash$extension'));
  if (!await destination.exists()) {
    await destination.writeAsBytes(bytes, flush: true);
  } else if (!p.equals(p.absolute(sourcePath), p.absolute(destination.path))) {
    final storedHash = await crypto.sha256.bind(destination.openRead()).first;
    if (storedHash.toString() != hash) {
      await destination.writeAsBytes(bytes, flush: true);
    }
  }
  return (hash: hash, byteSize: bytes.length);
}

Future<String> _storeDownloadedBytesInBackground(
  String normalizedHash,
  String extension,
  String rootPath,
  TransferableTypedData payload,
) async {
  final bytes = payload.materialize().asUint8List();
  if (crypto.sha256.convert(bytes).toString() != normalizedHash) {
    throw const FileSystemException('附件校验失败');
  }
  final destination = File(p.join(rootPath, '$normalizedHash$extension'));
  if (await destination.exists()) {
    final storedHash = await crypto.sha256.bind(destination.openRead()).first;
    if (storedHash.toString() != normalizedHash) {
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

Future<String> _runDownloadWorker(
  String normalizedHash,
  String extension,
  String rootPath,
  TransferableTypedData payload,
) => Isolate.run(
  () => _storeDownloadedBytesInBackground(
    normalizedHash,
    extension,
    rootPath,
    payload,
  ),
);

class MobileAttachmentStore {
  MobileAttachmentStore({this.rootDirectory});

  final Directory? rootDirectory;
  static const _maxRememberedImports = 128;
  final _importedFiles = <String, _ImportedFile>{};

  /// Reuses only imports verified in this process while both source and stored
  /// files retain their size and timestamps. A filename or a nonempty list of
  /// attachment IDs alone cannot prove that a local path has been imported.
  Future<Attachment?> findUnchangedImport(
    String sourcePath, {
    AttachmentKind? kind,
    String? mimeType,
  }) async {
    final key = p.normalize(p.absolute(sourcePath));
    final imported = _importedFiles[key];
    if (imported == null) return null;
    final attachment = imported.attachment;
    final resolvedKind = kind ?? _kindFor(sourcePath);
    if (attachment.kind != resolvedKind ||
        attachment.mimeType !=
            (mimeType ?? _mimeFor(resolvedKind, sourcePath))) {
      return null;
    }
    final sourceStat = await File(sourcePath).stat();
    final storedStat = await File(attachment.localPath!).stat();
    if (!_sameFileVersion(imported.sourceStat, sourceStat) ||
        !_sameFileVersion(imported.storedStat, storedStat)) {
      _importedFiles.remove(key);
      return null;
    }
    _importedFiles.remove(key);
    _importedFiles[key] = imported;
    return attachment;
  }

  Future<Attachment> importFile(
    String sourcePath, {
    AttachmentKind? kind,
    String? mimeType,
  }) async {
    final source = File(sourcePath);
    final sourceStat = await source.stat();
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
    final rootPath = root.path;
    final imported = await Isolate.run(
      () => _importFileInBackground(sourcePath, rootPath, safeExtension),
    );
    final hash = imported.hash;
    final destination = File(p.join(rootPath, '$hash$safeExtension'));
    final attachment = Attachment(
      assetId: 'asset-$hash',
      sha256: hash,
      kind: resolvedKind,
      mimeType: mimeType ?? _mimeFor(resolvedKind, source.path),
      byteSize: imported.byteSize,
      originalName: p.basename(source.path),
      localPath: destination.path,
      remoteState: AttachmentRemoteState.localOnly,
      createdAt: DateTime.now(),
    );
    final afterStat = await source.stat();
    final storedStat = await destination.stat();
    if (_sameFileVersion(sourceStat, afterStat) &&
        storedStat.type == FileSystemEntityType.file &&
        storedStat.size == imported.byteSize) {
      final key = p.normalize(p.absolute(sourcePath));
      _importedFiles.remove(key);
      if (_importedFiles.length >= _maxRememberedImports) {
        _importedFiles.remove(_importedFiles.keys.first);
      }
      _importedFiles[key] = _ImportedFile(attachment, afterStat, storedStat);
    }
    return attachment;
  }

  Stream<List<int>> openRead(Attachment attachment) {
    final localPath = attachment.localPath;
    if (localPath == null) {
      throw const FileSystemException('附件本地路径不存在');
    }
    return File(localPath).openRead();
  }

  Future<List<int>> readBytes(Attachment attachment) async {
    if (attachment.localPath == null) {
      throw const FileSystemException('附件本地路径不存在');
    }
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
    final payload = TransferableTypedData.fromList([
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    ]);
    final rootPath = root.path;
    return _runDownloadWorker(normalizedHash, safeExtension, rootPath, payload);
  }

  AttachmentKind _kindFor(String path) {
    final extension = p.extension(path).toLowerCase();
    if (['.mp4', '.mov', '.webm', '.mkv'].contains(extension)) {
      return AttachmentKind.video;
    }
    if (['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(extension)) {
      return AttachmentKind.audio;
    }
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    ].contains(extension)) {
      return AttachmentKind.image;
    }
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
