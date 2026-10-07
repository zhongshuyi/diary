import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:diary/data/speech_model_store.dart';
import 'package:diary/services/offline_transcription_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capabilityChannel = MethodChannel('diary_test/speech_capabilities');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(capabilityChannel, null);
  });

  test(
    'Android capabilities are checked before enabling model downloads',
    () async {
      var requests = 0;
      messenger.setMockMethodCallHandler(capabilityChannel, (call) async {
        expect(call.method, 'getCapabilities');
        requests++;
        return {'sdkInt': 27, 'supported': true};
      });
      final engine = SherpaOfflineTranscriptionEngine(
        abi: Abi.androidArm64,
        channel: capabilityChannel,
      );
      expect(engine.supported, false);
      expect(await engine.checkSupported(), true);
      expect(engine.supported, true);
      expect(await engine.checkSupported(), true);
      expect(requests, 1);
      await engine.dispose();
      expect(engine.supported, false);
    },
  );

  test(
    'older SDK is rejected before reading audio or loading native code',
    () async {
      messenger.setMockMethodCallHandler(capabilityChannel, (_) async {
        return {'sdkInt': 26, 'supported': true};
      });
      final engine = SherpaOfflineTranscriptionEngine(
        abi: Abi.androidArm64,
        channel: capabilityChannel,
      );
      expect(await engine.checkSupported(), false);
      await expectLater(
        engine.transcribe(
          'not-read-private-recording.wav',
          model: const SpeechModelFiles(
            modelPath: 'not-loaded',
            tokensPath: 'not-loaded',
          ),
        ),
        throwsA(
          isA<TranscriptionException>().having(
            (error) => error.message,
            'message',
            contains('Android 8.1'),
          ),
        ),
      );
      await engine.dispose();
    },
  );

  test('missing platform capability channel remains unsupported', () async {
    final engine = SherpaOfflineTranscriptionEngine(
      abi: Abi.androidArm64,
      channel: capabilityChannel,
    );
    expect(await engine.checkSupported(), false);
    expect(engine.supported, false);
    await engine.dispose();
  });

  test('unsupported ABI never probes a platform runtime', () async {
    var requests = 0;
    messenger.setMockMethodCallHandler(capabilityChannel, (_) async {
      requests++;
      return {'sdkInt': 40, 'supported': true};
    });
    for (final abi in [Abi.androidArm, Abi.androidX64, Abi.windowsArm64]) {
      final engine = SherpaOfflineTranscriptionEngine(
        abi: abi,
        channel: capabilityChannel,
      );
      expect(await engine.checkSupported(), false);
      expect(engine.supported, false);
      await engine.dispose();
    }
    expect(requests, 0);
  });

  test(
    'capability probe cancellation does not reach audio preflight',
    () async {
      final probe = Completer<void>();
      messenger.setMockMethodCallHandler(capabilityChannel, (_) async {
        await probe.future;
        return {'sdkInt': 40, 'supported': true};
      });
      final engine = SherpaOfflineTranscriptionEngine(
        abi: Abi.androidArm64,
        channel: capabilityChannel,
      );
      final pending = expectLater(
        engine.transcribe(
          'not-read-private-recording.wav',
          model: const SpeechModelFiles(
            modelPath: 'not-loaded',
            tokensPath: 'not-loaded',
          ),
        ),
        throwsA(isA<TranscriptionCancelled>()),
      );
      await engine.cancel();
      probe.complete();
      await pending;
      await engine.dispose();
    },
  );

  test('PCM16 WAV is decoded with original amplitude and rate', () {
    final decoded = decodePcmWave(_wave(samples: [0, 16384, -16384, 32767]));
    expect(decoded.sampleRate, 16000);
    expect(decoded.samples, [0, 0.5, -0.5, closeTo(32767 / 32768, 0.0001)]);
  });

  test('stereo WAV is downmixed to mono instead of changing duration', () {
    final decoded = decodePcmWave(
      _wave(channels: 2, samples: [16384, -16384, 16384, 16384]),
    );
    expect(decoded.samples, [0, 0.5]);
  });

  test('float WAV clamps malformed sample values safely', () {
    final bytes = _wave(encoding: 3, bits: 32, samples: [0, 0, 0]);
    final view = ByteData.sublistView(bytes);
    view.setFloat32(44, double.nan, Endian.little);
    view.setFloat32(48, 2, Endian.little);
    view.setFloat32(52, -0.25, Endian.little);
    expect(decodePcmWave(bytes).samples, [0, 1, -0.25]);
  });

  test('PCM8 and signed PCM24 WAV are handled with the correct scale', () {
    expect(decodePcmWave(_wave(bits: 8, samples: [128, 192])).samples, [
      0,
      0.5,
    ]);
    expect(
      decodePcmWave(_wave(bits: 24, samples: [4194304, -4194304])).samples,
      [0.5, -0.5],
    );
  });

  test('WAV duration over three minutes is rejected without truncation', () {
    final wave = _wave(rate: 8000, samples: List.filled(8000 * 181, 0));
    expect(
      () => decodePcmWave(wave),
      throwsA(
        isA<TranscriptionException>().having(
          (e) => e.message,
          'message',
          contains('超过 3 分钟'),
        ),
      ),
    );
  });

  test('malformed oversized data chunk fails before sample allocation', () {
    final bytes = _wave(samples: [0, 0]);
    ByteData.sublistView(bytes).setUint32(40, 0x7fffffff, Endian.little);
    expect(() => decodePcmWave(bytes), throwsA(isA<TranscriptionException>()));
  });

  test('unsupported encoding and channel count are rejected', () {
    for (final bytes in [
      _wave(encoding: 6, samples: [0]),
      _wave(channels: 9, samples: List.filled(9, 0)),
    ]) {
      expect(
        () => decodePcmWave(bytes),
        throwsA(isA<TranscriptionException>()),
      );
    }
  });

  test('invalid RIFF file size is rejected', () {
    final bytes = _wave(samples: [0, 0]);
    ByteData.sublistView(bytes).setUint32(4, 1024, Endian.little);
    expect(() => decodePcmWave(bytes), throwsA(isA<TranscriptionException>()));
  });

  test(
    'segments retain every sample and bound synchronous calls to twenty seconds',
    () {
      final samples = Float32List.fromList(
        List.generate(53 * 16000, (index) => index / (53 * 16000)),
      );
      final segments = splitSpeechSegments(samples, sampleRate: 16000);
      expect(
        segments.fold<int>(0, (sum, segment) => sum + segment.length),
        samples.length,
      );
      expect(
        segments.map((segment) => segment.length),
        everyElement(lessThanOrEqualTo(20 * 16000)),
      );
      expect(segments.expand((segment) => segment).toList(), samples);
    },
  );

  test(
    'segment boundaries prefer a quiet interval and retain later speech',
    () {
      final samples = Float32List.fromList(List.filled(25 * 16000, 0.5));
      for (var index = 16 * 16000; index < 17 * 16000; index++) {
        samples[index] = 0;
      }
      final segments = splitSpeechSegments(samples, sampleRate: 16000);
      expect(segments.first.length, inInclusiveRange(16 * 16000, 17 * 16000));
      expect(segments.last.last, 0.5);
    },
  );

  test(
    'missing model fails before native loading without downloading anything',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'diary_transcription_engine_test_',
      );
      final engine = SherpaOfflineTranscriptionEngine();
      try {
        final audio = File(p.join(temporary.path, 'audio.wav'));
        await audio.writeAsBytes(_wave(samples: [0, 0]));
        await expectLater(
          engine.transcribe(
            audio.path,
            model: SpeechModelFiles(
              modelPath: p.join(temporary.path, 'missing.onnx'),
              tokensPath: p.join(temporary.path, 'tokens.txt'),
            ),
          ),
          throwsA(
            isA<TranscriptionException>().having(
              (e) => e.message,
              'message',
              contains('下载离线语音模型'),
            ),
          ),
        );
      } finally {
        await engine.dispose();
        await _deleteTemporary(temporary);
      }
    },
    skip: !Platform.isWindows && !Platform.isAndroid,
  );

  test(
    'cancel while doing preflight stops before creating the native worker',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'diary_transcription_engine_test_',
      );
      final engine = SherpaOfflineTranscriptionEngine();
      try {
        final audio = File(p.join(temporary.path, 'audio.wav'));
        final model = File(p.join(temporary.path, 'model.onnx'));
        final tokens = File(p.join(temporary.path, 'tokens.txt'));
        await audio.writeAsBytes(_wave(samples: [0, 0]));
        await model.writeAsBytes([1]);
        await tokens.writeAsString('fixture');
        final pending = expectLater(
          engine.transcribe(
            audio.path,
            model: SpeechModelFiles(
              modelPath: model.path,
              tokensPath: tokens.path,
            ),
          ),
          throwsA(isA<TranscriptionCancelled>()),
        );
        await engine.cancel();
        await pending;
      } finally {
        await engine.dispose();
        await _deleteTemporary(temporary);
      }
    },
    skip: !Platform.isWindows && !Platform.isAndroid,
  );

  test(
    'Windows compressed recordings fail with an explicit format limitation',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'diary_transcription_engine_test_',
      );
      final engine = SherpaOfflineTranscriptionEngine();
      try {
        final audio = File(p.join(temporary.path, 'audio.m4a'));
        final model = File(p.join(temporary.path, 'model.onnx'));
        final tokens = File(p.join(temporary.path, 'tokens.txt'));
        await audio.writeAsBytes(List.filled(20, 0));
        await model.writeAsBytes([1]);
        await tokens.writeAsString('fixture');
        await expectLater(
          engine.transcribe(
            audio.path,
            model: SpeechModelFiles(
              modelPath: model.path,
              tokensPath: tokens.path,
            ),
          ),
          throwsA(
            isA<TranscriptionException>().having(
              (e) => e.message,
              'message',
              contains('Android'),
            ),
          ),
        );
      } finally {
        await engine.dispose();
        await _deleteTemporary(temporary);
      }
    },
    skip: !Platform.isWindows,
  );
}

