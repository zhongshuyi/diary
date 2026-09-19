import 'package:path/path.dart' as p;

import '../data/mobile_attachment_store.dart';
import '../domain/attachment.dart';
import '../domain/diary_entry.dart';
import '../domain/outbox_mutation.dart';
import 'attachment_sync_queue.dart';
import 'sync_client.dart';
import 'sync_models.dart';

class _AssetReference {
  const _AssetReference(this.sha256, this.extension);

  final String sha256;
  final String extension;
}

_AssetReference? _parseReference(String value) {
  final match = RegExp(
    r'^asset://([a-f0-9]{64})(\.[a-z0-9]{1,16})?$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  return _AssetReference(
    match.group(1)!.toLowerCase(),
    (match.group(2) ?? '').toLowerCase(),
  );
}

String _portablePath(Attachment attachment) {
  final extension = p.extension(attachment.originalName).toLowerCase();
  final safeExtension = RegExp(r'^\.[a-z0-9]{1,16}$').hasMatch(extension)
      ? extension
      : '';
  return 'asset://${attachment.sha256}$safeExtension';
}

class AttachmentTransfer {
  AttachmentTransfer({required this.client, MobileAttachmentStore? store})
    : store = store ?? MobileAttachmentStore();

  final SyncClient client;
  final MobileAttachmentStore store;

  Future<List<Map<String, dynamic>>> prepareChanges(
    Iterable<OutboxMutation> mutations,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final mutation in mutations) {
      final payload = Map<String, dynamic>.from(mutation.payload);
      final rawEntry = payload['entry'];
      if (rawEntry is! Map) {
        result.add(payload);
        continue;
      }
      final entry = DiaryEntry.fromJson(Map<String, dynamic>.from(rawEntry));
      payload['entry'] = (await _prepareEntry(entry)).toJson();
      result.add(payload);
    }
    return List.unmodifiable(result);
  }

  Future<void> backfillEntries(
    Iterable<DiaryEntry> entries,
    Future<void> Function(DiaryEntry entry) save,
  ) async {
    for (final entry in entries) {
      final local = await _localAttachments(entry);
      if (local.isEmpty) continue;
      final nextIds = {
        ...entry.attachmentIds,
        ...local.map((attachment) => attachment.assetId),
      }.toList(growable: false);
      if (nextIds.length == entry.attachmentIds.length) continue;
      await save(
        entry.copyWith(attachmentIds: nextIds, updatedAt: DateTime.now()),
      );
    }
  }

  Future<DiaryEntry> hydrateEntry(DiaryEntry entry) async {
    final downloads = <String, Future<String>>{};
    Future<List<String>> hydrate(List<String> paths) async => Future.wait(
      paths.map((path) async {
        final reference = _parseReference(path);
        if (reference == null) return path;
        final key = '${reference.sha256}${reference.extension}';
        final task = downloads.putIfAbsent(key, () async {
          final bytes = await client.downloadAsset(reference.sha256);
          return store.storeDownloadedBytes(
            sha256: reference.sha256,
            extension: reference.extension,
            bytes: bytes,
          );
        });
        return task;
      }),
    );
    return entry.copyWith(
      imagePaths: await hydrate(entry.imagePaths),
      audioPaths: await hydrate(entry.audioPaths),
      videoPaths: await hydrate(entry.videoPaths),
    );
  }

  Future<DiaryEntry> _prepareEntry(DiaryEntry entry) async {
    final sourceAssets = await _attachmentsBySourcePath(entry);
    final assets = {
      for (final attachment in sourceAssets.values)
        attachment.assetId: attachment,
    }.values.toList(growable: false);
    if (assets.isEmpty) return entry;
    final synced = await AttachmentSyncQueue(
      client: client,
    ).uploadMissing(assets, store.readBytes);
    final failed = synced
        .where(
          (attachment) =>
              attachment.remoteState == AttachmentRemoteState.failed,
        )
        .toList(growable: false);
    if (failed.isNotEmpty)
      throw const SyncFailure('asset_upload_failed', '附件上传失败');
    final syncedById = {
      for (final attachment in synced) attachment.assetId: attachment,
    };
    List<String> portable(List<String> paths) => paths
        .map((path) {
          if (_parseReference(path) != null) return path;
          final source = sourceAssets[p.normalize(path)];
          final attachment = source == null ? null : syncedById[source.assetId];
          return attachment == null ? path : _portablePath(attachment);
        })
        .toList(growable: false);
    return entry.copyWith(
      attachmentIds: {
        ...entry.attachmentIds,
        ...synced.map((attachment) => attachment.assetId),
      }.toList(growable: false),
      imagePaths: portable(entry.imagePaths),
      audioPaths: portable(entry.audioPaths),
      videoPaths: portable(entry.videoPaths),
    );
  }

  Future<List<Attachment>> _localAttachments(DiaryEntry entry) async {
    final bySourcePath = await _attachmentsBySourcePath(entry);
    return {
      for (final attachment in bySourcePath.values)
        attachment.assetId: attachment,
    }.values.toList(growable: false);
  }

  Future<Map<String, Attachment>> _attachmentsBySourcePath(
    DiaryEntry entry,
  ) async {
    final attachments = <String, Attachment>{};
    Future<void> collect(List<String> paths, AttachmentKind kind) async {
      for (final path in paths) {
        final key = p.normalize(path);
        if (_parseReference(path) != null || attachments.containsKey(key))
          continue;
        attachments[key] = await store.importFile(path, kind: kind);
      }
    }

    await collect(entry.imagePaths, AttachmentKind.image);
    await collect(entry.audioPaths, AttachmentKind.audio);
    await collect(entry.videoPaths, AttachmentKind.video);
    return attachments;
  }
}
