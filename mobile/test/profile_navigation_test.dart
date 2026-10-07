import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/pages/profile/profile_page.dart';

void main() {
  Widget page({
    required void Function(String action) onAction,
    bool desktopLayout = false,
    int conflictCount = 0,
    bool showCompanion = true,
    double textScale = 1,
  }) => MaterialApp(
    theme: DiaryTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: ProfilePage(
            desktopLayout: desktopLayout,
            entryCount: 12,
            trashCount: 2,
            favoriteCount: 3,
            profileName: '晚安日记',
            onOpenSettings: () => onAction('settings'),
            onOpenRecycle: () => onAction('recycle'),
            onOpenCategories: () => onAction('categories'),
            onOpenBackup: () => onAction('backup'),
            onOpenAbout: () => onAction('about'),
            onOpenFavorites: () => onAction('favorites'),
            onOpenMedia: () => onAction('media'),
            onOpenInsights: () => onAction('insights'),
            onOpenLocalAssistant: showCompanion
                ? () => onAction('assistant')
                : null,
            onOpenTranscription: showCompanion
                ? () => onAction('transcription')
                : null,
            onOpenChatAppearance: showCompanion
                ? () => onAction('appearance')
                : null,
            conflictCount: conflictCount,
            onOpenConflicts: () => onAction('conflicts'),
          ),
        ),
      ),
    ),
  );

  testWidgets('settings and companion shortcuts open their direct callbacks', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(page(onAction: actions.add));
    for (final item in [
      (key: 'settings', action: 'settings'),
      (key: 'favorites', action: 'favorites'),
      (key: 'media', action: 'media'),
      (key: 'insights', action: 'insights'),
      (key: 'assistant', action: 'assistant'),
      (key: 'transcription', action: 'transcription'),
      (key: 'chat-appearance', action: 'appearance'),
      (key: 'about', action: 'about'),
    ]) {
      final target = find.byKey(Key('profile-${item.key}-button'));
      await tester.ensureVisible(target);
      if (['favorites', 'media', 'insights'].contains(item.key)) {
        final row = tester.getRect(target);
        await tester.tapAt(Offset(row.right - 12, row.center.dy));
      } else {
        await tester.tap(target);
      }
      await tester.pump();
      expect(actions.last, item.action);
    }
    expect(find.text('偏好设置'), findsNothing);
    expect(find.byTooltip('设置'), findsOneWidget);
  });

  testWidgets('optional companion section stays hidden without callbacks', (
    tester,
  ) async {
    await tester.pumpWidget(page(onAction: (_) {}, showCompanion: false));
    expect(find.text('记录与陪伴'), findsNothing);
    expect(find.text('数据与整理'), findsOneWidget);
    expect(find.text('同步冲突'), findsNothing);
  });

  testWidgets(
    'settings remains visible and tappable after scrolling to bottom',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await tester.pumpWidget(page(onAction: actions.add, textScale: 2));
      final settings = find.byKey(const Key('profile-settings-button'));
      final position = tester.getTopLeft(settings);
      await tester.ensureVisible(find.byKey(const Key('profile-about-button')));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(settings), position);
      expect(settings.hitTestable(), findsOneWidget);
      await tester.tap(settings);
      await tester.pump();
      expect(actions, ['settings']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sync fallback and visible conflicts retain existing actions', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(page(onAction: actions.add, conflictCount: 2));
    for (final item in [
      (label: '同步', action: 'settings'),
      (label: '同步冲突', action: 'conflicts'),
    ]) {
      await tester.ensureVisible(find.text(item.label));
      await tester.tap(find.text(item.label));
      await tester.pump();
      expect(actions.last, item.action);
    }
    expect(find.text('2 篇待确认'), findsOneWidget);
  });

  testWidgets('large text keeps shortcut rows usable on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page(onAction: (_) {}, textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final favorites = find.byKey(const Key('profile-favorites-button'));
    final media = find.byKey(const Key('profile-media-button'));
    final insights = find.byKey(const Key('profile-insights-button'));
    expect(
      tester.getTopLeft(favorites).dy,
      lessThan(tester.getTopLeft(media).dy),
    );
    expect(
      tester.getTopLeft(insights).dy,
      greaterThan(tester.getTopLeft(media).dy),
    );
    for (final shortcut in [favorites, media, insights]) {
      expect(tester.getTopLeft(shortcut).dx, tester.getTopLeft(favorites).dx);
      expect(tester.getSize(shortcut).width, tester.getSize(favorites).width);
      expect(tester.getSize(shortcut).height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getTopLeft(find.text('收藏夹')).dx,
      tester.getTopLeft(find.text('媒体库')).dx,
    );
    expect(
      tester.getTopLeft(find.text('媒体库')).dx,
      tester.getTopLeft(find.text('洞察')).dx,
    );
    await tester.ensureVisible(
      find.byKey(const Key('profile-chat-appearance-button')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop profile also exposes new feature callbacks', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(page(onAction: actions.add, desktopLayout: true));
    for (final item in [
      (label: '日记陪伴', action: 'assistant'),
      (label: '录音转文字', action: 'transcription'),
      (label: '对话外观', action: 'appearance'),
    ]) {
      await tester.ensureVisible(find.text(item.label));
      await tester.tap(find.text(item.label));
      await tester.pump();
      expect(actions.last, item.action);
    }
  });
}