Uint8List _wave({
  List<int> samples = const [0],
  int rate = 16000,
  int channels = 1,
  int bits = 16,
  int encoding = 1,
}) {
  final sampleBytes = bits ~/ 8;
  final bytes = Uint8List(44 + samples.length * sampleBytes);
  final view = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  view.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 12, 'WAVE'.codeUnits);
  bytes.setRange(12, 16, 'fmt '.codeUnits);
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, encoding, Endian.little);
  view.setUint16(22, channels, Endian.little);
  view.setUint32(24, rate, Endian.little);
  view.setUint32(28, rate * channels * sampleBytes, Endian.little);
  view.setUint16(32, channels * sampleBytes, Endian.little);
  view.setUint16(34, bits, Endian.little);
  bytes.setRange(36, 40, 'data'.codeUnits);
  view.setUint32(40, samples.length * sampleBytes, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    final offset = 44 + index * sampleBytes;
    if (bits == 8) {
      view.setUint8(offset, samples[index]);
    } else if (bits == 16) {
      view.setInt16(offset, samples[index], Endian.little);
    } else if (bits == 24) {
      view.setUint8(offset, samples[index] & 255);
      view.setUint8(offset + 1, (samples[index] >> 8) & 255);
      view.setUint8(offset + 2, (samples[index] >> 16) & 255);
    } else {
      view.setInt32(offset, samples[index], Endian.little);
    }
  }
  return bytes;
}

Future<void> _deleteTemporary(Directory directory) async {
  final target = p.normalize(directory.absolute.path);
  if (!p.equals(
        p.dirname(target),
        p.normalize(Directory.systemTemp.absolute.path),
      ) ||
      !p.basename(target).startsWith('diary_transcription_engine_test_')) {
    throw StateError('Unexpected temporary transcription test directory.');
  }
  await directory.delete(recursive: true);
}
