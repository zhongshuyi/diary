import 'diary_audio_waveform.dart';

DiaryAudioWaveformLoader createDiaryAudioWaveformLoader() =>
    const _UnavailableAudioWaveformLoader();

class _UnavailableAudioWaveformLoader implements DiaryAudioWaveformLoader {
  const _UnavailableAudioWaveformLoader();

  @override
  Future<DiaryAudioWaveform?> load(String audioPath) async => null;
}
