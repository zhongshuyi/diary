import 'package:flutter/material.dart';

import 'app/diary_app.dart';

export 'app/diary_app.dart' show DiaryBootstrapApp, MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiaryBootstrapApp());
}
