import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IncomingShare {
  const IncomingShare({
    required this.id,
    required this.text,
    required this.imagePaths,
  });

  final String id;
  final String text;
  final List<String> imagePaths;
}

class IncomingShareBridge {
  IncomingShareBridge({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.ling.diary/incoming_share');

  final MethodChannel _channel;

  void listen({
    required VoidCallback onShareAvailable,
    required VoidCallback onShortcutAvailable,
  }) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareAvailable') onShareAvailable();
      if (call.method == 'shortcutAvailable') onShortcutAvailable();
    });
  }

  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler(null);
    }
  }

  Future<IncomingShare?> takePendingShare() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    Map<String, dynamic>? payload;
    try {
      payload = await _channel.invokeMapMethod<String, dynamic>(
        'takePendingShare',
      );
    } on MissingPluginException {
      return null;
    }
    if (payload == null) return null;
    final text = payload['text'];
    final images = payload['imagePaths'];
    return IncomingShare(
      id: payload['id'] is String ? payload['id'] as String : '',
      text: text is String ? text : '',
      imagePaths: images is List
          ? images.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  Future<void> completePendingShare(String id) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>('completePendingShare', id);
  }

  Future<String?> takePendingShortcut() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _channel.invokeMethod<String>('takePendingShortcut');
  }
}
