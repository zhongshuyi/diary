class DiaryAudioWaveform {
  DiaryAudioWaveform(List<double> amplitudes)
    : amplitudes = List<double>.unmodifiable(amplitudes);

  /// Peak amplitude for each consecutive portion of the source audio.
  ///
  /// Values are normalized to 0–1 and keep the timing of the original file.
  final List<double> amplitudes;
}

abstract interface class DiaryAudioWaveformLoader {
  Future<DiaryAudioWaveform?> load(String audioPath);
}
