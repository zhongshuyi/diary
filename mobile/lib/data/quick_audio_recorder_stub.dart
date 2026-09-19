import 'quick_audio_recorder_base.dart';

QuickAudioRecorder createQuickAudioRecorder() =>
    _UnsupportedQuickAudioRecorder();

class _UnsupportedQuickAudioRecorder implements QuickAudioRecorder {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> start() async => false;

  @override
  Future<String?> stop() async => null;
}
