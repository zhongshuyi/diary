import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/data/local_model_store.dart';
import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/domain/local_assistant_message.dart';

class LocalAssistantSettingsPage extends StatefulWidget {
  const LocalAssistantSettingsPage({
    required this.controller,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    super.key,
  });

  final LocalAssistantController controller;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

  @override
  State<LocalAssistantSettingsPage> createState() =>
      _LocalAssistantSettingsPageState();
}

enum _ModelAction { download, import, select }

class _LocalAssistantSettingsPageState
    extends State<LocalAssistantSettingsPage> {
  bool _picking = false;
  bool _savingStyle = false;
  bool _libraryOpen = false;
  String? _modelError;
  _ModelAction? _retryAction;
  InstalledLocalModel? _retrySelection;
  LocalModelDescriptor? _retryDownload;
  late LocalAssistantTone _tone;
  late final TextEditingController _persona;
  late OnlineModelProvider _provider;
  late final TextEditingController _baseUrl;
  late final TextEditingController _onlineModel;
  late final TextEditingController _apiKey;
  final _onlineDrafts = <OnlineModelProvider, _OnlineDraft>{};
  bool _sendImages = false;
  bool _showApiKey = false;
  bool _savingOnline = false;
  String? _onlineError;
  String? _testStatus;
  bool? _testSucceeded;

  bool get _canChange =>
      widget.controller.initialized &&
      !widget.controller.busy &&
      !widget.controller.testingConnection &&
      !_picking &&
      !_savingStyle &&
      !_savingOnline;

  bool get _canManageLocal => _canChange && widget.controller.localSupported;

  bool get _canChangeSource =>
      widget.controller.initialized &&
      !widget.controller.installing &&
      !widget.controller.testingConnection &&
      !_picking &&
      !_savingStyle &&
      !_savingOnline;

  OnlineModelConfiguration get _draftConfiguration => OnlineModelConfiguration(
    provider: _provider,
    baseUrl: _baseUrl.text.trim(),
    model: _onlineModel.text.trim(),
    sendImages: _sendImages,
  );

  bool get _onlineDirty {
    final saved = widget.controller.configurationFor(_provider);
    return _provider != widget.controller.onlineProvider ||
        _baseUrl.text != saved.baseUrl ||
        _onlineModel.text != saved.model ||
        _sendImages != saved.sendImages ||
        _apiKey.text.isNotEmpty;
  }

  bool get _styleDirty =>
      _tone != widget.controller.tone ||
      _persona.text.trim() != widget.controller.persona;

  @override
  void initState() {
    super.initState();
    _tone = widget.controller.tone;
    _persona = TextEditingController(text: widget.controller.persona);
    _provider = widget.controller.onlineProvider;
    final configuration = widget.controller.configurationFor(_provider);
    _baseUrl = TextEditingController(text: configuration.baseUrl);
    _onlineModel = TextEditingController(text: configuration.model);
    _apiKey = TextEditingController();
    _sendImages = configuration.sendImages;
    _persona.addListener(_draftChanged);
    _baseUrl.addListener(_onlineDraftChanged);
    _onlineModel.addListener(_onlineDraftChanged);
    _apiKey.addListener(_onlineDraftChanged);
    if (!widget.controller.initialized) unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final controller = widget.controller;
    await controller.initialize();
    if (!mounted || !identical(controller, widget.controller)) return;
    setState(() {
      _tone = controller.tone;
      _persona.text = controller.persona;
      _resetOnlineDrafts();
    });
  }

  @override
  void didUpdateWidget(covariant LocalAssistantSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    _tone = widget.controller.tone;
    _persona.text = widget.controller.persona;
    _modelError = null;
    _retryAction = null;
    _retrySelection = null;
    _retryDownload = null;
    _resetOnlineDrafts();
    if (!widget.controller.initialized) unawaited(_initialize());
  }

  @override
  void dispose() {
    _persona.dispose();
    _baseUrl.dispose();
    _onlineModel.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _notice('操作未完成，请稍后重试。');
    }
  }

  Future<void> _setEnabled(bool value) async {
    if (value && !widget.controller.canUseSelectedModel) {
      if (widget.controller.source == AssistantReplySource.online) {
        _notice('先保存有效的 API 地址、模型 ID 和 API Key，再开启日记陪伴。');
        return;
      }
      _notice('先选择一个模型，再开启日记陪伴。');
      await _showModelLibrary();
      return;
    }
    await _run(() => widget.controller.enable(value));
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  void _onlineDraftChanged() {
    if (!mounted) return;
    setState(() {
      _onlineError = null;
      _testStatus = null;
      _testSucceeded = null;
    });
  }

  void _resetOnlineDrafts() {
    _onlineDrafts.clear();
    _provider = widget.controller.onlineProvider;
    _loadOnlineDraft(
      _OnlineDraft.fromConfiguration(
        widget.controller.configurationFor(_provider),
      ),
    );
  }

  void _loadOnlineDraft(_OnlineDraft draft) {
    _baseUrl.text = draft.baseUrl;
    _onlineModel.text = draft.model;
    _apiKey.text = draft.apiKey;
    _sendImages = draft.sendImages;
    _showApiKey = false;
    _onlineError = null;
    _testStatus = null;
    _testSucceeded = null;
  }

  void _selectProvider(OnlineModelProvider provider) {
    if (!_canChange || provider == _provider) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _onlineDrafts[_provider] = _OnlineDraft(
      baseUrl: _baseUrl.text,
      model: _onlineModel.text,
      apiKey: _apiKey.text,
      sendImages: _sendImages,
    );
    setState(() {
      _provider = provider;
      _loadOnlineDraft(
        _onlineDrafts[provider] ??
            _OnlineDraft.fromConfiguration(
              widget.controller.configurationFor(provider),
            ),
      );
    });
  }

  Future<void> _setSource(AssistantReplySource source) async {
    if (!_canChangeSource || widget.controller.source == source) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await _run(() => widget.controller.setReplySource(source));
  }

  bool _validateOnlineDraft() {
    try {
      _draftConfiguration.validate();
      final key = _apiKey.text.trim();
      if (key.isEmpty && !widget.controller.hasApiKeyFor(_provider)) {
        throw const FormatException('请填写 API Key');
      }
      if (key.length > 8192 || RegExp(r'\s|[\x00-\x1f\x7f]').hasMatch(key)) {
        throw const FormatException('请填写有效的 API Key');
      }
      return true;
    } on FormatException catch (error) {
      setState(() => _onlineError = error.message.toString());
      return false;
    }
  }

  Future<void> _saveOnline() async {
    if (!_canChange || !_validateOnlineDraft()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final configuration = _draftConfiguration;
    final key = _apiKey.text.trim();
    setState(() => _savingOnline = true);
    try {
      await widget.controller.saveOnlineConfiguration(
        configuration,
        apiKey: key.isEmpty ? null : key,
      );
      if (!mounted) return;
      if (widget.controller.error != null ||
          widget.controller.onlineProvider != configuration.provider ||
          !widget.controller.hasApiKeyFor(configuration.provider)) {
        setState(() => _onlineError = widget.controller.error ?? '配置未保存，请重试。');
        return;
      }
      setState(() {
        _apiKey.clear();
        _baseUrl.text = configuration.baseUrl;
        _onlineModel.text = configuration.model;
        _onlineDrafts.remove(_provider);
      });
      _notice('线上模型配置已保存');
    } catch (_) {
      if (mounted) {
        setState(() => _onlineError = '配置未保存，请检查设置后重试。');
      }
    } finally {
      if (mounted) setState(() => _savingOnline = false);
    }
  }

  Future<void> _testOnline() async {
    if (!_canChange || !_validateOnlineDraft()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final key = _apiKey.text.trim();
    try {
      final success = await widget.controller.testOnlineConnection(
        _draftConfiguration,
        apiKey: key.isEmpty ? null : key,
      );
      if (!mounted) return;
      setState(() {
        _testSucceeded = success;
        _testStatus =
            widget.controller.connectionStatus ??
            (success ? '连接成功' : '连接未成功，请检查配置后重试。');
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _testSucceeded = false;
          _testStatus = '连接未成功，请检查配置后重试。';
        });
      }
    }
  }

  Future<void> _removeApiKey() async {
    if (!_canChange || !widget.controller.hasApiKeyFor(_provider)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除保存的 API Key？'),
        content: Text('${_provider.label} 的线上回应需要重新填写密钥后才能使用。未保存的表单修改会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除密钥'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _savingOnline = true);
    try {
      await widget.controller.removeOnlineApiKey(_provider);
      if (!mounted) return;
      if (widget.controller.error != null ||
          widget.controller.hasApiKeyFor(_provider)) {
        setState(() => _onlineError = widget.controller.error ?? '密钥未删除，请重试。');
        return;
      }
      _notice('保存的 API Key 已删除');
    } catch (_) {
      if (mounted) setState(() => _onlineError = '密钥未删除，请重试。');
    } finally {
      if (mounted) setState(() => _savingOnline = false);
    }
  }

  Future<void> _saveStyle() async {
    if (!_canChange) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _savingStyle = true);
    final tone = _tone;
    final persona = _persona.text.trim();
    await _run(
      () => widget.controller.setReplyStyle(tone: tone, persona: persona),
    );
    if (!mounted) return;
    setState(() => _savingStyle = false);
    if (widget.controller.tone == tone &&
        widget.controller.persona == persona) {
      _notice('陪伴方式已保存');
    }
  }

  Future<void> _prepareModel(
    _ModelAction action, {
    InstalledLocalModel? selection,
    LocalModelDescriptor? download,
    String? importPath,
  }) async {
    if (!mounted || widget.controller.busy) return;
    final controller = widget.controller;
    final oldPath = controller.currentModel?.path;
    setState(() {
      _modelError = null;
      _retryAction = action;
      _retrySelection = selection;
      _retryDownload = download;
    });
    try {
      switch (action) {
        case _ModelAction.download:
          await controller.downloadRecommendedModel(download);
        case _ModelAction.import:
          await controller.importModel(importPath!);
        case _ModelAction.select:
          await controller.selectModel(selection!.path);
      }
      if (!mounted || !identical(controller, widget.controller)) return;
      setState(() {
        _modelError = controller.error;
        if (_modelError == null) _retryAction = null;
      });
      final model = controller.currentModel;
      if (!controller.busy &&
          controller.error == null &&
          model != null &&
          model.path != oldPath) {
        _notice(
          action == _ModelAction.select
              ? '已切换为 ${model.name}'
              : '模型已准备好，${controller.enabled ? '可以继续使用日记陪伴' : '可以开启日记陪伴了'}',
        );
      }
    } catch (_) {
      if (!mounted || !identical(controller, widget.controller)) return;
      setState(() => _modelError = '模型准备未完成，请重试。');
    }
  }

  Future<void> _retryModel() async {
    switch (_retryAction) {
      case _ModelAction.download:
        await _prepareModel(_ModelAction.download, download: _retryDownload);
      case _ModelAction.import:
        await _importModel();
      case _ModelAction.select:
        if (_retrySelection != null) {
          await _prepareModel(_ModelAction.select, selection: _retrySelection);
        } else {
          await _showModelLibrary();
        }
      case null:
        await _showModelLibrary();
    }
  }

  Future<void> _importModel() async {
    if (_picking || widget.controller.busy) return;
    var pickedFile = false;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _picking = true;
      _modelError = null;
    });
    try {
      FilePickerResult? result;
      widget.onExternalActivityStart?.call();
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['gguf'],
          allowMultiple: false,
          withData: false,
        );
        pickedFile = result != null;
      } finally {
        widget.onExternalActivityEnd?.call();
      }
      if (!mounted || result == null) return;
      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        setState(() {
          _modelError = '无法读取这个文件，请将模型保存到手机后重新选择。';
          _retryAction = _ModelAction.import;
        });
        return;
      }
      await _prepareModel(_ModelAction.import, importPath: path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelError = '无法打开模型文件，请重新选择。';
        _retryAction = _ModelAction.import;
      });
    } finally {
      if (pickedFile) {
        try {
          await FilePicker.clearTemporaryFiles();
        } catch (_) {
          // Cache cleanup must not turn a completed import into a failure.
        }
      }
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _cancelPreparation() async {
    await _run(widget.controller.stop);
    if (!mounted) return;
    setState(() {
      _modelError = null;
      _retryAction = null;
      _retrySelection = null;
      _retryDownload = null;
    });
  }

  Future<void> _removeModel(InstalledLocalModel model) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = widget.controller.currentModel?.path == model.path;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除这个模型？'),
        content: Text(
          '将移除「${model.name}」并释放存储空间。'
          '${selected && widget.controller.source == AssistantReplySource.local ? '日记陪伴将暂时关闭。' : ''}已经保存的回应会保留。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除模型'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => widget.controller.removeInstalledModel(model.path));
    }
  }

  Future<void> _clearReplies() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空本地回应？'),
        content: const Text('只移除这台设备保存的陪伴回应，你的日记不会受到影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空回应'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(widget.controller.clearConversation);
    }
  }

  Future<void> _showModelLibrary() async {
    if (!_canManageLocal || _libraryOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _libraryOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: DiaryThemeColors.of(context).surface,
        builder: (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .4,
          maxChildSize: .94,
          builder: (context, scrollController) => AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              final colors = DiaryThemeColors.of(context);
              final models = controller.installedModels;
              return ListView(
                key: const Key('assistant-model-library'),
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  Text('选择模型', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '选择后即可准备日记陪伴。模型保存在这台设备上。',
                    style: TextStyle(color: colors.mutedInk, height: 1.5),
                  ),
                  if (models.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('已在本机', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final model in models)
                      ListTile(
                        key: ValueKey('assistant-model-${model.path}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        leading: _ModelIcon(color: colors.sage),
                        title: Text(
                          model.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_modelSize(model.sizeBytes)}${model.isRecommended ? ' · 推荐' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.currentModel?.path == model.path)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.terracotta,
                                size: 21,
                              ),
                            PopupMenuButton<String>(
                              key: ValueKey(
                                'assistant-model-menu-${model.path}',
                              ),
                              tooltip: '管理 ${model.name}',
                              enabled: _canManageLocal,
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text('移除模型'),
                                ),
                              ],
                              onSelected: (_) => unawaited(_removeModel(model)),
                            ),
                          ],
                        ),
                        onTap: !_canManageLocal
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                if (controller.currentModel?.path !=
                                    model.path) {
                                  unawaited(
                                    _prepareModel(
                                      _ModelAction.select,
                                      selection: model,
                                    ),
                                  );
                                }
                              },
                      ),
                  ],
                  const SizedBox(height: 22),
                  Text('可用模型', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final descriptor in controller.recommendedModels) ...[
                    _buildModelOption(sheetContext, descriptor, models),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: colors.line),
                  ListTile(
                    key: const Key('assistant-import-model'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    leading: _ModelIcon(
                      color: colors.butter,
                      icon: Icons.folder_open_rounded,
                    ),
                    title: const Text('从手机导入'),
                    subtitle: const Text('选择 GGUF 模型文件'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: !_canManageLocal
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            unawaited(_importModel());
                          },
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      _libraryOpen = false;
    }
  }

  Widget _buildModelOption(
    BuildContext sheetContext,
    LocalModelDescriptor descriptor,
    List<InstalledLocalModel> models,
  ) {
    final colors = DiaryThemeColors.of(sheetContext);
    InstalledLocalModel? installed;
    for (final model in models) {
      if (descriptor.matches(model)) {
        installed = model;
        break;
      }
    }
    final available = installed;
    final selected =
        available != null &&
        widget.controller.currentModel?.path == available.path;
    void choose() {
      Navigator.pop(sheetContext);
      if (available != null) {
        if (!selected) {
          unawaited(_prepareModel(_ModelAction.select, selection: available));
        }
      } else {
        unawaited(_prepareModel(_ModelAction.download, download: descriptor));
      }
    }

    return _SettingsCard(
      child: InkWell(
        key: ValueKey('assistant-model-option-${descriptor.id}'),
        onTap: _canManageLocal ? choose : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModelIcon(
                    color: descriptor.isRecommended
                        ? colors.terracottaSoft
                        : colors.sage,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descriptor.name,
                          style: Theme.of(sheetContext).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_modelSize(descriptor.sizeBytes)}${descriptor.isRecommended ? ' · 推荐' : ''}',
                          style: TextStyle(color: colors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                descriptor.description,
                style: TextStyle(color: colors.mutedInk, height: 1.5),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: available != null
                      ? ValueKey('assistant-use-model-${descriptor.id}')
                      : descriptor.isRecommended
                      ? const Key('assistant-download-model')
                      : ValueKey('assistant-download-model-${descriptor.id}'),
                  onPressed: _canManageLocal ? choose : null,
                  child: Text(
                    selected
                        ? '已选择'
                        : available != null
                        ? '使用'
                        : '下载',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(centerTitle: true, title: const Text('日记陪伴')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => ListView(
          key: const Key('assistant-settings-list'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildSelectionSummary(context),
            const SizedBox(height: 20),
            _buildSource(context),
            const SizedBox(height: 16),
            if (widget.controller.source == AssistantReplySource.local)
              _buildCurrentModel(context)
            else
              _buildOnlineConfiguration(context),
            const SizedBox(height: 16),
            _SettingsCard(
              child: SwitchListTile.adaptive(
                key: const Key('assistant-enabled'),
                title: const Text('启用日记陪伴'),
                subtitle: Text(
                  widget.controller.canUseSelectedModel
                      ? widget.controller.source == AssistantReplySource.online
                            ? '使用已保存的 ${widget.controller.onlineProvider.label} 配置回应'
                            : '记录后，用选中的模型简短回应'
                      : widget.controller.source == AssistantReplySource.online
                      ? '先保存线上模型配置和 API Key'
                      : '先准备模型，再开启陪伴',
                ),
                value:
                    widget.controller.enabled &&
                    widget.controller.canUseSelectedModel,
                onChanged: _canChange && widget.controller.supported
                    ? (value) => unawaited(_setEnabled(value))
                    : null,
              ),
            ),
            if (widget.controller.source == AssistantReplySource.local) ...[
              const SizedBox(height: 12),
              Text(
                '本地小模型的理解与表达较弱，容易误解、重复或答非所问，仅建议用于离线简单陪伴。优先回复质量时，建议选择线上模型。',
                key: const Key('assistant-local-quality-notice'),
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
            ],
            const SizedBox(height: 24),
            Text('你喜欢的陪伴方式', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _buildReplyStyle(context),
            const SizedBox(height: 16),
            Text(
              widget.controller.source == AssistantReplySource.local
                  ? '本地回应在设备上生成，不把日记文字发送给模型服务。回应保存在本机，不会加入日记正文、搜索或同步。'
                  : '线上回应需要联网，服务商可能收费。会发送当前日记文字、回复语气和人设；开启图片后还会发送当前日记的图片。回应保存在本机，不会加入日记正文、搜索或同步。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.6,
              ),
            ),
            if (widget.controller.source == AssistantReplySource.local) ...[
              const SizedBox(height: 10),
              Text(
                '下载需要联网。模型会占用存储和内存，回复速度取决于手机。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.mutedInk,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('assistant-clear-replies'),
                onPressed: _canChange ? () => unawaited(_clearReplies()) : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('清空本地回应'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final controller = widget.controller;
    final colors = DiaryThemeColors.of(context);
    final online = controller.source == AssistantReplySource.online;
    final sourceLabel = online ? '线上模型' : '本地模型';
    final modelLabel = online
        ? '${controller.onlineProvider.label} · ${controller.onlineConfiguration.model}'
        : controller.currentModel?.name ?? '尚未选择模型';
    final status = !controller.initialized
        ? '读取中'
        : !online && !controller.localSupported
        ? '设备不支持'
        : !controller.canUseSelectedModel
        ? '待配置'
        : controller.enabled
        ? '已启用'
        : '未启用';
    return _SettingsCard(
      child: Padding(
        key: const Key('assistant-current-selection'),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModelIcon(
              color: colors.terracottaSoft,
              icon: online ? Icons.cloud_outlined : Icons.phone_android_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.initialized ? '当前选择：$sourceLabel' : '正在读取设置…',
                    key: const Key('assistant-current-source'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.initialized ? '模型：$modelLabel' : '正在加载模型配置',
                    key: const Key('assistant-current-selection-model'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedInk, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(
                    text: status,
                    ready:
                        controller.initialized &&
                        controller.enabled &&
                        controller.canUseSelectedModel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSource(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('切换回应来源', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 340 ||
              (constraints.maxWidth < 420 &&
                  MediaQuery.textScalerOf(context).scale(14) > 19);
          final options = [
            for (final source in AssistantReplySource.values)
              _SourceOption(
                key: ValueKey('assistant-source-${source.name}'),
                label: source == AssistantReplySource.local ? '本地模型' : '线上模型',
                icon: source == AssistantReplySource.local
                    ? Icons.phone_android_rounded
                    : Icons.cloud_outlined,
                selected:
                    widget.controller.initialized &&
                    widget.controller.source == source,
                onTap: _canChangeSource
                    ? () => unawaited(_setSource(source))
                    : null,
              ),
          ];
          return stacked
              ? Column(
                  children: [
                    options.first,
                    const SizedBox(height: 8),
                    options.last,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: options.first),
                    const SizedBox(width: 10),
                    Expanded(child: options.last),
                  ],
                );
        },
      ),
    ],
  );

  Widget _buildOnlineConfiguration(BuildContext context) {
    final controller = widget.controller;
    final colors = DiaryThemeColors.of(context);
    final hasKey = controller.hasApiKeyFor(_provider);
    final dirty = _onlineDirty;
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('线上模型', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              controller.canUseSelectedModel
                  ? '已保存：${controller.onlineProvider.label} · ${controller.onlineConfiguration.model}'
                  : '尚未准备好，请保存配置和 API Key。',
              key: const Key('assistant-online-current'),
              style: TextStyle(color: colors.mutedInk, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('服务商', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final provider in OnlineModelProvider.values)
                  ChoiceChip(
                    key: ValueKey('assistant-provider-${provider.name}'),
                    label: Text(provider.label),
                    selected: _provider == provider,
                    onSelected: _canChange
                        ? (_) => _selectProvider(provider)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('assistant-online-base-url'),
              controller: _baseUrl,
              enabled: _canChange,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.example.com/v1',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '填写服务商提供的 HTTPS API 地址；兼容服务需支持 Chat Completions。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.5,
              ),
            ),
            if (_provider == OnlineModelProvider.miniMax) ...[
              const SizedBox(height: 8),
              Text(
                'MiniMax 密钥需与地区匹配。默认国内地址；国际平台可改为 https://api.minimax.io/v1。',
                key: const Key('assistant-minimax-region-notice'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.mutedInk,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('assistant-online-model'),
              controller: _onlineModel,
              enabled: _canChange,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: '模型 ID',
                hintText: _provider == OnlineModelProvider.deepSeek
                    ? 'deepseek-flash'
                    : '填写服务商提供的模型 ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('assistant-online-api-key'),
              controller: _apiKey,
              enabled: _canChange,
              obscureText: !_showApiKey,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hasKey ? '已保存；留空保留原密钥' : '填写 API Key',
                suffixIcon: IconButton(
                  key: const Key('assistant-online-key-visibility'),
                  tooltip: _showApiKey ? '隐藏输入的密钥' : '显示输入的密钥',
                  onPressed: _canChange
                      ? () => setState(() => _showApiKey = !_showApiKey)
                      : null,
                  icon: Icon(
                    _showApiKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasKey
                  ? '密钥已安全保存，不会显示在输入框中。留空保存可继续使用。'
                  : '密钥使用设备的安全存储，不进入日记、同步或导出。',
              key: const Key('assistant-online-key-status'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.5,
              ),
            ),
            if (hasKey)
              TextButton.icon(
                key: const Key('assistant-online-remove-key'),
                onPressed: _canChange ? () => unawaited(_removeApiKey()) : null,
                icon: const Icon(Icons.key_off_outlined),
                label: const Text('删除保存的密钥'),
              ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              key: const Key('assistant-online-send-images'),
              contentPadding: EdgeInsets.zero,
              title: const Text('发送当前日记的图片'),
              subtitle: const Text(
                '需要模型和服务商支持图片。默认关闭；开启后最多上传当前日记的 4 张压缩图片，不发送历史图片或音频。',
              ),
              value: _sendImages,
              onChanged: _canChange
                  ? (value) => setState(() {
                      _sendImages = value;
                      _testStatus = null;
                      _testSucceeded = null;
                    })
                  : null,
            ),
            const SizedBox(height: 12),
            if (dirty)
              Text(
                '有未保存的修改。保存后才会用于回应；切换回应来源不会保存这些修改。',
                key: const Key('assistant-online-unsaved'),
                style: TextStyle(color: colors.ink, height: 1.5),
              )
            else
              Text(
                hasKey ? '当前配置已保存。' : '填写密钥后保存配置，便可开启线上陪伴。',
                style: TextStyle(color: colors.mutedInk, height: 1.5),
              ),
            if ((_onlineError ?? controller.error) != null) ...[
              const SizedBox(height: 10),
              Text(
                (_onlineError ?? controller.error)!,
                key: const Key('assistant-online-error'),
                style: TextStyle(color: colors.ink, height: 1.5),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const Key('assistant-online-save'),
                  onPressed: _canChange ? () => unawaited(_saveOnline()) : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_savingOnline ? '正在保存…' : '保存线上配置'),
                ),
                OutlinedButton.icon(
                  key: const Key('assistant-online-test'),
                  onPressed: _canChange ? () => unawaited(_testOnline()) : null,
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: Text(
                    controller.testingConnection ? '正在测试…' : '测试当前填写的配置',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '连接测试只发送公开样例文字，不发送你的日记或图片，也不会保存表单修改。服务商可能对测试请求计费。',
              key: const Key('assistant-online-test-notice'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.5,
              ),
            ),
            if (controller.testingConnection) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_testStatus != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _testSucceeded == true
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testStatus!,
                      key: const Key('assistant-online-test-status'),
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModel(BuildContext context) {
    final controller = widget.controller;
    final colors = DiaryThemeColors.of(context);
    final model = controller.currentModel;
    final preparing =
        controller.installing ||
        (controller.busy && controller.installProgress != null);
    final failure = _modelError ?? controller.error;
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '当前模型',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (controller.initialized)
                  _StatusBadge(
                    text: preparing
                        ? '准备中'
                        : model == null
                        ? '未选择'
                        : '已选择',
                    ready: !preparing && model != null,
                  ),
                if (model != null && !preparing)
                  PopupMenuButton<String>(
                    key: const Key('assistant-current-model-menu'),
                    tooltip: '管理当前模型',
                    enabled: _canManageLocal,
                    padding: EdgeInsets.zero,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'library', child: Text('管理已下载模型')),
                      PopupMenuItem(value: 'remove', child: Text('移除当前模型')),
                    ],
                    onSelected: (action) => unawaited(
                      action == 'remove'
                          ? _removeModel(model)
                          : _showModelLibrary(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (!controller.initialized)
              const LinearProgressIndicator()
            else if (preparing)
              _ModelPreparation(
                name: controller.installingModelName ?? '本地模型',
                progress: controller.installProgress,
                onCancel: () => unawaited(_cancelPreparation()),
              )
            else ...[
              Text(
                model?.name ?? '先选一个陪伴模型',
                key: const Key('assistant-model-status'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 7),
              Text(
                model == null
                    ? '下载推荐模型，或导入手机中的模型。'
                    : '${_modelSize(model.sizeBytes)} · 保存在这台设备上',
                style: TextStyle(color: colors.mutedInk, height: 1.5),
              ),
              if (!controller.localSupported) ...[
                const SizedBox(height: 12),
                Text(
                  '目前需要 Android 10 或更高版本的 64 位手机。当前设备暂时无法运行模型。',
                  style: TextStyle(color: colors.mutedInk, height: 1.5),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('assistant-change-model'),
                  onPressed: _canManageLocal
                      ? () => unawaited(_showModelLibrary())
                      : null,
                  icon: const Icon(Icons.unfold_more_rounded),
                  label: Text(
                    _picking
                        ? '正在选择文件…'
                        : model == null
                        ? '选择模型'
                        : '更换模型',
                  ),
                ),
              ),
            ],
            if (failure != null && !preparing) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('assistant-model-error'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.terracottaSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failure,
                      style: TextStyle(color: colors.ink, height: 1.5),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      key: const Key('assistant-retry-model'),
                      onPressed: _canManageLocal
                          ? () => unawaited(_retryModel())
                          : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _retryAction == _ModelAction.import
                            ? '重新选择文件'
                            : _retryAction == null
                            ? '检查模型'
                            : '重试',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyStyle(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('回复语气', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tone in LocalAssistantTone.values)
                  ChoiceChip(
                    key: ValueKey('assistant-tone-${tone.name}'),
                    label: Text(tone.label),
                    selected: _tone == tone,
                    onSelected: _canChange
                        ? (_) => setState(() => _tone = tone)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('assistant-persona'),
              controller: _persona,
              enabled: _canChange,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: '陪伴人设',
                hintText: '像一位细心的朋友，先理解我的情绪，再给一句温柔的回应。',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '描述你喜欢的说话方式。每次只针对刚写下的日记简短回应，不追问。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedInk,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            if (_styleDirty) ...[
              Text(
                '陪伴方式有未保存的修改。',
                key: const Key('assistant-style-unsaved'),
                style: TextStyle(color: colors.mutedInk, height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.tonal(
              key: const Key('assistant-save-style'),
              onPressed: _canChange ? () => unawaited(_saveStyle()) : null,
              child: Text(_savingStyle ? '正在保存…' : '保存陪伴方式'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineDraft {
  const _OnlineDraft({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.sendImages,
  });

  factory _OnlineDraft.fromConfiguration(
    OnlineModelConfiguration configuration,
  ) => _OnlineDraft(
    baseUrl: configuration.baseUrl,
    model: configuration.model,
    apiKey: '',
    sendImages: configuration.sendImages,
  );

  final String baseUrl;
  final String model;
  final String apiKey;
  final bool sendImages;
}

class _ModelPreparation extends StatelessWidget {
  const _ModelPreparation({
    required this.name,
    required this.progress,
    required this.onCancel,
  });
  final String name;
  final LocalModelInstallProgress? progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final stage = progress?.stage ?? LocalModelInstallStage.connecting;
    final transferring =
        stage == LocalModelInstallStage.downloading ||
        stage == LocalModelInstallStage.importing;
    final fraction = transferring ? progress?.fraction : null;
    final received = progress?.receivedBytes ?? 0;
    final total = progress?.totalBytes;
    final status = switch (stage) {
      LocalModelInstallStage.connecting => '正在连接下载地址…',
      LocalModelInstallStage.downloading => '正在下载模型',
      LocalModelInstallStage.importing => '正在导入模型',
      LocalModelInstallStage.verifying => '正在检查模型文件…',
      LocalModelInstallStage.activating => '正在确认模型可用…',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          key: const Key('assistant-installing-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          status,
          key: const Key('assistant-install-stage'),
          style: TextStyle(color: colors.mutedInk),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            key: const Key('assistant-install-progress'),
            value: fraction,
            minHeight: 6,
            color: colors.terracotta,
            backgroundColor: colors.line,
          ),
        ),
        if (transferring) ...[
          const SizedBox(height: 9),
          Text(
            '${fraction == null ? '' : '${(fraction * 100).floor()}% · '}${_formatBytes(received)}${total != null && total > 0 ? ' / ${_formatBytes(total)}' : ' · 大小暂未提供'}',
            key: const Key('assistant-transfer-progress'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.mutedInk,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('assistant-cancel-install'),
            onPressed: onCancel,
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}

String _formatBytes(int bytes) => '${(bytes / 1000000).toStringAsFixed(1)} MB';
String _modelSize(int bytes) => bytes >= 1000000000
    ? '${(bytes / 1000000000).toStringAsFixed(2)} GB'
    : bytes > 0
    ? _formatBytes(bytes)
    : '大小待确认';

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Material(
        color: selected ? colors.terracottaSoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.terracotta : colors.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colors.terracotta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? colors.terracotta : colors.mutedInk,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelIcon extends StatelessWidget {
  const _ModelIcon({required this.color, this.icon = Icons.memory_rounded});
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 22, color: DiaryThemeColors.of(context).ink),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.ready});
  final String text;
  final bool ready;
  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ready ? colors.sage : colors.paper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.ink),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
