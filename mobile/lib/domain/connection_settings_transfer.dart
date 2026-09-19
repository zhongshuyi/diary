import 'dart:convert';

class ConnectionSettingsTransfer {
  const ConnectionSettingsTransfer({
    required this.syncEndpoint,
    required this.syncToken,
    required this.updateEndpoint,
  });

  static const prefix = 'DIARY-CONNECTION:v1:';

  final String syncEndpoint;
  final String syncToken;
  final String updateEndpoint;

  String encode() {
    final payload = jsonEncode({
      'version': 1,
      'syncEndpoint': syncEndpoint,
      'syncToken': syncToken,
      'updateEndpoint': updateEndpoint,
    });
    return '$prefix${base64UrlEncode(utf8.encode(payload)).replaceAll('=', '')}';
  }

  static ConnectionSettingsTransfer decode(String value) {
    final source = value.trim();
    final payloadText = source.startsWith(prefix)
        ? _decodeBase64Payload(source.substring(prefix.length))
        : source;
    dynamic payload;
    try {
      payload = jsonDecode(payloadText);
    } on FormatException {
      throw const FormatException('连接配置不是有效的 JSON');
    }
    if (payload is! Map || payload['version'] != 1) {
      throw const FormatException('不支持的连接配置版本');
    }

    final syncEndpoint = _readString(payload, 'syncEndpoint');
    final syncToken = _readString(payload, 'syncToken');
    final updateEndpoint = _readString(payload, 'updateEndpoint');
    return ConnectionSettingsTransfer(
      syncEndpoint: _validateEndpoint(syncEndpoint, '同步服务地址'),
      syncToken: syncToken.trim(),
      updateEndpoint: _validateEndpoint(updateEndpoint, '公开更新地址'),
    );
  }
}

String _decodeBase64Payload(String encoded) {
  if (encoded.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(encoded)) {
    throw const FormatException('连接配置编码无效');
  }
  try {
    return utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
  } on FormatException {
    throw const FormatException('连接配置编码无效');
  }
}

String _readString(Map<dynamic, dynamic> payload, String key) {
  final value = payload[key];
  if (value is! String) throw FormatException('连接配置缺少 $key');
  return value;
}

String _validateEndpoint(String value, String label) {
  final endpoint = value.trim().replaceFirst(RegExp(r'/+$'), '');
  if (endpoint.isEmpty) return endpoint;
  final uri = Uri.tryParse(endpoint);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    throw FormatException('$label必须是完整的 http:// 或 https:// 地址');
  }
  return endpoint;
}
