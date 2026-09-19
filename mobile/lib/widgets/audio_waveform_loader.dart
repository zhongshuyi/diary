import 'audio_waveform_loader_stub.dart'
    if (dart.library.io) 'audio_waveform_loader_io.dart'
    as platform;
import 'diary_audio_waveform.dart';

export 'diary_audio_waveform.dart';

DiaryAudioWaveformLoader createDiaryAudioWaveformLoader() =>
    platform.createDiaryAudioWaveformLoader();
