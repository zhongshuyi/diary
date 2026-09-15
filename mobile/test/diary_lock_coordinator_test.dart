import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_lock_coordinator.dart';

void main() {
  test('tracks nested platform activities safely', () {
    final coordinator = DiaryLockCoordinator();

    expect(coordinator.isExternalActivityActive, isFalse);
    coordinator.beginExternalActivity();
    coordinator.beginExternalActivity();
    expect(coordinator.isExternalActivityActive, isTrue);

    coordinator.endExternalActivity();
    expect(coordinator.isExternalActivityActive, isTrue);
    coordinator.endExternalActivity();
    coordinator.endExternalActivity();
    expect(coordinator.isExternalActivityActive, isFalse);
  });
}
