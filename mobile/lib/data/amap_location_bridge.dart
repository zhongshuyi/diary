import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_place.dart';
import 'package:diary/app/app_theme.dart';

class AmapLocationBridge {
  static const _channel = MethodChannel('com.ling.diary/amap_location');
  static const _consentKey = 'diary.amap.privacy_consent';

  static Future<void> revokeConsent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_consentKey);
  }

  static Future<DiaryPlace?> pick(
    BuildContext context,
    String key, {
    bool includeThumbnail = true,
  }) async {
    if (!_ready(context, key)) return null;
    final appearance = _appearance(context);
    if (!await _requestConsent(context)) return null;
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pickPlace',
      {'key': key.trim(), 'includeThumbnail': includeThumbnail, ...appearance},
    );
    if (result == null) return null;
    return DiaryPlace(
      name: '${result['name'] ?? ''}',
      address: '${result['address'] ?? ''}',
      latitude: (result['latitude'] as num).toDouble(),
      longitude: (result['longitude'] as num).toDouble(),
      thumbnailPath: result['thumbnailPath'] as String?,
    );
  }

  static Future<void> showEntry(
    BuildContext context,
    DiaryEntry entry,
    String key,
  ) async {
    if (!_ready(context, key)) return;
    final appearance = _appearance(context);
    if (!await _requestConsent(context)) return;
    try {
      await _channel.invokeMethod<void>('showPlace', {
        'key': key.trim(),
        ...appearance,
        'name': entry.locationDisplayName,
        'address': entry.locationDisplayAddress,
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

  static Map<String, Object> _appearance(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<DiaryThemeColors>() ?? DiaryThemeColors.light;
    return {
      'paperColor': colors.paper.toARGB32(),
      'surfaceColor': colors.surface.toARGB32(),
      'inkColor': colors.ink.toARGB32(),
      'mutedColor': colors.mutedInk.toARGB32(),
      'lineColor': colors.line.toARGB32(),
      'accentColor': colors.terracotta.toARGB32(),
      'accentSoftColor': colors.terracottaSoft.toARGB32(),
      'onAccentColor': theme.colorScheme.onPrimary.toARGB32(),
      'darkTheme': theme.brightness == Brightness.dark,
    };
  }

  static Future<bool> _requestConsent(BuildContext context) async {
    final preferences = await SharedPreferences.getInstance();
    if (!context.mounted) return false;
    if (preferences.getBool(_consentKey) == true) return true;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('使用高德地图'),
        content: const Text(
          '查看或选择位置时，高德地图 SDK 会处理位置信息、Wi-Fi 与网络信息，以提供定位、附近地点和地图。请先阅读高德地图开放平台隐私政策。同意后不再重复询问，可在设置中撤回。',
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
    if (agreed != true || !context.mounted) return false;
    await preferences.setBool(_consentKey, true);
    return true;
  }

  static void _message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
