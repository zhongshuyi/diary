import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Keeps the official Dart binding API available without shipping WASM assets.
class SherpaOnnxWeb {
  static void registerWith(Registrar registrar) {}

  static Future<void> loadWasm() async {
    throw UnsupportedError('Offline speech is unavailable on this platform.');
  }
}
