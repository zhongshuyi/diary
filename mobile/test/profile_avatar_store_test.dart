import 'dart:io';
import 'dart:typed_data';

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
    expect(replacementPath, isNot(path));
    expect(await File(replacementPath).readAsBytes(), [4, 5, 6]);
    expect(await File(path).exists(), isFalse);

    await store.clear();
    expect(await File(replacementPath).exists(), isFalse);
  });

  test('writes a cropped avatar to a new app-owned path', () async {
    final sandbox = await Directory.systemTemp.createTemp('diary-avatar-test-');
    addTearDown(() => sandbox.delete(recursive: true));
    final store = ProfileAvatarStore(
      rootDirectory: Directory(
        '${sandbox.path}${Platform.pathSeparator}profile-avatar',
      ),
    );

    final path = await store.savePng(Uint8List.fromList([1, 2, 3]));

    expect(path, endsWith('.png'));
    expect(await File(path).readAsBytes(), [1, 2, 3]);
  });

  test(
    'replacing and clearing companion avatars keeps the own avatar',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'diary-avatar-test-',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final own = ProfileAvatarStore(
        rootDirectory: Directory('${sandbox.path}/profile-avatar'),
      );
      final companion = ProfileAvatarStore(
        rootDirectory: Directory('${sandbox.path}/companion-avatar'),
        role: ProfileAvatarRole.companion,
      );
      final ownPath = await own.savePng(Uint8List.fromList([1, 2, 3]));
      final firstCompanionPath = await companion.savePng(
        Uint8List.fromList([4, 5, 6]),
      );
      final secondCompanionPath = await companion.savePng(
        Uint8List.fromList([7, 8, 9]),
      );
      expect(await File(firstCompanionPath).exists(), isFalse);
      expect(await File(ownPath).readAsBytes(), [1, 2, 3]);

      await companion.clear();
      expect(await File(secondCompanionPath).exists(), isFalse);
      expect(await File(ownPath).readAsBytes(), [1, 2, 3]);

      final restoredCompanionPath = await companion.savePng(
        Uint8List.fromList([4, 5, 6]),
      );
      await own.clear();
      expect(await File(restoredCompanionPath).readAsBytes(), [4, 5, 6]);
    },
  );
}
