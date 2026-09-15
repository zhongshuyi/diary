enum DiaryMediaKind { image, audio, video, file }

DiaryMediaKind diaryMediaKindForPath(String path) {
  final normalized = path.toLowerCase();
  if (RegExp(r'\.(png|jpe?g|gif|webp|heic|bmp|avif)$').hasMatch(normalized)) {
    return DiaryMediaKind.image;
  }
  if (RegExp(r'\.(mp3|wav|m4a|aac|flac|ogg)$').hasMatch(normalized)) {
    return DiaryMediaKind.audio;
  }
  if (RegExp(r'\.(mp4|mov|mkv|webm|avi|3gp)$').hasMatch(normalized)) {
    return DiaryMediaKind.video;
  }
  return DiaryMediaKind.file;
}

String diaryMediaKindLabel(DiaryMediaKind kind) {
  switch (kind) {
    case DiaryMediaKind.image:
      return '图片';
    case DiaryMediaKind.audio:
      return '音频';
    case DiaryMediaKind.video:
      return '视频';
    case DiaryMediaKind.file:
      return '文件';
  }
}
