import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/diary_lock_gate.dart';
import 'package:diary/application/app_lock_service.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/recycle/recycle_page.dart';
import 'package:diary/pages/settings/backup_page.dart';

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore(this.settings);

  DiarySettings settings;

  @override
  Future<DiarySettings> load() async => settings;

  @override
  Future<void> save(DiarySettings value) async => settings = value;
}

class _EmptyPinStore implements PinSecretStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> delete() async {}
}

DiaryEntry _entry({String id = 'entry-1'}) {
  final now = DateTime(2026, 9, 17);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    title: '带附件的日记',
    content: '正文',
    contentText: '正文',
    category: '生活',
    imagePaths: const ['photo.jpg'],
  );
}

void main() {
  testWidgets('keeps the privacy lock visible after a failed attempt', (
    tester,
  ) async {
    final controller = SettingsController(
      store: _MemorySettingsStore(const DiarySettings(biometricLock: true)),
    );
    await controller.initialize();
    final coordinator = DiaryLockCoordinator();
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DiaryLockGate(
          controller: controller,
          coordinator: coordinator,
          lockService: AppLockService(store: _EmptyPinStore()),
          authenticate: () async {
            attempts += 1;
            return attempts > 1;
          },
          child: const Text('私密内容'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('日记已锁定'), findsOneWidget);
    expect(find.text('验证未完成，请点击按钮重试'), findsOneWidget);

    await tester.tap(find.text('解锁日记'));
    await tester.pump();

    expect(find.text('私密内容'), findsOneWidget);
  });

  testWidgets('explains attachment risk before permanent deletion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecyclePage(
          entries: [_entry()],
          onRestore: (_) {},
          onDelete: (_) {},
          onEmpty: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('永久删除'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 个附件'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('confirms the scope before emptying the recycle bin', (
    tester,
  ) async {
    var emptied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RecyclePage(
          entries: [_entry()],
          onRestore: (_) {},
          onDelete: (_) {},
          onEmpty: () async => emptied = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('empty-recycle-bin')));
    await tester.pumpAndSettle();

    expect(find.textContaining('将永久删除 1 篇日记'), findsOneWidget);
    expect(emptied, isFalse);

    await tester.tap(find.byKey(const Key('confirm-empty-recycle-bin')));
    await tester.pumpAndSettle();

    expect(emptied, isTrue);
  });

  testWidgets('confirms the scope before importing a backup', (tester) async {
    var imported = false;
    final payload = utf8.encode(jsonEncode([_entry().toJson()]));
    await tester.pumpWidget(
      MaterialApp(
        home: BackupPage(
          entries: const [],
          pickBackupBytes: () async => payload,
          onImport: (_) async => imported = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导入日记备份'));
    await tester.pump();

    expect(find.textContaining('将导入 1 篇日记'), findsOneWidget);
    expect(imported, isFalse);

    await tester.tap(find.text('确认导入'));
    await tester.pumpAndSettle();

    expect(imported, isTrue);
  });
}
