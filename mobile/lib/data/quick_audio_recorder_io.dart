import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/attachment.dart';
import 'mobile_attachment_store.dart';
import 'quick_audio_recorder_base.dart';

QuickAudioRecorder createQuickAudioRecorder() => _MobileQuickAudioRecorder();

class _MobileQuickAudioRecorder implements QuickAudioRecorder {
  _MobileQuickAudioRecorder({
    AudioRecorder? recorder,
    MobileAttachmentStore? attachmentStore,
  }) : _recorder = recorder ?? AudioRecorder(),
       _attachmentStore = attachmentStore ?? MobileAttachmentStore();

  final AudioRecorder _recorder;
  final MobileAttachmentStore _attachmentStore;
  String? _temporaryPath;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final directory = Directory(
      p.join((await getTemporaryDirectory()).path, 'diary-recordings'),
    );
    await directory.create(recursive: true);
    final path = p.join(
      directory.path,
      'recording-${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _temporaryPath = path;
    return true;
  }

  @override
  Future<String?> stop() async {
    final recordedPath = await _recorder.stop();
    final temporaryPath = _temporaryPath;
    _temporaryPath = null;
    if (recordedPath == null || recordedPath.isEmpty) return null;
    try {
      final attachment = await _attachmentStore.importFile(
        recordedPath,
        kind: AttachmentKind.audio,
        mimeType: 'audio/mp4',
      );
      return attachment.localPath;
    } finally {
      if (recordedPath == temporaryPath) {
        await _deleteIfExists(recordedPath);
      }
    }
  }

  @override
  Future<void> cancel() async {
    final temporaryPath = _temporaryPath;
    _temporaryPath = null;
    await _recorder.cancel();
    if (temporaryPath != null) await _deleteIfExists(temporaryPath);
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
