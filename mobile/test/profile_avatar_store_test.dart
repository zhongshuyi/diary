import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:diary/data/profile_avatar_store.dart';

void main() {
  test('copies an avatar into app-owned storage and clears it', () async {
    final sandbox = await Directory.systemTemp.createTemp('diary-avatar-test-');
    addTearDown(() => sandbox.delete(recursive: true));
    final source = File('${sandbox.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final store = ProfileAvatarStore(
      rootDirectory: Directory(
        '${sandbox.path}${Platform.pathSeparator}profile-avatar',
      ),
    );

    final path = await store.importFile(source.path);

    expect(path, isNot(source.path));
    expect(await File(path).readAsBytes(), [1, 2, 3]);

    await source.writeAsBytes([4, 5, 6]);
    final replacementPath = await store.importFile(source.path);
    expect(replacementPath, path);
    expect(await File(replacementPath).readAsBytes(), [4, 5, 6]);

    await store.clear();
    expect(await File(path).exists(), isFalse);
  });
}
