import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/transcription_controller.dart';
import 'package:diary/data/speech_model_store.dart';
import 'package:diary/services/offline_transcription_engine.dart';

const _files = SpeechModelFiles(
  modelPath: '/model/sensevoice.onnx',
  tokensPath: '/model/tokens.txt',
);

void main() {
  test(
    'cancelling while native cleanup is pending never starts a model download',
    () async {
      final engine = _DelayedCancelEngine();
      final models = _Models(model: null);
      final controller = TranscriptionController(
        models: models,
        engine: engine,
      );
      final download = controller.downloadModel();
      await _flush();
      expect(controller.downloading, isTrue);
      expect(models.downloadCalls, 0);
      await controller.cancelDownload();
      engine.cancelBarrier.complete();
      await download;
      expect(models.downloadCalls, 0);
      expect(controller.hasModel, isFalse);
      expect(controller.error, isNull);
      await controller.close();
    },
  );

  testWidgets(
    'an entry check cannot start native work after the CPU permit changes',
    (tester) async {
      final engine = _Engine();
      final guard = Completer<bool>();
      var canStart = true;
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        queueDelay: Duration.zero,
        canStart: () => canStart,
        isCurrent: (_, _) => guard.future,
      );
      await controller.retry('entry-1', '/audio/voice.m4a');
      await tester.pump();
      canStart = false;
      guard.complete(true);
      await tester.pump();
      expect(engine.calls, isEmpty);
      expect(controller.queuedCount, 1);
      canStart = true;
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(engine.calls, ['/audio/voice.m4a']);
      engine.complete('取得运行许可后识别');
      await tester.pump();
      await controller.close();
    },
  );

  test(
    'unsupported capability checks prevent download and automatic opt-in',
    () async {
      final engine = _Engine(isSupported: false);
      final models = _Models(model: null);
      final controller = TranscriptionController(
        models: models,
        engine: engine,
      );
      await controller.downloadModel();
      expect(engine.capabilityChecks, 1);
      expect(controller.supported, isFalse);
      expect(models.downloadCalls, 0);
      await controller.setAutoTranscribe(true);
      expect(controller.autoTranscribe, isFalse);
      expect(models.settingsWrites, isEmpty);
      await controller.close();
    },
  );

  for (final operation in ['stop', 'remove-entry', 'cancel-audio']) {
    test(
      'a pending initialization cannot requeue work after $operation',
      () async {
        final models = _PendingModels();
        final engine = _Engine();
        final controller = TranscriptionController(
          models: models,
          engine: engine,
          queueDelay: Duration.zero,
        );
        final enqueue = controller.retry('entry-1', '/audio/voice.m4a');
        switch (operation) {
          case 'stop':
            await controller.stop();
          case 'remove-entry':
            await controller.removeEntry('entry-1');
          case 'cancel-audio':
            await controller.cancel('entry-1', '/audio/voice.m4a');
        }
        models.ready.complete(_files);
        await enqueue;
        await _flush();
        expect(controller.queuedCount, 0);
        expect(engine.calls, isEmpty);
        await controller.close();
      },
    );
  }

  testWidgets(
    'native work waits for the foreground model and keyboard transitions',
    (tester) async {
      final engine = _Engine();
      var canStart = false;
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        canStart: () => canStart,
        queueDelay: Duration.zero,
      );
      await controller.retry('entry-1', '/audio/voice.m4a');
      await tester.pump();
      expect(engine.calls, isEmpty);
      canStart = true;
      controller.deferForInteraction();
      await tester.pump(const Duration(milliseconds: 200));
      expect(engine.calls, isEmpty);
      controller.deferForInteraction();
      await tester.pump(const Duration(milliseconds: 200));
      expect(engine.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(engine.calls, ['/audio/voice.m4a']);
      engine.complete('交互完成后识别');
      await tester.pump();
      await controller.close();
    },
  );

  test(
    'automatic transcription defaults off without downloading or running inference',
    () async {
      final models = _Models();
      final engine = _Engine();
      final controller = TranscriptionController(
        models: models,
        engine: engine,
        queueDelay: Duration.zero,
      );
      await controller.initialize();
      expect(controller.autoTranscribe, isFalse);
      await controller.enqueue('entry-1', '/audio/voice.m4a');
      await _flush();
      expect(engine.calls, isEmpty);
      expect(models.downloadCalls, 0);
      expect(controller.stateFor('entry-1', '/audio/voice.m4a'), isNull);
      await controller.close();
    },
  );

  test(
    'missing model cannot enable auto mode and download does not opt in',
    () async {
      final models = _Models(model: null);
      final engine = _Engine();
      final controller = TranscriptionController(
        models: models,
        engine: engine,
      );
      await controller.setAutoTranscribe(true);
      expect(controller.autoTranscribe, isFalse);
      expect(models.settingsWrites, isEmpty);
      expect(controller.error, contains('先下载'));
      await controller.downloadModel();
      expect(controller.hasModel, isTrue);
      expect(models.downloadCalls, 1);
      expect(controller.autoTranscribe, isFalse);
      await controller.setAutoTranscribe(true);
      expect(controller.autoTranscribe, isTrue);
      expect(models.settingsWrites, [true]);
      await controller.close();
    },
  );

  test(
    'saved recordings run sequentially and only successful text is persisted',
    () async {
      final engine = _Engine();
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(automatic: true),
        engine: engine,
        queueDelay: Duration.zero,
        onCompleted: (entry, path, text) async => completed.add('$entry:$text'),
      );
      await controller.enqueue('entry-1', '/audio/first.m4a');
      await controller.enqueue('entry-2', '/audio/second.m4a');
      await _flush();
      expect(engine.calls, ['/audio/first.m4a']);
      expect(
        controller.stateFor('entry-2', '/audio/second.m4a')?.stage,
        AudioTranscriptionStage.queued,
      );
      engine.complete('今天看到了晚霞');
      await _flush();
      expect(engine.calls, ['/audio/first.m4a', '/audio/second.m4a']);
      expect(completed, ['entry-1:今天看到了晚霞']);
      engine.complete('明天要记得带伞');
      await _flush();
      expect(completed, ['entry-1:今天看到了晚霞', 'entry-2:明天要记得带伞']);
      expect(engine.maximumConcurrent, 1);
      expect(controller.transcribing, isFalse);
      expect(
        controller.stateFor('entry-2', '/audio/second.m4a')?.text,
        '明天要记得带伞',
      );
      await controller.close();
    },
  );

  test(
    'manual retry works with auto mode off and failures do not expose private paths',
    () async {
      final engine = _Engine();
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        queueDelay: Duration.zero,
        onCompleted: (_, _, text) async => completed.add(text),
      );
      await controller.retry('entry-1', '/private/recording.m4a');
      await _flush();
      engine.fail(
        StateError('cannot decode /private/recording.m4a secret filename'),
      );
      await _flush();
      final failed = controller.stateFor('entry-1', '/private/recording.m4a');
      expect(failed?.stage, AudioTranscriptionStage.failed);
      expect(failed?.error, isNot(contains('/private')));
      expect(completed, isEmpty);
      await controller.retry('entry-1', '/private/recording.m4a');
      await _flush();
      engine.complete('重试之后识别的文字');
      await _flush();
      expect(completed, ['重试之后识别的文字']);
      expect(controller.autoTranscribe, isFalse);
      await controller.close();
    },
  );

  test(
    'cancelled inference cannot persist late text or overwrite a replacement task',
    () async {
      final engine = _Engine(cancelCompletes: false);
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        queueDelay: Duration.zero,
        onCompleted: (_, _, text) async => completed.add(text),
      );
      await controller.retry('entry-1', '/audio/voice.m4a');
      await _flush();
      await controller.cancel('entry-1', '/audio/voice.m4a');
      await controller.retry('entry-1', '/audio/voice.m4a');
      engine.complete('已经取消的旧结果');
      await _flush();
      expect(completed, isEmpty);
      expect(engine.calls, hasLength(2));
      engine.complete('新结果');
      await _flush();
      expect(completed, ['新结果']);
      expect(controller.stateFor('entry-1', '/audio/voice.m4a')?.text, '新结果');
      await controller.close();
    },
  );

  test(
    'deleted or edited audio is checked both before work and before completion',
    () async {
      final engine = _Engine();
      var current = false;
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        queueDelay: Duration.zero,
        isCurrent: (_, _) => current,
        onCompleted: (_, _, text) async => completed.add(text),
      );
      await controller.retry('entry-1', '/audio/removed.m4a');
      await _flush();
      expect(engine.calls, isEmpty);
      current = true;
      await controller.retry('entry-1', '/audio/removed.m4a');
      await _flush();
      current = false;
      engine.complete('附件删除之后的晚结果');
      await _flush();
      expect(completed, isEmpty);
      expect(controller.stateFor('entry-1', '/audio/removed.m4a'), isNull);
      await controller.close();
    },
  );

  test(
    'removing an entry cancels queued and active work without altering other entries',
    () async {
      final engine = _Engine();
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(automatic: true),
        engine: engine,
        queueDelay: Duration.zero,
        onCompleted: (entry, _, text) async => completed.add('$entry:$text'),
      );
      await controller.enqueue('entry-1', '/audio/first.m4a');
      await controller.enqueue('entry-1', '/audio/second.m4a');
      await controller.enqueue('entry-2', '/audio/third.m4a');
      await _flush();
      await controller.removeEntry('entry-1');
      await _flush();
      expect(controller.stateFor('entry-1', '/audio/first.m4a'), isNull);
      expect(controller.stateFor('entry-1', '/audio/second.m4a'), isNull);
      expect(engine.calls, ['/audio/first.m4a', '/audio/third.m4a']);
      engine.complete('其他日记的录音');
      await _flush();
      expect(completed, ['entry-2:其他日记的录音']);
      await controller.close();
    },
  );

  test(
    'empty audio does not produce a searchable transcript and remains retryable',
    () async {
      final engine = _Engine();
      final completed = <String>[];
      final controller = TranscriptionController(
        models: _Models(),
        engine: engine,
        queueDelay: Duration.zero,
        onCompleted: (_, _, text) async => completed.add(text),
      );
      await controller.retry('entry-1', '/audio/silent.m4a');
      await _flush();
      engine.complete('   ');
      await _flush();
      expect(completed, isEmpty);
      expect(
        controller.stateFor('entry-1', '/audio/silent.m4a')?.error,
        '没有识别到清晰的人声',
      );
      await controller.close();
    },
  );

  test(
    'removing the model disables auto mode and keeps completed text',
    () async {
      final engine = _Engine();
      final models = _Models(automatic: true);
      final controller = TranscriptionController(
        models: models,
        engine: engine,
        queueDelay: Duration.zero,
      );
      await controller.enqueue('entry-1', '/audio/voice.m4a');
      await _flush();
      engine.complete('已保存的录音文字');
      await _flush();
      await controller.removeModel();
      expect(controller.hasModel, isFalse);
      expect(controller.autoTranscribe, isFalse);
      expect(models.removes, 1);
      expect(models.settingsWrites, [false]);
      expect(
        controller.stateFor('entry-1', '/audio/voice.m4a')?.text,
        '已保存的录音文字',
      );
      await controller.close();
    },
  );

  test('shutdown prevents an in-flight result from being persisted', () async {
    final engine = _Engine();
    var writes = 0;
    final controller = TranscriptionController(
      models: _Models(),
      engine: engine,
      queueDelay: Duration.zero,
      onCompleted: (_, _, _) async => writes++,
    );
    await controller.retry('entry-1', '/audio/voice.m4a');
    await _flush();
    await controller.close();
    expect(writes, 0);
    expect(engine.disposed, isTrue);
  });
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _Models extends SpeechModelStore {
  _Models({this.model = _files, this.automatic = false});
  SpeechModelFiles? model;
  bool automatic;
  int downloadCalls = 0;
  int removes = 0;
  final settingsWrites = <bool>[];

  @override
  Future<SpeechModelFiles?> installed() async => model;
  @override
  Future<bool> readAutoTranscribe() async => automatic;
  @override
  Future<void> writeAutoTranscribe(bool value) async {
    settingsWrites.add(value);
    automatic = value;
  }

  @override
  Future<SpeechModelFiles> download({void Function(double)? onProgress}) async {
    downloadCalls++;
    onProgress?.call(.5);
    return model = _files;
  }

  @override
  Future<void> cancelDownload() async {}
  @override
  Future<void> remove() async {
    removes++;
    model = null;
  }

  @override
  Future<void> dispose() async {}
}

