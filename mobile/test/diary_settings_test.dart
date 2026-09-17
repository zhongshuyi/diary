import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

void main() {
  test(
    'settings controller persists user preferences through its store',
    () async {
      final store = _MemorySettingsStore();
      final controller = SettingsController(store: store);

      await controller.initialize();
      await controller.setThemeMode(DiaryThemeMode.dark);
      await controller.setFontScale(1.2);
      await controller.setDefaultEditorType(DiaryEditorType.markdown);
      await controller.setShowWordCount(false);
      await controller.setQuickCaptureSide(QuickCaptureSide.left);

      expect(store.value.themeMode, DiaryThemeMode.dark);
      expect(store.value.fontScale, 1.2);
      expect(store.value.defaultEditorType, DiaryEditorType.markdown);
      expect(store.value.showWordCount, isFalse);
      expect(store.value.quickCaptureSide, QuickCaptureSide.left);
    },
  );

  test(
    'quick capture defaults to the right and survives controller reload',
    () async {
      final store = _MemorySettingsStore();
      final first = SettingsController(store: store);
      await first.initialize();
      expect(first.settings.quickCaptureSide, QuickCaptureSide.right);
      await first.setQuickCaptureSide(QuickCaptureSide.left);

      final reopened = SettingsController(store: store);
      await reopened.initialize();
      expect(reopened.settings.quickCaptureSide, QuickCaptureSide.left);
    },
  );

  test(
    'settings store falls back to safe values for invalid font scale',
    () async {
      final store = _MemorySettingsStore(const DiarySettings(fontScale: 5));
      final controller = SettingsController(store: store);

      await controller.initialize();

      expect(controller.settings.fontScale, 1.3);
    },
  );

  test('saved button side round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(
      const DiarySettings(quickCaptureSide: QuickCaptureSide.left),
    );
    expect((await store.load()).quickCaptureSide, QuickCaptureSide.left);
  });
}

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore([DiarySettings? initial])
    : value = initial ?? const DiarySettings();

  DiarySettings value;

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async => value = settings;
}
