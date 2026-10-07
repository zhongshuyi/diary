import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/attachment.dart';
import '../domain/conflict.dart';
import '../domain/diary_entry.dart';
import 'sync_models.dart';

class _AssetUploadRequest extends http.BaseRequest {
  _AssetUploadRequest(Uri url, this._bytes, this._byteSize)
    : super('PUT', url) {
    contentLength = _byteSize;
  }

  final Stream<List<int>> _bytes;
  final int _byteSize;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_checkedBytes());
  }

  Stream<List<int>> _checkedBytes() async* {
    var received = 0;
    await for (final chunk in _bytes) {
      received += chunk.length;
      if (received > _byteSize) {
        throw const SyncFailure('asset_size_mismatch', '附件大小校验失败');
      }
      yield chunk;
    }
    if (received != _byteSize) {
      throw const SyncFailure('asset_size_mismatch', '附件大小校验失败');
    }
  }
}

class SyncClient {
  SyncClient({required String baseUrl, this.token = '', http.Client? client})
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  void close() => _client.close();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token.trim().isNotEmpty) 'Authorization': 'Bearer ${token.trim()}',
  };

  Future<SyncResponse> sync(SyncRequest request) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v2/sync'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    final payload = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncFailure(
        payload['error']?['code'] ?? 'http_error',
        payload['error']?['message'] ?? '同步服务不可用',
        statusCode: response.statusCode,
      );
    }
    final data = Map<String, dynamic>.from(payload['data'] as Map? ?? const {});
    final changes = (data['changes'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => DiaryEntry.fromJson(
            Map<String, dynamic>.from(item['entry'] as Map? ?? const {}),
          ),
        )
        .toList(growable: false);
    final conflicts = (data['conflicts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final conflictEntry = DiaryEntry.fromJson(
            Map<String, dynamic>.from(map['entry'] as Map? ?? const {}),
          );
          final serverEntry = DiaryEntry.fromJson(
            Map<String, dynamic>.from(map['serverEntry'] as Map? ?? const {}),
          );
          return Conflict(
            conflictId: '${map['conflictId'] ?? ''}',
            entryId: '${map['entryId'] ?? serverEntry.id}',
            entry: conflictEntry,
            serverEntry: serverEntry,
            sourceDeviceId: '${map['sourceDeviceId'] ?? ''}',
            sourceMutationId: '${map['mutationId'] ?? ''}',
            createdAt: DateTime.now(),
          );
        })
        .toList(growable: false);
    return SyncResponse(
      nextCursor: '${data['nextCursor'] ?? request.cursor}',
      changes: changes,
      conflicts: conflicts,
      acknowledgedMutationIds: (data['appliedMutationIds'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Future<bool> headAsset(String sha256) async {
    final response = await _client.head(
      Uri.parse('$baseUrl/api/v2/assets/$sha256'),
      headers: _headers,
    );
    if (response.statusCode == 404) return false;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncFailure(
        'asset_head_failed',
        '无法检查附件状态',
        statusCode: response.statusCode,
      );
    }
    return true;
  }

  Future<void> uploadAsset(
    Attachment attachment,
    Stream<List<int>> bytes,
  ) async {
    final request =
        _AssetUploadRequest(
            Uri.parse('$baseUrl/api/v2/assets/${attachment.sha256}'),
            bytes,
            attachment.byteSize,
          )
          ..headers.addAll({
            ..._headers,
            'Content-Type': attachment.mimeType,
            'X-Asset-Kind': attachment.kind.name,
            'Content-Length': '${attachment.byteSize}',
          });
    final response = await _client.send(request);
    await response.stream.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncFailure(
        'asset_upload_failed',
        '附件上传失败',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Uint8List> downloadAsset(String sha256) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v2/assets/$sha256'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncFailure(
        'asset_download_failed',
        '附件下载失败',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      return value is Map
          ? Map<String, dynamic>.from(value)
          : <String, dynamic>{};
    } catch (_) {
      throw const SyncFailure('invalid_response', '同步服务返回了无效数据');
    }
  }
}
