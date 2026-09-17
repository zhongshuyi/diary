import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const defaultUpdateServerUrl = String.fromEnvironment(
  'DIARY_UPDATE_SERVER_URL',
  defaultValue: 'http://127.0.0.1:8787',
);
const currentAppVersion = String.fromEnvironment(
  'DIARY_APP_VERSION',
  defaultValue: '1.0.0',
);

class AppUpdateResult {
  const AppUpdateResult({
    required this.platform,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.notes,
  });

  final String platform;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String notes;

  bool get hasUpdate => compareAppVersions(latestVersion, currentVersion) > 0;
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateService {
  AppUpdateService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultUpdateServerUrl);

  final http.Client _client;
  final String _baseUrl;

  Future<AppUpdateResult> check({
    required String platform,
    required String currentVersion,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/update?platform=${Uri.encodeQueryComponent(platform)}',
    );
    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const UpdateCheckException('检查更新超时，请稍后重试');
    } on Object {
      throw const UpdateCheckException('无法连接更新服务器，请检查网络');
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      payload = Map<String, dynamic>.from(decoded);
    } on Object {
      throw const UpdateCheckException('更新服务器返回了无效数据');
    }

    if (response.statusCode != 200) {
      final error = payload['error'];
      final message = error is Map ? error['message'] : null;
      throw UpdateCheckException(
        message is String && message.isNotEmpty ? message : '暂时没有可用的更新信息',
      );
    }

    final data = payload['data'];
    if (data is! Map ||
        data['version'] is! String ||
        data['downloadUrl'] is! String) {
      throw const UpdateCheckException('更新信息不完整');
    }
    return AppUpdateResult(
      platform: data['platform'] is String
          ? data['platform'] as String
          : platform,
      currentVersion: currentVersion,
      latestVersion: data['version'] as String,
      downloadUrl: data['downloadUrl'] as String,
      notes: data['notes'] is String ? data['notes'] as String : '',
    );
  }
}

int compareAppVersions(String left, String right) {
  final leftVersion = _parseVersion(left);
  final rightVersion = _parseVersion(right);
  for (var index = 0; index < 4; index += 1) {
    final difference = leftVersion.core[index] - rightVersion.core[index];
    if (difference != 0) return difference.sign;
  }
  if (leftVersion.prerelease.isEmpty && rightVersion.prerelease.isEmpty) {
    return 0;
  }
  if (leftVersion.prerelease.isEmpty) return 1;
  if (rightVersion.prerelease.isEmpty) return -1;
  for (
    var index = 0;
    index < leftVersion.prerelease.length ||
        index < rightVersion.prerelease.length;
    index += 1
  ) {
    if (index >= leftVersion.prerelease.length) return -1;
    if (index >= rightVersion.prerelease.length) return 1;
    final difference = _compareIdentifiers(
      leftVersion.prerelease[index],
      rightVersion.prerelease[index],
    );
    if (difference != 0) return difference.sign;
  }
  return 0;
}

({List<int> core, List<String> prerelease}) _parseVersion(String value) {
  final normalized = value.trim().replaceFirst(
    RegExp(r'^v', caseSensitive: false),
    '',
  );
  final match = RegExp(
    r'^(\d+(?:\.\d+){0,3})(?:-([0-9A-Za-z.-]+))?$',
  ).firstMatch(normalized);
  if (match == null) throw FormatException('Invalid app version: $value');
  final core = match.group(1)!.split('.').map(int.parse).toList();
  while (core.length < 4) {
    core.add(0);
  }
  return (core: core, prerelease: match.group(2)?.split('.') ?? const []);
}

int _compareIdentifiers(String left, String right) {
  final leftNumeric = int.tryParse(left);
  final rightNumeric = int.tryParse(right);
  if (leftNumeric != null && rightNumeric != null) {
    return leftNumeric.compareTo(rightNumeric);
  }
  if (leftNumeric != null || rightNumeric != null) {
    return leftNumeric != null ? -1 : 1;
  }
  return left.compareTo(right);
}

String _normalizeBaseUrl(String value) =>
    value.trim().replaceFirst(RegExp(r'/+$'), '');
