import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/pages/profile/profile_page.dart';

void main() {
  testWidgets('profile avatar can be changed and removed', (tester) async {
    var changeRequested = false;
    var removalRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: ProfilePage(
          entryCount: 3,
          trashCount: 0,
          profileAvatarPath: 'avatar.jpg',
          onPickAvatar: () async {
            changeRequested = true;
          },
          onClearAvatar: () async {
            removalRequested = true;
          },
          onOpenRecycle: () {},
          onOpenSettings: () {},
          onOpenCategories: () {},
          onOpenBackup: () {},
          onOpenAbout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-avatar-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-avatar-button')));
    await tester.pump();
    expect(changeRequested, isTrue);

    await tester.tap(find.byKey(const Key('profile-avatar-reset-button')));
    await tester.pump();
    expect(removalRequested, isTrue);
  });
}
