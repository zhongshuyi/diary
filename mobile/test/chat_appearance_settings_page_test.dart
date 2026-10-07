import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/settings/chat_appearance_settings_page.dart';
import 'package:diary/widgets/diary_chat_appearance.dart';

void main() {
  testWidgets('each layout previews the persisted participants', (
    tester,
  ) async {
    final controller = await _controller(
      const DiarySettings(
        chatStyle: DiaryChatStyle.soft,
        chatTitle: '晚安日记',
        companionName: '不应展示的旧称呼',
        profileAvatarPath: 'missing-self.jpg',
        companionAvatarPath: 'missing-companion.jpg',
        chatBackground: DiaryChatBackground(
          imagePath: 'missing-background.jpg',
          scale: 1.3,
          opacity: .3,
        ),
      ),
    );
    await _show(tester, ChatAppearanceSettingsPage(controller: controller));

    for (final style in DiaryChatStyle.values) {
      final card = find.byKey(Key('chat-appearance-style-${style.name}'));
      await _reveal(tester, card);
      final preview = tester.widget<DiaryChatAppearancePreview>(
        find.descendant(
          of: card,
          matching: find.byType(DiaryChatAppearancePreview),
        ),
      );
      expect(preview.style, style);
      expect(preview.showAvatars, isTrue);
      expect(preview.selfAvatarPath, 'missing-self.jpg');
      expect(preview.companionAvatarPath, 'missing-companion.jpg');
      expect(preview.title, '晚安日记');
      expect(preview.background.imagePath, 'missing-background.jpg');
      expect(preview.background.scale, 1.3);
      expect(preview.background.opacity, .3);
      expect(find.text('不应展示的旧称呼'), findsNothing);
    }
    expect(
      find.byKey(const Key('chat-appearance-selected-soft')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'choosing a layout saves immediately and preserves the profile title',
    (tester) async {
      final store = _MemorySettingsStore(
        const DiarySettings(chatTitle: '晚安日记'),
      );
      final controller = SettingsController(store: store);
      await controller.initialize();
      await _show(tester, ChatAppearanceSettingsPage(controller: controller));
      final style = find.text('经典聊天');
      await _reveal(tester, style);
      await tester.pumpAndSettle();
      await tester.tap(style);
      await tester.pumpAndSettle();

      expect(store.value.chatStyle, DiaryChatStyle.messenger);
      expect(store.value.chatTitle, '晚安日记');
      expect(
        find.byKey(const Key('chat-appearance-selected-messenger')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'previews follow the profile title without a separate name editor',
    (tester) async {
      final store = _MemorySettingsStore();
      final controller = SettingsController(store: store);
      await controller.initialize();
      await _show(tester, ChatAppearanceSettingsPage(controller: controller));
      expect(store.saves, 0);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('陪伴者称呼'), findsNothing);
      expect(find.text('保存称呼'), findsNothing);
      await controller.setProfileDetails('  睡前片刻  ', '记录今天', true);
      await tester.pumpAndSettle();

      expect(store.saves, 1);
      expect(store.value.chatTitle, '睡前片刻');
      for (final style in DiaryChatStyle.values) {
        final card = find.byKey(Key('chat-appearance-style-${style.name}'));
        await _reveal(tester, card);
        expect(
          tester
              .widget<DiaryChatAppearancePreview>(
                find.descendant(
                  of: card,
                  matching: find.byType(DiaryChatAppearancePreview),
                ),
              )
              .title,
          '睡前片刻',
        );
      }
      await _reveal(tester, find.text('陪伴者头像'));
      expect(find.byType(TextField), findsNothing);
      expect(
        find.byKey(const Key('chat-appearance-companion-name')),
        findsNothing,
      );
      expect(find.byKey(const Key('chat-appearance-save-name')), findsNothing);
    },
  );

  testWidgets('each participant invokes its own picker and default action', (
    tester,
  ) async {
    final controller = await _controller(
      const DiarySettings(
        profileAvatarPath: 'self.jpg',
        companionAvatarPath: 'friend.jpg',
      ),
    );
    var ownPicks = 0;
    var companionPicks = 0;
    await _show(
      tester,
      ChatAppearanceSettingsPage(
        controller: controller,
        onPickOwnAvatar: () async {
          ownPicks++;
        },
        onPickCompanionAvatar: () async {
          companionPicks++;
        },
        onClearOwnAvatar: controller.clearProfileAvatarPath,
        onClearCompanionAvatar: controller.clearCompanionAvatarPath,
      ),
    );

    final own = find.text('我的头像');
    await _reveal(tester, own);
    await tester.pumpAndSettle();
    await tester.tap(own);
    await tester.pumpAndSettle();
    expect(ownPicks, 1);
    expect(companionPicks, 0);

    final companion = find.text('陪伴者头像');
    await _reveal(tester, companion);
    await tester.tap(companion);
    await tester.pumpAndSettle();
    expect(companionPicks, 1);
    await tester.tap(
      find.byKey(const Key('chat-appearance-companion-avatar-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复默认头像'));
    await tester.pumpAndSettle();
    expect(controller.settings.companionAvatarPath, isNull);
    expect(controller.settings.profileAvatarPath, 'self.jpg');

    final ownMenu = find.byKey(const Key('chat-appearance-own-avatar-menu'));
    await _reveal(tester, ownMenu, delta: -250);
    await tester.tap(ownMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复默认头像'));
    await tester.pumpAndSettle();
    expect(controller.settings.profileAvatarPath, isNull);
  });

  testWidgets('the avatar switch updates both participants in all previews', (
    tester,
  ) async {
    final controller = await _controller(
      const DiarySettings(chatTitle: '晚安日记'),
    );
    await _show(tester, ChatAppearanceSettingsPage(controller: controller));
    final toggle = find.byKey(const Key('chat-appearance-show-avatars'));
    await _reveal(tester, toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(controller.settings.showChatAvatar, isFalse);
    expect(controller.settings.chatTitle, '晚安日记');
    for (final style in DiaryChatStyle.values.reversed) {
      final card = find.byKey(Key('chat-appearance-style-${style.name}'));
      await _reveal(tester, card, delta: -250);
      expect(
        tester
            .widget<DiaryChatAppearancePreview>(
              find.descendant(
                of: card,
                matching: find.byType(DiaryChatAppearancePreview),
              ),
            )
            .showAvatars,
        isFalse,
      );
    }
  });

  testWidgets('an in-flight picker blocks duplicate avatar requests', (
    tester,
  ) async {
    final controller = await _controller(const DiarySettings());
    final pending = Completer<void>();
    var picks = 0;
    await _show(
      tester,
      ChatAppearanceSettingsPage(
        controller: controller,
        onPickOwnAvatar: () async {
          picks++;
          await pending.future;
        },
      ),
    );
    final own = find.text('我的头像');
    await _reveal(tester, own);
    await tester.pumpAndSettle();
    await tester.tap(own);
    await tester.pump();
    await tester.tap(own);
    await tester.pump();
    expect(picks, 1);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('avatar failures provide a retry message without leaking paths', (
    tester,
  ) async {
    final controller = await _controller(const DiarySettings());
    await _show(
      tester,
      ChatAppearanceSettingsPage(
        controller: controller,
        onPickCompanionAvatar: () async =>
            throw StateError('/private/photo.jpg'),
      ),
    );
    final companion = find.text('陪伴者头像');
    await _reveal(tester, companion);
    await tester.pumpAndSettle();
    await tester.tap(companion);
    await tester.pumpAndSettle();

    expect(find.text('头像更新失败，请重试'), findsOneWidget);
    expect(find.textContaining('/private/photo.jpg'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screens and large text keep every control reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await _controller(
      const DiarySettings(
        chatStyle: DiaryChatStyle.messenger,
        chatTitle: '这是一个比较长的个人页对话标题',
      ),
    );
    await _show(
      tester,
      ChatAppearanceSettingsPage(controller: controller),
      largeText: true,
      dark: true,
    );
    expect(tester.takeException(), isNull);
    for (final style in DiaryChatStyle.values) {
      final label = find.text(style.label);
      await _reveal(tester, label);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await _reveal(tester, find.text('我的头像'));
    expect(tester.takeException(), isNull);
    await _reveal(tester, find.text('陪伴者头像'));
    expect(tester.takeException(), isNull);
    final toggle = find.byKey(const Key('chat-appearance-show-avatars'));
    await _reveal(tester, toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(controller.settings.showChatAvatar, isFalse);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<SettingsController> _controller(DiarySettings settings) async {
  final controller = SettingsController(store: _MemorySettingsStore(settings));
  await controller.initialize();
  return controller;
}

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 250,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
}

Future<void> _show(
  WidgetTester tester,
  Widget page, {
  bool largeText = false,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? DiaryTheme.dark : DiaryTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(largeText ? 1.3 : 1)),
        child: child!,
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore([this.value = const DiarySettings()]);

  DiarySettings value;
  int saves = 0;

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async {
    saves++;
    value = settings;
  }
}
