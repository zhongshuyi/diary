import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'diary_audio_waveform.dart';

final _sharedLoader = _JustAudioWaveformLoader();

DiaryAudioWaveformLoader createDiaryAudioWaveformLoader() => _sharedLoader;

class _JustAudioWaveformLoader implements DiaryAudioWaveformLoader {
  final Map<String, Future<DiaryAudioWaveform?>> _pending = {};

  @override
  Future<DiaryAudioWaveform?> load(String audioPath) async {
    final source = File(audioPath);
    if (!await source.exists()) return null;

    try {
      final metadata = await source.stat();
      final cacheKey =
          '$audioPath:${metadata.size}:${metadata.modified.microsecondsSinceEpoch}';
      final existing = _pending[cacheKey];
      if (existing != null) return existing;

      final task = _load(source, cacheKey);
      _pending[cacheKey] = task;
      final waveform = await task;
      if (waveform == null) _pending.remove(cacheKey);
      return waveform;
    } catch (_) {
      return null;
    }
  }

  Future<DiaryAudioWaveform?> _load(File source, String cacheKey) async {
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      final cacheDirectory = Directory(
        path.join(supportDirectory.path, 'audio-waveforms'),
      );
      await cacheDirectory.create(recursive: true);
      final hash = sha256.convert(utf8.encode(cacheKey)).toString();
      final waveformFile = File(path.join(cacheDirectory.path, '$hash.wave'));

      Waveform? waveform;
      if (await waveformFile.exists()) {
        try {
          waveform = await JustWaveform.parse(waveformFile);
        } catch (_) {
          // A partial cache is regenerated below.
        }
      }

      if (waveform == null) {
        await for (final update in JustWaveform.extract(
          audioInFile: source,
          waveOutFile: waveformFile,
          zoom: const WaveformZoom.pixelsPerSecond(50),
        )) {
          waveform = update.waveform ?? waveform;
        }
      }

      if (waveform == null && await waveformFile.exists()) {
        waveform = await JustWaveform.parse(waveformFile);
      }
      if (waveform == null || waveform.length == 0) return null;
      return DiaryAudioWaveform(_reduce(waveform));
    } catch (_) {
      return null;
    }
  }

  List<double> _reduce(Waveform waveform) {
    const maximumBars = 720;
    final barCount = math.min(maximumBars, waveform.length);
    final maximumSample = waveform.flags & 1 == 1 ? 127.0 : 32767.0;
    return List<double>.generate(barCount, (index) {
      final start = index * waveform.length ~/ barCount;
      final end = math.max(
        start + 1,
        (index + 1) * waveform.length ~/ barCount,
      );
      var peak = 0;
      for (
        var sampleIndex = start;
        sampleIndex < end && sampleIndex < waveform.length;
        sampleIndex++
      ) {
        peak = math.max(peak, waveform.getPixelMin(sampleIndex).abs());
        peak = math.max(peak, waveform.getPixelMax(sampleIndex).abs());
      }
      return (peak / maximumSample).clamp(0.0, 1.0).toDouble();
    }, growable: false);
  }
}
