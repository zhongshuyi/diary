import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/mobile_diary_shell.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  required String title,
  bool favorite = false,
}) {
  final now = DateTime(2026, 9, 20, 10);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    title: title,
    content: '正文：$title',
    contentText: '正文：$title',
    category: '生活',
    isFavorite: favorite,
  );
}

DiaryShellActions _actions() {
  return DiaryShellActions(
    openEditor: ([DiaryEntry? _]) async {},
    openEditorFromQuick: (_, _) async {},
    openEntry: (_) async {},
    toggleFavorite: (_) async {},
    openShare: (_) async {},
    moveToTrash: (_) async {},
    saveQuickCapture: (_) async {},
    saveQuickCaptureWithPhotos: (_, _) async {},
    saveQuickCaptureWithMedia: (_, _, _) async {},
    saveChatMessage: (_, _, _, _, _, _) async {},
    importQuickPhotos: (paths) async => paths,
    loadDraft: (_) async => null,
    saveDraft: (_) async {},
    clearDraft: (_) async {},
    openRecycle: () async {},
    openSettings: () async {},
    openCategories: () async {},
    openBackup: () async {},
    openAbout: () async {},
    toggleTheme: () async {},
    saveEntry: (_) async {},
    beginExternalActivity: () {},
    endExternalActivity: () {},
    replaceEntries: (_) async {},
    restoreEntry: (_) async {},
    deleteEntryPermanently: (_) async {},
    clearTrash: () async {},
    openConflicts: () async {},
  );
}

Widget _buildMobileShell(ValueListenable<List<DiaryEntry>> entries) {
  return MaterialApp(
    home: ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: entries,
      builder: (context, value, _) => MobileDiaryShell(
        entries: value,
        trash: const [],
        actions: _actions(),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('profile opens Favorites with the live favorite count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entries = ValueNotifier<List<DiaryEntry>>([
      _entry(id: 'saved', title: '保留的一页', favorite: true),
      _entry(id: 'ordinary', title: '普通记录'),
    ]);
    await tester.pumpWidget(_buildMobileShell(entries));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('收藏夹'), findsOneWidget);
    expect(find.text('1 篇已收藏'), findsOneWidget);

    await tester.tap(find.text('收藏夹'));
    await tester.pumpAndSettle();
    expect(find.text('保留的一页'), findsOneWidget);

    entries.value = [_entry(id: 'saved', title: '保留的一页')];
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
  });
}
