import '../domain/assistant_provider_settings.dart';
import '../domain/local_assistant_message.dart';
import 'local_llm_engine.dart';
import 'online_model_adapter.dart';

abstract interface class DiaryReplyStrategy {
  Future<void> prepare();
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  });
  Future<void> cancel();
  Future<void> unload();
  Future<void> dispose();
}

class LocalDiaryReplyStrategy implements DiaryReplyStrategy {
  LocalDiaryReplyStrategy({required this.engine, required this.modelPath});

  final LocalLlmEngine engine;
  final String modelPath;

  @override
  Future<void> prepare() => engine.load(modelPath);

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) => engine.generate(messages, tone: tone, persona: persona);

  @override
  Future<void> cancel() => engine.cancel();

  @override
  Future<void> unload() => engine.unload();

  // The controller owns the shared native engine and its final disposal.
  @override
  Future<void> dispose() => engine.unload();
}

class OnlineDiaryReplyStrategy implements DiaryReplyStrategy {
  OnlineDiaryReplyStrategy({
    required this.configuration,
    required this.apiKey,
    OnlineModelAdapter? adapter,
  }) : _adapter =
           adapter ??
           switch (configuration.provider) {
             OnlineModelProvider.deepSeek => DeepSeekAdapter(),
             OnlineModelProvider.miniMax => MiniMaxAdapter(),
             OnlineModelProvider.compatible => OpenAiCompatibleAdapter(),
           };

  final OnlineModelConfiguration configuration;
  final String apiKey;
  final OnlineModelAdapter _adapter;

  @override
  Future<void> prepare() async {
    configuration.validate();
    if (apiKey.trim().isEmpty || apiKey.contains(RegExp(r'[\r\n]'))) {
      throw const OnlineModelException('请先填写有效的 API Key。');
    }
  }

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) {
    if (messages.isEmpty || messages.last.role != LocalAssistantRole.user) {
      return Stream.error(const OnlineModelException('需要一条日记内容。'));
    }
    final diary = messages.last;
    return _adapter.generate(
      configuration: configuration,
      apiKey: apiKey,
      diary: diary.text,
      tone: tone,
      persona: persona,
      imagePaths: diary.imagePaths,
    );
  }

  @override
  Future<void> cancel() => _adapter.cancel();

  @override
  Future<void> unload() => _adapter.cancel();

  @override
  Future<void> dispose() => _adapter.dispose();
}
