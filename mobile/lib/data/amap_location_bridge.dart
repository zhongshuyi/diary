import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_place.dart';

class AmapLocationBridge {
  static const _channel = MethodChannel('com.ling.diary/amap_location');

  static Future<DiaryPlace?> pick(BuildContext context, String key) async {
    if (!_ready(context, key) || !await _requestConsent(context)) return null;
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pickPlace',
      {'key': key.trim()},
    );
    if (result == null) return null;
    return DiaryPlace(
      name: '${result['name'] ?? ''}',
      address: '${result['address'] ?? ''}',
      latitude: (result['latitude'] as num).toDouble(),
      longitude: (result['longitude'] as num).toDouble(),
    );
  }

  static Future<void> showEntry(
    BuildContext context,
    DiaryEntry entry,
    String key,
  ) async {
    if (!_ready(context, key) || !await _requestConsent(context)) return;
    try {
      await _channel.invokeMethod<void>('showPlace', {
        'key': key.trim(),
        'name': entry.positions.first,
        'address': entry.positions.length > 1 ? entry.positions[1] : '',
        'latitude': entry.latitude,
        'longitude': entry.longitude,
      });
    } on PlatformException {
      if (context.mounted) _message(context, '暂时无法打开地图');
    }
  }

  static bool _ready(BuildContext context, String key) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _message(context, '当前仅支持 Android 地图');
      return false;
    }
    if (key.trim().isEmpty) {
      _message(context, '请先在设置中填写高德 Android Key');
      return false;
    }
    return true;
  }

  static Future<bool> _requestConsent(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('使用高德地图'),
        content: const Text(
          '选择位置时，高德地图 SDK 会处理位置信息、Wi-Fi 与网络信息，以提供定位、附近地点和地图。请先阅读高德地图开放平台隐私政策。',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://lbs.amap.com/pages/privacy/')),
            child: const Text('查看隐私政策'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
    return agreed == true && context.mounted;
  }

  static void _message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
