import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:diary/sync/deferred_sync_queue.dart';

void main() {
  const idleDelay = Duration(seconds: 2);
  const retryDelay = Duration(seconds: 10);

  testWidgets('coalesces repeated requests until the idle delay expires', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        return true;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    queue.request();
    queue.request();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
    await tester.pump(retryDelay);
    expect(calls, 1);
  });

  testWidgets('interaction postpones pending synchronization until idle', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        return true;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await tester.pump(const Duration(milliseconds: 1500));
    queue.deferForInteraction();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(calls, 0);
    queue.deferForInteraction();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);

    queue.deferForInteraction();
    await tester.pump(retryDelay);
    expect(calls, 1);
  });

  testWidgets('keeps requests made while synchronization is running', (
    tester,
  ) async {
    final firstSync = Completer<bool>();
    var calls = 0;
    var active = 0;
    var maximumActive = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        active++;
        if (active > maximumActive) maximumActive = active;
        try {
          return calls == 1 ? await firstSync.future : true;
        } finally {
          active--;
        }
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await tester.pump(idleDelay);
    expect(calls, 1);
    queue.request();
    queue.request();
    await tester.pump(idleDelay);
    expect(calls, 1);
    expect(active, 1);

    firstSync.complete(true);
    await tester.pump();
    await tester.pump(idleDelay);
    expect(calls, 2);
    expect(active, 0);
    expect(maximumActive, 1);
    await tester.pump(retryDelay);
    expect(calls, 2);
  });

  testWidgets('flush waits for the running sync before draining new requests', (
    tester,
  ) async {
    final firstSync = Completer<bool>();
    final secondSync = Completer<bool>();
    var calls = 0;
    var flushCompleted = false;
    final queue = DeferredSyncQueue(
      synchronize: () {
        calls++;
        return calls == 1 ? firstSync.future : secondSync.future;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await tester.pump(idleDelay);
    expect(calls, 1);
    queue.request();
    final flush = queue.flush().then((_) => flushCompleted = true);
    await tester.pump();
    expect(calls, 1);
    expect(flushCompleted, isFalse);

    firstSync.complete(true);
    await tester.pump();
    expect(calls, 2);
    expect(flushCompleted, isFalse);
    secondSync.complete(true);
    await tester.pump();
    await flush;
    expect(flushCompleted, isTrue);
    await tester.pump(retryDelay);
    expect(calls, 2);
  });

  for (final throws in [false, true]) {
    testWidgets(
      '${throws ? 'exception' : 'incomplete synchronization'} retries pending work',
      (tester) async {
        var calls = 0;
        final queue = DeferredSyncQueue(
          synchronize: () async {
            calls++;
            if (calls == 1) {
              if (throws) throw StateError('temporary sync failure');
              return false;
            }
            return true;
          },
          idleDelay: idleDelay,
          retryDelay: retryDelay,
        );
        addTearDown(queue.dispose);

        queue.request();
        await tester.pump(idleDelay);
        expect(calls, 1);
        await tester.pump(const Duration(milliseconds: 9999));
        expect(calls, 1);
        await tester.pump(const Duration(milliseconds: 1));
        expect(calls, 2);
        await tester.pump(retryDelay);
        expect(calls, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('manual flush starts pending work without waiting for idle', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        return true;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await queue.flush();
    expect(calls, 1);
    await tester.pump(retryDelay);
    expect(calls, 1);
  });

  testWidgets('manual flush drains all healthy batches before completing', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        return calls == 3;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await queue.flush();
    expect(calls, 3);
    await tester.pump(retryDelay);
    expect(calls, 3);
  });

  testWidgets('concurrent manual flushes both wait for every pending batch', (
    tester,
  ) async {
    final batches = List.generate(3, (_) => Completer<bool>());
    var calls = 0;
    var firstCompleted = false;
    var secondCompleted = false;
    final queue = DeferredSyncQueue(
      synchronize: () => batches[calls++].future,
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await tester.pump(idleDelay);
    expect(calls, 1);
    final firstFlush = queue.flush();
    final secondFlush = queue.flush();
    expect(secondFlush, same(firstFlush));
    final firstResult = firstFlush.then((_) => firstCompleted = true);
    final secondResult = secondFlush.then((_) => secondCompleted = true);

    for (var index = 0; index < 2; index++) {
      batches[index].complete(false);
      await tester.pump();
      expect(calls, index + 2);
      expect(firstCompleted, isFalse);
      expect(secondCompleted, isFalse);
    }
    batches.last.complete(true);
    await tester.pump();
    await Future.wait([firstResult, secondResult]);
    expect(firstCompleted, isTrue);
    expect(secondCompleted, isTrue);
    await tester.pump(retryDelay);
    expect(calls, 3);
  });

  testWidgets('flush joining a failed attempt preserves its retry delay', (
    tester,
  ) async {
    final firstSync = Completer<bool>();
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () {
        calls++;
        return calls == 1 ? firstSync.future : Future.value(true);
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await tester.pump(idleDelay);
    final flush = queue.flush();
    firstSync.completeError(StateError('temporary sync failure'));
    await tester.pump();
    await flush;
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 9999));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed manual flush stops and keeps work for a later retry', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        if (calls == 1) throw StateError('temporary sync failure');
        return true;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );
    addTearDown(queue.dispose);

    queue.request();
    await queue.flush();
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 9999));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    await tester.pump(retryDelay);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose cancels pending work and stops later scheduling', (
    tester,
  ) async {
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () async {
        calls++;
        return true;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );

    queue.request();
    queue.dispose();
    queue.request();
    queue.deferForInteraction();
    await tester.pump(retryDelay);
    expect(calls, 0);
  });

  testWidgets('disposing during a failed sync prevents its retry', (
    tester,
  ) async {
    final synchronization = Completer<bool>();
    var calls = 0;
    final queue = DeferredSyncQueue(
      synchronize: () {
        calls++;
        return synchronization.future;
      },
      idleDelay: idleDelay,
      retryDelay: retryDelay,
    );

    queue.request();
    await tester.pump(idleDelay);
    expect(calls, 1);
    queue.dispose();
    synchronization.complete(false);
    await tester.pump();
    await tester.pump(retryDelay);
    expect(calls, 1);
  });
}
