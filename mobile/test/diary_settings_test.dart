import 'package:flutter_test/flutter_test.dart';

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

      expect(store.value.themeMode, DiaryThemeMode.dark);
      expect(store.value.fontScale, 1.2);
      expect(store.value.defaultEditorType, DiaryEditorType.markdown);
      expect(store.value.showWordCount, isFalse);
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
