import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ling.diary/incoming_share');

  testWidgets('an Android share opens the editor with a recoverable draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    var pending = true;
    var acknowledged = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'takePendingShare':
              if (!pending) return null;
              return {
                'id': 'share-1',
                'text': '分享进来的文字',
                'imagePaths': <String>[],
              };
            case 'completePendingShare':
              expect(call.arguments, 'share-1');
              pending = false;
              acknowledged = true;
              return null;
            case 'takePendingShortcut':
              return null;
          }
          return null;
        });

    final repository = MemoryDiaryRepository();
    final settings = SettingsController(
      store: SharedPreferencesDiarySettingsStore(),
    );
    final lock = DiaryLockCoordinator();
    await settings.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryShell(
          repository: repository,
          settingsController: settings,
          lockCoordinator: lock,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(acknowledged, isTrue);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('entry-content-field')))
          .controller
          ?.text,
      '分享进来的文字',
    );
    expect(
      (await repository.loadDraft('incoming-share'))?.payload['content'],
      '分享进来的文字',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
    lock.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
