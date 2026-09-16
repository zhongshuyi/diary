enum AttachmentKind { image, video, audio, file }

enum AttachmentRemoteState {
  localOnly,
  uploading,
  uploaded,
  downloading,
  ready,
  missing,
  failed,
}

class Attachment {
  const Attachment({
    required this.assetId,
    required this.sha256,
    required this.kind,
    required this.mimeType,
    required this.byteSize,
    required this.originalName,
    this.localPath,
    this.remoteState = AttachmentRemoteState.localOnly,
    this.lastError,
    required this.createdAt,
  });

  final String assetId;
  final String sha256;
  final AttachmentKind kind;
  final String mimeType;
  final int byteSize;
  final String originalName;
  final String? localPath;
  final AttachmentRemoteState remoteState;
  final String? lastError;
  final DateTime createdAt;

  Attachment copyWith({
    String? localPath,
    AttachmentRemoteState? remoteState,
    String? lastError,
  }) {
    return Attachment(
      assetId: assetId,
      sha256: sha256,
      kind: kind,
      mimeType: mimeType,
      byteSize: byteSize,
      originalName: originalName,
      localPath: localPath ?? this.localPath,
      remoteState: remoteState ?? this.remoteState,
      lastError: lastError,
      createdAt: createdAt,
    );
  }
}
