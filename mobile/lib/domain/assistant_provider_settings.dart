/// Diary replies can be generated on this device or by a chosen API provider.
enum AssistantReplySource { local, online }

enum OnlineModelProvider {
  deepSeek,
  miniMax,
  compatible;

  String get label => switch (this) {
    deepSeek => 'DeepSeek',
    miniMax => 'MiniMax',
    compatible => 'OpenAI 兼容 API',
  };

  String get defaultBaseUrl => switch (this) {
    deepSeek => 'https://api.deepseek.com',
    miniMax => 'https://api.minimaxi.com/v1',
    compatible => 'https://api.openai.com/v1',
  };

  String get defaultModel => switch (this) {
    deepSeek => 'deepseek-flash',
    miniMax => 'MiniMax-M3',
    compatible => '',
  };
}

/// Non-secret API settings. Credentials are deliberately stored separately.
class OnlineModelConfiguration {
  const OnlineModelConfiguration({
    required this.provider,
    required this.baseUrl,
    required this.model,
    this.sendImages = false,
  });

  final OnlineModelProvider provider;
  final String baseUrl;
  final String model;
  final bool sendImages;

  OnlineModelConfiguration copyWith({
    String? baseUrl,
    String? model,
    bool? sendImages,
  }) => OnlineModelConfiguration(
    provider: provider,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    sendImages: sendImages ?? this.sendImages,
  );

  /// The test-only exception never permits plain HTTP to a remote server.
  void validate({bool allowInsecureLoopback = false}) {
    if (baseUrl.length > 2048 ||
        baseUrl.trim() != baseUrl ||
        RegExp(r'\s|[\x00-\x1f\x7f]').hasMatch(baseUrl)) {
      throw const FormatException('API 地址格式不正确');
    }
    final Uri? uri;
    try {
      uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          uri.port <= 0 ||
          uri.port > 65535) {
        throw const FormatException('API 地址格式不正确');
      }
    } on FormatException {
      throw const FormatException('API 地址格式不正确，请勿包含密钥、查询参数或片段');
    }
    final loopback = const {
      'localhost',
      '127.0.0.1',
      '::1',
      '[::1]',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' &&
        !(allowInsecureLoopback && uri.scheme == 'http' && loopback)) {
      throw const FormatException('API 地址必须使用 HTTPS');
    }
    if (model.isEmpty ||
        model.length > 200 ||
        model.trim() != model ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(model)) {
      throw const FormatException('请填写有效的模型 ID');
    }
  }

  /// Call [validate] before sending a request. A full endpoint is also accepted.
  Uri get completionUri {
    final uri = Uri.parse(baseUrl);
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(
      path: path.endsWith('/chat/completions')
          ? path
          : '$path/chat/completions',
    );
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'model': model,
    'sendImages': sendImages,
  };

  factory OnlineModelConfiguration.fromJson(
    OnlineModelProvider provider,
    Map<String, dynamic> json,
  ) {
    final baseUrl = json['baseUrl'];
    final model = json['model'];
    final sendImages = json['sendImages'] ?? false;
    if (baseUrl is! String || model is! String || sendImages is! bool) {
      throw const FormatException('线上模型配置格式不正确');
    }
    final configuration = OnlineModelConfiguration(
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      sendImages: sendImages,
    );
    configuration.validate();
    return configuration;
  }
}

class AssistantProviderSettings {
  const AssistantProviderSettings({
    this.source = AssistantReplySource.local,
    this.provider = OnlineModelProvider.deepSeek,
    this.configurations = const {},
  });

  final AssistantReplySource source;
  final OnlineModelProvider provider;
  final Map<OnlineModelProvider, OnlineModelConfiguration> configurations;

  OnlineModelConfiguration configurationFor(OnlineModelProvider provider) =>
      configurations[provider] ??
      OnlineModelConfiguration(
        provider: provider,
        baseUrl: provider.defaultBaseUrl,
        model: provider.defaultModel,
      );

  AssistantProviderSettings copyWith({
    AssistantReplySource? source,
    OnlineModelProvider? provider,
    Map<OnlineModelProvider, OnlineModelConfiguration>? configurations,
  }) => AssistantProviderSettings(
    source: source ?? this.source,
    provider: provider ?? this.provider,
    configurations: Map.unmodifiable(configurations ?? this.configurations),
  );

  Map<String, dynamic> toJson() {
    for (final entry in configurations.entries) {
      if (entry.key != entry.value.provider) {
        throw const FormatException('线上模型服务商配置不一致');
      }
      entry.value.validate();
    }
    return {
      'version': 1,
      'source': source.name,
      'provider': provider.name,
      'configurations': {
        for (final entry in configurations.entries)
          entry.key.name: entry.value.toJson(),
      },
    };
  }

  factory AssistantProviderSettings.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('模型服务配置版本不受支持');
    }
    final source = _enumFromName(
      AssistantReplySource.values,
      json['source'],
      AssistantReplySource.local,
    );
    final provider = _enumFromName(
      OnlineModelProvider.values,
      json['provider'],
      OnlineModelProvider.deepSeek,
    );
    final rawConfigurations = json['configurations'] ?? const {};
    if (rawConfigurations is! Map ||
        rawConfigurations.length > OnlineModelProvider.values.length) {
      throw const FormatException('线上模型配置格式不正确');
    }
    final configurations = <OnlineModelProvider, OnlineModelConfiguration>{};
    for (final entry in rawConfigurations.entries) {
      final configuredProvider = _enumFromName(
        OnlineModelProvider.values,
        entry.key,
        null,
      );
      if (entry.value is! Map<String, dynamic>) {
        throw const FormatException('线上模型配置格式不正确');
      }
      configurations[configuredProvider] = OnlineModelConfiguration.fromJson(
        configuredProvider,
        entry.value as Map<String, dynamic>,
      );
    }
    return AssistantProviderSettings(
      source: source,
      provider: provider,
      configurations: Map.unmodifiable(configurations),
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, Object? name, T? fallback) {
  if (name == null && fallback != null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw const FormatException('模型服务配置格式不正确');
}
