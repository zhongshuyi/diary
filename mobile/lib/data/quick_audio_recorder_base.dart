abstract interface class QuickAudioRecorder {
  /// Requests microphone access and begins recording a temporary audio file.
  /// Returns false when microphone access is unavailable.
  Future<bool> start();

  /// Stops recording, moves the result into private attachment storage, and
  /// returns its permanent local path.
  Future<String?> stop();

  /// Discards the active recording, if any.
  Future<void> cancel();

  Future<void> dispose();
}
