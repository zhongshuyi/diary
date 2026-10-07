enum LocalAssistantRole { user, assistant }

const defaultLocalAssistantPersona =
    '一位自然、真诚、懂得分寸的日记伙伴，留意我记录的小事，按当下的感受给予简短回应，不强行安慰。';

enum LocalAssistantTone {
  gentle,
  cheerful,
  calm;

  String get label => switch (this) {
    gentle => '温柔安慰',
    cheerful => '轻松鼓励',
    calm => '平静倾听',
  };

  String get instruction => switch (this) {
    gentle => '温柔、自然，有烦恼时表达理解，开心时分享开心，不强行安慰。',
    cheerful => '轻松、有活力，可以有一点俏皮，但尊重低落，不强行乐观或夸奖。',
    calm => '平静、朴实、克制，留意具体细节，不擅自分析情绪或讲大道理。',
  };
}

/// A transient inference prompt or a private response linked to a diary entry.
class LocalAssistantMessage {
  const LocalAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.imagePaths = const [],
  });

  final String id;
  final LocalAssistantRole role;
  final String text;
  final DateTime createdAt;
  // Transient input only. Image paths are never saved with companion replies.
  final List<String> imagePaths;

  LocalAssistantMessage copyWith({String? text, List<String>? imagePaths}) =>
      LocalAssistantMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        createdAt: createdAt,
        imagePaths: imagePaths ?? this.imagePaths,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory LocalAssistantMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];
    final text = json['text'];
    final timestamp = json['createdAt'];
    if (id is! String ||
        id.isEmpty ||
        text is! String ||
        text.length > 16000 ||
        timestamp is! String ||
        (role != 'user' && role != 'assistant')) {
      throw const FormatException('本地对话记录格式不正确');
    }
    final createdAt = DateTime.tryParse(timestamp);
    if (createdAt == null) {
      throw const FormatException('本地对话记录时间不正确');
    }
    return LocalAssistantMessage(
      id: id,
      role: role == 'user'
          ? LocalAssistantRole.user
          : LocalAssistantRole.assistant,
      text: text,
      createdAt: createdAt,
    );
  }
}