class _PendingModels extends _Models {
  final ready = Completer<SpeechModelFiles?>();

  @override
  Future<SpeechModelFiles?> installed() => ready.future;
}

class _Engine implements TranscriptionEngine {
  _Engine({this.cancelCompletes = true, this.isSupported = true});
  final bool cancelCompletes;
  final bool isSupported;
  int capabilityChecks = 0;
  final calls = <String>[];
  Completer<String>? _pending;
  int concurrent = 0;
  int maximumConcurrent = 0;
  bool disposed = false;

  @override
  bool get supported => isSupported;
  @override
  Future<bool> checkSupported() async {
    capabilityChecks++;
    return supported;
  }

  @override
  Future<String> transcribe(
    String audioPath, {
    required SpeechModelFiles model,
    void Function(double)? onProgress,
  }) {
    calls.add(audioPath);
    concurrent++;
    if (concurrent > maximumConcurrent) maximumConcurrent = concurrent;
    final pending = _pending = Completer<String>();
    onProgress?.call(.5);
    return pending.future.whenComplete(() {
      concurrent--;
      if (identical(_pending, pending)) _pending = null;
    });
  }

  void complete(String text) => _pending!.complete(text);
  void fail(Object error) => _pending!.completeError(error);
  @override
  Future<void> cancel() async {
    if (cancelCompletes && _pending?.isCompleted == false) {
      _pending!.completeError(StateError('cancelled'));
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _DelayedCancelEngine extends _Engine {
  final cancelBarrier = Completer<void>();

  @override
  Future<void> cancel() => cancelBarrier.future;
}
