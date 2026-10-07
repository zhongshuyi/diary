import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/pages/profile/profile_page.dart';

void main() {
  testWidgets(
    'profile brings frequent features above data without nested preferences',
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
            favoriteCount: 3,
            onOpenLocalAssistant: () {},
            onOpenTranscription: () {},
            onOpenChatAppearance: () {},
          ),
        ),
      );

      expect(find.text('记录与陪伴'), findsOneWidget);
      expect(find.text('数据与整理'), findsOneWidget);
      expect(find.text('偏好设置'), findsNothing);
      expect(find.text('应用'), findsNothing);
      expect(find.text('关于'), findsNothing);
      expect(find.text('同步'), findsOneWidget);
      expect(find.text('备份与恢复'), findsOneWidget);
      expect(find.text('3 篇'), findsOneWidget);
      expect(find.byKey(const Key('profile-settings-button')), findsOneWidget);

      final shortcuts = tester
          .getTopLeft(find.byKey(const Key('profile-shortcuts')))
          .dy;
      final companion = tester.getTopLeft(find.text('记录与陪伴')).dy;
      final data = tester.getTopLeft(find.text('数据与整理')).dy;
      expect(shortcuts, lessThan(companion));
      expect(companion, lessThan(data));
      expect(
        tester.getTopLeft(find.text('收藏夹')).dy,
        lessThan(tester.getTopLeft(find.text('媒体库')).dy),
      );
      expect(
        tester.getTopLeft(find.text('媒体库')).dy,
        lessThan(tester.getTopLeft(find.text('洞察')).dy),
      );
      expect(
        tester.getTopLeft(find.text('收藏夹')).dx,
        tester.getTopLeft(find.text('媒体库')).dx,
      );
      expect(
        tester.getTopLeft(find.text('媒体库')).dx,
        tester.getTopLeft(find.text('洞察')).dx,
      );
      expect(
        tester.getTopLeft(find.text('收藏夹')).dx,
        lessThan(
          tester.getCenter(find.byKey(const Key('profile-shortcuts'))).dx,
        ),
      );
      expect(
        tester.getTopLeft(find.text('3 篇')).dx,
        greaterThan(tester.getTopLeft(find.text('收藏夹')).dx),
      );
      expect(
        tester.getCenter(find.text('3 篇')).dy,
        closeTo(tester.getCenter(find.text('收藏夹')).dy, 1),
      );
    },
  );

  testWidgets('offers a direct, visible avatar edit affordance', (
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
          onSaveProfile: (name, signature, showSignature) async {},
        ),
      ),
    );

    expect(find.byKey(const Key('profile-identity-panel')), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-button')), findsOneWidget);
    expect(
      find.byKey(const Key('profile-avatar-edit-indicator')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profile-avatar-button')));
    await tester.pumpAndSettle();
    expect(pickRequested, isTrue);

    final panel = tester.widget<Container>(
      find.byKey(const Key('profile-identity-panel')),
    );
    expect((panel.decoration! as BoxDecoration).color, DiaryPalette.surface);
    expect(find.byKey(const Key('profile-edit-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-signature-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-name-field')), findsOneWidget);
  });

  testWidgets('profile name and icon fit on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: Scaffold(
          body: ProfilePage(
            entryCount: 8,
            trashCount: 0,
            profileName: '很长很长的对话昵称',
            profileSignature: '记下每一个值得珍藏的瞬间',
            onSaveProfile: (name, signature, showSignature) async {},
            onOpenRecycle: () {},
            onOpenSettings: () {},
            onOpenCategories: () {},
            onOpenBackup: () {},
            onOpenAbout: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-edit-button')), findsOneWidget);
    expect(find.text('A QUIET PLACE FOR YOU'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('记下每一个值得珍藏的瞬间')).style?.fontStyle,
      FontStyle.italic,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signature accent is centered and visibility keeps its text', (
    tester,
  ) async {
    var visible = true;
    String? savedSignature;
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => ProfilePage(
            entryCount: 1,
            trashCount: 0,
            profileName: '晚安日记',
            profileSignature: '记录今天',
            showProfileSignature: visible,
            onSaveProfile: (name, signature, showSignature) async {
              savedSignature = signature;
              setState(() => visible = showSignature);
            },
            onOpenRecycle: () {},
            onOpenSettings: () {},
            onOpenCategories: () {},
            onOpenBackup: () {},
            onOpenAbout: () {},
          ),
        ),
      ),
    );

    final signatureCenter = tester.getCenter(find.text('记录今天')).dy;
    final accentCenter = tester
        .getCenter(find.byKey(const Key('profile-signature-accent')))
        .dy;
    expect((signatureCenter - accentCenter).abs(), lessThan(1));

    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('profile-signature-visibility-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-save-button')));
    await tester.pumpAndSettle();

    expect(savedSignature, '记录今天');
    expect(visible, isFalse);
    expect(find.text('记录今天'), findsNothing);
    expect(find.byKey(const Key('profile-signature-button')), findsNothing);
    expect(tester.widget<Text>(find.text('晚安日记')).style?.fontSize, 26);
    final nameCenter = tester.getCenter(find.text('晚安日记')).dy;
    final avatarCenter = tester
        .getCenter(find.byKey(const Key('profile-avatar-button')))
        .dy;
    expect((nameCenter - avatarCenter).abs(), lessThan(1));

    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('profile-signature-visibility-switch')),
    );
    expect(toggle.value, isFalse);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('profile-signature-field')))
          .controller
          ?.text,
      '记录今天',
    );
  });
}
