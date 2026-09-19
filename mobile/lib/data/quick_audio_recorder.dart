import 'quick_audio_recorder_base.dart';
import 'quick_audio_recorder_stub.dart'
    if (dart.library.io) 'quick_audio_recorder_io.dart'
    as platform;

export 'quick_audio_recorder_base.dart';

QuickAudioRecorder createQuickAudioRecorder() =>
    platform.createQuickAudioRecorder();
