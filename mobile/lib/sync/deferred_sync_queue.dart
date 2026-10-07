import 'dart:async';

/// Schedules durable outbox work after interaction settles. The repository
/// owns the mutations; this queue only coalesces and serializes wakeups.
class DeferredSyncQueue {
  DeferredSyncQueue({
    required this.synchronize,
    this.idleDelay = const Duration(seconds: 2),
    this.retryDelay = const Duration(seconds: 10),
  });

  /// Returns true when the outbox is drained, false when another pass is needed.
  final Future<bool> Function() synchronize;
  final Duration idleDelay;
  final Duration retryDelay;
  Timer? _timer;
  Future<void>? _running;
  Future<void>? _flushing;
  bool _pending = false;
  bool _disposed = false;
  bool _lastAttemptFailed = false;

  void request() {
    if (_disposed) return;
    _pending = true;
    if (_running == null) _schedule(idleDelay);
  }

  void deferForInteraction() {
    if (!_disposed && _pending && _running == null) _schedule(idleDelay);
  }

  Future<void> flush() {
    if (_disposed) return Future<void>.value();
    return _flushing ??= _flush();
  }

  Future<void> _flush() async {
    try {
      _timer?.cancel();
      _timer = null;
      _pending = true;
      final running = _running;
      if (running != null) {
        await running;
        // A flush joining an active attempt shares its failure and backoff.
        if (_lastAttemptFailed) return;
      }
      while (!_disposed && _pending) {
        await _startRun();
        if (_lastAttemptFailed) break;
      }
    } finally {
      _flushing = null;
    }
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _startRun);
  }

  Future<void> _startRun() {
    if (_disposed || !_pending) return Future<void>.value();
    if (_running != null) return _running!;
    _timer?.cancel();
    _timer = null;
    _pending = false;
    _lastAttemptFailed = false;
    final completion = Completer<void>();
    _running = completion.future;
    unawaited(_performRun(completion));
    return completion.future;
  }

  Future<void> _performRun(Completer<void> completion) async {
    var drained = false;
    try {
      drained = await synchronize();
    } catch (_) {
      _lastAttemptFailed = true;
      // The persistent outbox keeps its mutations for the next attempt.
    } finally {
      _running = null;
      if (!_disposed) {
        _pending = _pending || !drained;
        if (_pending) _schedule(drained ? idleDelay : retryDelay);
      }
      completion.complete();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pending = false;
  }
}
