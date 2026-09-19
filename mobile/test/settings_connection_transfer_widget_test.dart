import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/settings/settings_page.dart';

void main() {
  testWidgets('copies and imports a portable connection package before saving', (
    tester,
  ) async {
    final store = _MemorySettingsStore(
      const DiarySettings(
        syncEndpoint: 'http://sync.example.com',
        syncToken: 'token-123',
        updateEndpoint: 'https://updates.example.com',
      ),
    );
    final controller = SettingsController(store: store);
    await controller.initialize();
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: SettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('双端同步'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('复制连接配置'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制连接配置'));
    await tester.pump();
    expect(
      clipboardText,
      'DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoxLCJzeW5jRW5kcG9pbnQiOiJodHRwOi8vc3luYy5leGFtcGxlLmNvbSIsInN5bmNUb2tlbiI6InRva2VuLTEyMyIsInVwZGF0ZUVuZHBvaW50IjoiaHR0cHM6Ly91cGRhdGVzLmV4YW1wbGUuY29tIn0',
    );

    clipboardText =
        'DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoxLCJzeW5jRW5kcG9pbnQiOiJodHRwOi8vc3luYy5leGFtcGxlLmNvbSIsInN5bmNUb2tlbiI6InRva2VuLTQ1NiIsInVwZGF0ZUVuZHBvaW50IjoiaHR0cHM6Ly91cGRhdGVzLmV4YW1wbGUuY29tIn0';
    await tester.tap(find.text('粘贴并导入'));
    await tester.pump();
    await tester.ensureVisible(find.text('保存连接'));
    await tester.tap(find.text('保存连接'));
    await tester.pump();

    expect(store.value.syncEndpoint, 'http://sync.example.com');
    expect(store.value.syncToken, 'token-456');
    expect(store.value.updateEndpoint, 'https://updates.example.com');
  });
}

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore(this.value);

  DiarySettings value;

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async => value = settings;
}
