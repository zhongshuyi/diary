import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/local_assistant_message.dart';

/// Contains only assistant messages; the diary repository and sync never read it.
class LocalAssistantStore {
  LocalAssistantStore({this.rootDirectory});

  static const maxMessages = 100;
  static const _maxFileBytes = 8 * 1024 * 1024;
  final Directory? rootDirectory;
  Future<void> _writes = Future<void>.value();

  Future<Directory> _root() async =>
      rootDirectory ??
      Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
          'local-assistant',
        ),
      );

  Future<List<LocalAssistantMessage>> load() async {
    await _writes;
    final file = File(p.join((await _root()).path, 'conversation.json'));
    if (!await file.exists()) return const [];
    if (await file.length() > _maxFileBytes) {
      throw const FormatException('本地对话记录过大');
    }
    final value = jsonDecode(await file.readAsString());
    if (value is! Map || value['version'] != 1 || value['messages'] is! List) {
      throw const FormatException('本地对话记录格式不正确');
    }
    final raw = value['messages'] as List;
    final result = <LocalAssistantMessage>[];
    for (final item in raw.skip(
      raw.length > maxMessages ? raw.length - maxMessages : 0,
    )) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('本地对话记录格式不正确');
      }
      result.add(LocalAssistantMessage.fromJson(item));
    }
    final replies = result
        .where((message) => message.role == LocalAssistantRole.assistant)
        .toList(growable: false);
    // Migrate the prototype's conversations without retaining diary/user text.
    if (replies.length != result.length) await save(replies);
    return List.unmodifiable(replies);
  }

  /// Snapshot immediately, then serialize writes so an older completion cannot
  /// replace a newer conversation.
  Future<void> save(List<LocalAssistantMessage> messages) {
    final replies = messages
        .where((message) => message.role == LocalAssistantRole.assistant)
        .toList(growable: false);
    final retained = replies.length > maxMessages
        ? replies.sublist(replies.length - maxMessages)
        : replies;
    final contents = jsonEncode({
      'version': 1,
      'messages': retained.map((message) => message.toJson()).toList(),
    });
    final write = _writes.then((_) async {
      final root = await _root();
      await root.create(recursive: true);
      final destination = File(p.join(root.path, 'conversation.json'));
      final staging = File('${destination.path}.part');
      try {
        await staging.writeAsString(contents, flush: true);
        await staging.rename(destination.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}
