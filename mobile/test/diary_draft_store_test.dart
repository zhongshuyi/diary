import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_draft_store.dart';

void main() {
  test('memory draft store round trips and clears a draft', () async {
    final store = MemoryDiaryDraftStore();
    const draft = <String, dynamic>{'title': '晚风', 'contentText': '今天的风很轻。'};

    await store.save('new-entry', draft);

    expect(await store.load('new-entry'), draft);
    await store.clear('new-entry');
    expect(await store.load('new-entry'), isNull);
  });
}
