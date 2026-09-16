import 'package:flutter_test/flutter_test.dart';

import 'package:diary/data/diary_backup_service.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry() => DiaryEntry(
  id: 'backup-1',
  createdAt: DateTime(2026, 9, 16),
  updatedAt: DateTime(2026, 9, 16),
  title: '备份',
  content: '内容',
  contentText: '内容',
  category: '生活',
);

void main() {
  test('round trips entries through portable zip manifest', () {
    const service = DiaryBackupService();
    final bytes = service.exportZip(
      entries: [_entry()],
      settings: const {'theme': 'dark'},
    );
    final package = service.importZip(bytes);
    expect(package.entries.single.id, 'backup-1');
    expect(package.settings['theme'], 'dark');
    expect(bytes, isNotEmpty);
  });
}
