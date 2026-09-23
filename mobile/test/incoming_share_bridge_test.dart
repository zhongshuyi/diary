import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/incoming_share_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ling.diary/incoming_share');

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads shared text and images, then acknowledges the share', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'takePendingShare') {
            return {
              'id': 'share-1',
              'text': '读到的一句话',
              'imagePaths': ['/cache/picture.jpg'],
            };
          }
          return null;
        });

    final bridge = IncomingShareBridge(channel: channel);
    final share = await bridge.takePendingShare();
    expect(share?.id, 'share-1');
    expect(share?.text, '读到的一句话');
    expect(share?.imagePaths, ['/cache/picture.jpg']);
    await bridge.completePendingShare(share!.id);
    expect(calls, ['takePendingShare', 'completePendingShare']);
  });

  test('notifies Dart about shares and shortcuts', () async {
    var shares = 0;
    var shortcuts = 0;
    final bridge = IncomingShareBridge(channel: channel);
    bridge.listen(
      onShareAvailable: () => shares++,
      onShortcutAvailable: () => shortcuts++,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('shareAvailable'),
      ),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('shortcutAvailable'),
      ),
      (_) {},
    );
    expect(shares, 1);
    expect(shortcuts, 1);
    bridge.dispose();
  });
}
