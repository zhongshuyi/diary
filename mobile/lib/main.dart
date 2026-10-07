import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/diary_app.dart';

export 'app/diary_app.dart' show DiaryBootstrapApp, MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'llamadart native runtime',
      'llama.cpp',
      'ggml',
      'KleidiAI',
    ], await rootBundle.loadString('assets/licenses/local-llm.txt'));
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'sherpa-onnx ASR runtime',
      'ONNX Runtime',
      'SenseVoice',
    ], await rootBundle.loadString('assets/licenses/offline-speech.txt'));
  });
  runApp(const DiaryBootstrapApp());
}
