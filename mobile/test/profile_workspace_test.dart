import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/pages/profile/profile_page.dart';

void main() {
  testWidgets(
    'profile groups diary work before data and application preferences',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.light,
          home: ProfilePage(
            entryCount: 8,
            trashCount: 2,
            onOpenRecycle: () {},
            onOpenSettings: () {},
            onOpenCategories: () {},
            onOpenBackup: () {},
            onOpenAbout: () {},
            onOpenMedia: () {},
            onOpenInsights: () {},
            onOpenFavorites: () {},
          ),
        ),
      );

      expect(find.text('回看'), findsOneWidget);
      expect(find.text('整理'), findsOneWidget);
      expect(find.text('数据'), findsOneWidget);
      expect(find.text('应用'), findsOneWidget);
      expect(find.text('同步'), findsOneWidget);
      expect(find.text('备份与恢复'), findsOneWidget);

      final revisit = tester.getTopLeft(find.text('回看')).dy;
      final organize = tester.getTopLeft(find.text('整理')).dy;
      final data = tester.getTopLeft(find.text('数据')).dy;
      final app = tester.getTopLeft(find.text('应用')).dy;
      expect(revisit, lessThan(organize));
      expect(organize, lessThan(data));
      expect(data, lessThan(app));
    },
  );

  testWidgets('keeps the original banner and exposes avatar choices', (
    tester,
  ) async {
    var pickRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: ProfilePage(
          entryCount: 8,
          trashCount: 2,
          onOpenRecycle: () {},
          onOpenSettings: () {},
          onOpenCategories: () {},
          onOpenBackup: () {},
          onOpenAbout: () {},
          profileAvatarPath: 'missing-avatar.jpg',
          onPickAvatar: () async => pickRequested = true,
          onClearAvatar: () async {},
        ),
      ),
    );

    expect(find.text('写给自己的日记'), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-button')), findsOneWidget);
    expect(find.textContaining('已写下'), findsNothing);

    await tester.tap(find.byKey(const Key('profile-avatar-button')));
    await tester.pumpAndSettle();
    expect(find.text('从相册选择'), findsOneWidget);
    expect(find.text('恢复默认头像'), findsOneWidget);

    await tester.tap(find.text('从相册选择'));
    await tester.pumpAndSettle();
    expect(pickRequested, isTrue);
  });
}
