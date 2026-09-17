import '../domain/attachment.dart';
import 'sync_client.dart';

/// Content-addressed attachment queue. It is deliberately independent from
/// Isar so the same retry policy can be used by mobile and desktop adapters.
class AttachmentSyncQueue {
  const AttachmentSyncQueue({required this.client});

  final SyncClient client;

  Future<List<Attachment>> uploadMissing(
    Iterable<Attachment> attachments,
    Future<List<int>> Function(Attachment) readBytes,
  ) async {
    final result = <Attachment>[];
    for (final attachment in attachments) {
      if (await client.headAsset(attachment.sha256)) {
        result.add(
          attachment.copyWith(remoteState: AttachmentRemoteState.uploaded),
        );
        continue;
      }
      try {
        final bytes = await readBytes(attachment);
        await client.uploadAsset(
          attachment.copyWith(remoteState: AttachmentRemoteState.uploading),
          Stream.value(bytes),
        );
        result.add(
          attachment.copyWith(
            remoteState: AttachmentRemoteState.uploaded,
            lastError: null,
          ),
        );
      } catch (error) {
        result.add(
          attachment.copyWith(
            remoteState: AttachmentRemoteState.failed,
            lastError: '$error',
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  Future<Attachment> downloadIfNeeded(
    Attachment attachment,
    Future<void> Function(Attachment, List<int>) writeBytes,
  ) async {
    if (attachment.localPath != null &&
        attachment.remoteState == AttachmentRemoteState.ready)
      return attachment;
    try {
      final bytes = await client.downloadAsset(attachment.sha256);
      await writeBytes(attachment, bytes);
      return attachment.copyWith(
        remoteState: AttachmentRemoteState.ready,
        lastError: null,
      );
    } catch (error) {
      return attachment.copyWith(
        remoteState: AttachmentRemoteState.failed,
        lastError: '$error',
      );
    }
  }
}
