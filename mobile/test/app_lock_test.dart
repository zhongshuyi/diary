import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/diary_lock_gate.dart';
import 'package:diary/application/app_lock_service.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/app_lock_settings.dart';

class _MemoryPinStore implements PinSecretStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String next) async => value = next;

  @override
  Future<void> delete() async => value = null;
}

class _MemorySettingsStore implements DiarySettingsStore {
  DiarySettings value = const DiarySettings();

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async => value = settings;
}

Future<void> _enter(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-digit-$digit')));
    await tester.pump();
  }
}

void main() {
  test(
    'PIN is stored as a verifier and survives a new service instance',
    () async {
      final store = _MemoryPinStore();
      final lock = AppLockService(store: store);
      await lock.setPin('123456');

      expect(store.value, isNot(contains('123456')));
      expect(await AppLockService(store: store).verifyPin('123456'), isTrue);
      expect(await lock.verifyPin('654321'), isFalse);
      await lock.removePin();
      expect(store.value, isNull);
    },
  );

  testWidgets('sets a PIN twice and unlocks with the keypad', (tester) async {
    final pinStore = _MemoryPinStore();
    final lock = AppLockService(store: pinStore);
    final controller = SettingsController(store: _MemorySettingsStore());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppLockSettings(controller: controller, lockService: lock),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-app-pin')));
    await tester.pumpAndSettle();
    await _enter(tester, '123456');
    expect(find.text('再次输入密码'), findsOneWidget);
    await _enter(tester, '123456');
    await tester.pumpAndSettle();
    expect(lock.hasPin, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: DiaryLockGate(
          controller: controller,
          coordinator: DiaryLockCoordinator(),
          lockService: AppLockService(store: pinStore),
          child: const Text('私密内容'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('日记已锁定'), findsOneWidget);
    expect(find.text('私密内容'), findsNothing);
    await _enter(tester, '000000');
    await tester.pumpAndSettle();
    expect(find.text('密码不正确，请重试'), findsOneWidget);
    await _enter(tester, '123456');
    expect(find.text('私密内容'), findsOneWidget);
  });

  testWidgets('locks again after the app leaves the foreground', (
    tester,
  ) async {
    final pinStore = _MemoryPinStore();
    await AppLockService(store: pinStore).setPin('123456');
    final controller = SettingsController(store: _MemorySettingsStore());
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryLockGate(
          controller: controller,
          coordinator: DiaryLockCoordinator(),
          lockService: AppLockService(store: pinStore),
          child: const Text('私密内容'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _enter(tester, '123456');
    expect(find.text('私密内容'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('日记已锁定'), findsOneWidget);
    expect(find.text('私密内容'), findsNothing);
  });

  testWidgets('cancelled biometrics stays on PIN and manual retry works', (
    tester,
  ) async {
    final pinStore = _MemoryPinStore();
    await AppLockService(store: pinStore).setPin('123456');
    final settingsStore = _MemorySettingsStore()
      ..value = const DiarySettings(biometricLock: true);
    final controller = SettingsController(store: settingsStore);
    await controller.initialize();
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryLockGate(
          controller: controller,
          coordinator: DiaryLockCoordinator(),
          lockService: AppLockService(store: pinStore),
          authenticate: () async => ++attempts > 1,
          child: const Text('私密内容'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.byTooltip('使用指纹解锁'), findsOneWidget);
    expect(find.text('日记已锁定'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(attempts, 1);

    await tester.tap(find.byTooltip('使用指纹解锁'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('私密内容'), findsOneWidget);
  });
}
