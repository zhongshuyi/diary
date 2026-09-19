import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/diary_draft_store.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/quick_audio_recorder.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/desktop_window_bar.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/hold_to_record_button.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';
import 'package:diary/widgets/local_media_preview.dart';
import 'package:diary/widgets/media_kind.dart';
import 'package:diary/widgets/selected_photo_strip.dart';

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    required this.categories,
    required this.onSave,
    this.defaultEditorType = DiaryEditorType.plainText,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.onImportPhotos,
    this.audioRecorder,
    this.pickGalleryPhotos,
    this.entry,
    this.initialContent = '',
    this.initialImagePaths = const [],
    this.restoreInitialDraft = false,
    this.desktopLayout = false,
    this.showDesktopWindowBar = true,
    this.onToggleTheme,
    this.onDesktopBack,
    this.draftId,
    this.onLoadDraft,
    this.onSaveDraft,
    this.onClearDraft,
    this.draftStore,
    this.draftKey,
    super.key,
  });

  final DiaryEntry? entry;
  final String initialContent;
  final List<String> initialImagePaths;
  final bool restoreInitialDraft;
  final List<String> categories;
  final Future<void> Function(DiaryEntry entry) onSave;
  final DiaryEditorType defaultEditorType;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<List<String>> Function(List<String> paths)? onImportPhotos;
  final QuickAudioRecorder? audioRecorder;
  final Future<List<String>> Function()? pickGalleryPhotos;
  final bool desktopLayout;
  final bool showDesktopWindowBar;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onDesktopBack;
  final String? draftId;
  final Future<DraftPayload?> Function(String id)? onLoadDraft;
  final Future<void> Function(DraftPayload draft)? onSaveDraft;
  final Future<void> Function(String id)? onClearDraft;
  final DiaryDraftStore? draftStore;
  final String? draftKey;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final quill.QuillController _quillController;
  late DiaryEditorType _editorType;
  late String _category;
  late String _selectedMood;
  List<String> _attachments = const [];
  bool _saving = false;
  bool _pickingAttachment = false;
  bool _recordingActive = false;
  Timer? _draftTimer;
  bool _restoringDraft = false;

  static const _moods = ['阴天', '低落', '平常', '平静', '明亮'];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _editorType = entry?.editorType ?? widget.defaultEditorType;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(
      text: entry?.contentText ?? widget.initialContent,
    );
    _tagsController = TextEditingController(text: entry?.tags.join(', ') ?? '');
    _category =
        entry?.category ??
        (widget.categories.isEmpty ? '生活' : widget.categories.first);
    _selectedMood = diaryMoodLabel(entry?.mood ?? .5);
    _attachments = [
      ...(entry?.imagePaths ?? widget.initialImagePaths),
      ...?entry?.audioPaths,
      ...?entry?.videoPaths,
    ];
    _quillController = quill.QuillController.basic();
    if (entry != null && entry.editorType == DiaryEditorType.richText) {
      try {
        _quillController.document = quill.Document.fromJson(
          jsonDecode(entry.content) as List,
        );
      } catch (_) {
        _quillController.document.insert(0, entry.contentText);
      }
    } else if (entry == null &&
        _editorType == DiaryEditorType.richText &&
        widget.initialContent.isNotEmpty) {
      _quillController.document.insert(0, widget.initialContent);
    }
    _titleController.addListener(_scheduleDraftSave);
    _contentController.addListener(_scheduleDraftSave);
    _tagsController.addListener(_scheduleDraftSave);
    _quillController.addListener(_scheduleDraftSave);
    final shouldRestoreDraft =
        entry == null &&
        (widget.restoreInitialDraft ||
            (widget.initialContent.isEmpty &&
                widget.initialImagePaths.isEmpty));
    if (shouldRestoreDraft &&
        widget.draftId != null &&
        widget.onLoadDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    } else if (shouldRestoreDraft &&
        widget.draftStore != null &&
        widget.draftKey != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restoreLegacyDraft(),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _quillController.dispose();
    _draftTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    if (!mounted || widget.draftId == null || widget.onLoadDraft == null)
      return;
    final draft = await widget.onLoadDraft!(widget.draftId!);
    if (!mounted || draft == null) return;
    final payload = draft.payload;
    _restoringDraft = true;
    _titleController.text = '${payload['title'] ?? ''}';
    final editorType = '${payload['editorType'] ?? ''}';
    if (editorType == DiaryEditorType.richText.name) {
      _editorType = DiaryEditorType.richText;
    } else if (editorType == DiaryEditorType.plainText.name) {
      _editorType = DiaryEditorType.plainText;
    }
    final content = '${payload['content'] ?? ''}';
    if (_editorType == DiaryEditorType.richText) {
      try {
        _quillController.document = quill.Document.fromJson(
          jsonDecode(content) as List,
        );
      } catch (_) {
        _quillController.document = quill.Document()..insert(0, content);
      }
      _contentController.text = _quillController.document
          .toPlainText()
          .trimRight();
    } else {
      _contentController.text = content;
    }
    _tagsController.text = '${payload['tags'] ?? ''}';
    final category = '${payload['category'] ?? ''}';
    if (category.isNotEmpty && widget.categories.contains(category))
      _category = category;
    final mood = '${payload['mood'] ?? ''}';
    if (_moods.contains(mood)) _selectedMood = mood;
    final attachments = payload['attachments'] ?? payload['imagePaths'];
    if (attachments is List) {
      _attachments = attachments.whereType<String>().toList(growable: false);
    }
    _restoringDraft = false;
    if (mounted) setState(() {});
  }

  Future<void> _restoreLegacyDraft() async {
    final store = widget.draftStore;
    final key = widget.draftKey;
    if (!mounted || store == null || key == null) return;
    final draft = await store.load(key);
    if (!mounted || !_hasDraftContent(draft)) return;
    final restore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('发现未完成草稿'),
        content: const Text('要恢复上次未完成的内容吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('丢弃草稿'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复草稿'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (restore == true) {
      _applyLegacyDraft(draft!);
    } else if (restore == false) {
      await store.clear(key);
    }
  }

  void _applyLegacyDraft(Map<String, dynamic> draft) {
    _restoringDraft = true;
    try {
      _titleController.text = _stringValue(draft['title']);
      _editorType = DiaryEditorTypeCodec.fromWireValue(
        _stringValue(draft['editorType']),
      );
      final category = _stringValue(draft['category']);
      if (category.isNotEmpty && widget.categories.contains(category)) {
        _category = category;
      }
      final mood = _stringValue(draft['mood']);
      if (_moods.contains(mood)) _selectedMood = mood;
      _tagsController.text = _stringValue(draft['tagsText']);
      if (_tagsController.text.isEmpty && draft['tags'] is List) {
        _tagsController.text = (draft['tags'] as List).whereType<String>().join(
          ', ',
        );
      }
      _attachments = draft['attachments'] is List
          ? (draft['attachments'] as List).whereType<String>().toList()
          : const [];
      final content = _stringValue(draft['content']);
      if (_editorType == DiaryEditorType.richText && content.isNotEmpty) {
        try {
          _quillController.document = quill.Document.fromJson(
            jsonDecode(content) as List,
          );
          _contentController.text = _quillController.document
              .toPlainText()
              .trimRight();
        } catch (_) {
          _contentController.text = _stringValue(draft['contentText']);
        }
      } else {
        _contentController.text = _stringValue(
          draft['contentText'],
          fallback: content,
        );
      }
    } finally {
      _restoringDraft = false;
    }
    if (mounted) setState(() {});
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    final modernDraftEnabled =
        widget.draftId != null && widget.onSaveDraft != null;
    final legacyDraftEnabled =
        widget.draftStore != null && widget.draftKey != null;
    if (!modernDraftEnabled && !legacyDraftEnabled) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(
      Duration(milliseconds: legacyDraftEnabled ? 500 : 700),
      () {
        final payload = <String, dynamic>{
          'title': _titleController.text,
          'content': _editorType == DiaryEditorType.richText
              ? jsonEncode(_quillController.document.toDelta().toJson())
              : _contentController.text,
          'contentText': _editorType == DiaryEditorType.richText
              ? _quillController.document.toPlainText().trim()
              : _contentController.text,
          'tags': _tagsController.text,
          'tagsText': _tagsController.text,
          'category': _category,
          'mood': _selectedMood,
          'editorType': legacyDraftEnabled
              ? _editorType.wireValue
              : _editorType.name,
          'attachments': _attachments,
        };
        if (legacyDraftEnabled) {
          unawaited(widget.draftStore!.save(widget.draftKey!, payload));
        }
        if (modernDraftEnabled) {
          unawaited(
            widget.onSaveDraft!(
              DraftPayload(
                id: widget.draftId!,
                entryId: widget.entry?.id,
                payload: payload,
                updatedAt: DateTime.now(),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          _save();
        },
        SingleActivator(LogicalKeyboardKey.escape): () {
          if (widget.onDesktopBack != null) {
            widget.onDesktopBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        appBar: widget.desktopLayout
            ? null
            : AppBar(
                backgroundColor: colors.paper,
                surfaceTintColor: Colors.transparent,
                title: Text(widget.entry == null ? '写下此刻' : '编辑日记'),
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                actions: [
                  IconButton(
                    onPressed: _saving || _pickingAttachment || _recordingActive
                        ? null
                        : _save,
                    tooltip: '保存（Ctrl + Enter）',
                    icon: const Icon(Icons.check),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '私密记录',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ),
        body: Column(
          children: [
            if (widget.desktopLayout && widget.showDesktopWindowBar)
              DesktopWindowBar(
                title: widget.entry == null ? '写下此刻' : '编辑日记',
                isDark: Theme.of(context).brightness == Brightness.dark,
                onToggleTheme: widget.onToggleTheme ?? () {},
                onBack: () => Navigator.pop(context),
                actions: [
                  IconButton(
                    onPressed: _saving || _pickingAttachment || _recordingActive
                        ? null
                        : _save,
                    tooltip: '保存（Ctrl + Enter）',
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            Expanded(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop =
                        widget.desktopLayout || constraints.maxWidth >= 1000;
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              desktop ? 34 : 20,
                              desktop ? 24 : 14,
                              desktop ? 34 : 20,
                              30,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: desktop ? 1180 : 760,
                                ),
                                child: desktop
                                    ? _desktopWorkspace(context)
                                    : _mobileWorkspace(context),
                              ),
                            ),
                          ),
                        ),
                        _saveBar(context, desktop: desktop),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileWorkspace(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entryDate(context),
        const SizedBox(height: 15),
        _titleField(context),
        const SizedBox(height: 19),
        _formatSection(context),
        const SizedBox(height: 15),
        _editorBody(context),
        const SizedBox(height: 25),
        _metadataFields(context),
      ],
    );
  }

  Widget _desktopWorkspace(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _entryDate(context),
              const SizedBox(height: 15),
              _titleField(context),
              const SizedBox(height: 22),
              _formatSection(context),
              const SizedBox(height: 15),
              _editorBody(context, desktop: true),
            ],
          ),
        ),
        const SizedBox(width: 26),
        SizedBox(
          width: 300,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: _metadataFields(context, desktop: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryDate(BuildContext context) {
    return Text(
      diaryDateLabel(widget.entry?.createdAt ?? DateTime.now()),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  Widget _titleField(BuildContext context) {
    return TextField(
      key: const Key('entry-title-field'),
      controller: _titleController,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32),
      decoration: const InputDecoration(hintText: '给这一页起个标题'),
    );
  }

  Widget _formatSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('编辑方式', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: DiaryEditorType.values.map(_editorChoice).toList(),
        ),
      ],
    );
  }

  Widget _metadataFields(BuildContext context, {bool desktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desktop) ...[
          Text('这篇日记', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '补充一点信息，之后会更容易找到它。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
        ],
        Text('分类', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map(_categoryChoice).toList(),
        ),
        const SizedBox(height: 22),
        Text('标签', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        TextField(
          key: const Key('entry-tags-field'),
          controller: _tagsController,
          decoration: const InputDecoration(hintText: '例如：读书, 灵感'),
        ),
        const SizedBox(height: 22),
        Text('附件', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        _attachmentControls(context),
        const SizedBox(height: 22),
        Text('今天的情绪', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: _moods.map(_moodChoice).toList()),
      ],
    );
  }

  Widget _attachmentControls(BuildContext context) {
    final photos = _attachments
        .where((path) => diaryMediaKindForPath(path) == DiaryMediaKind.image)
        .toList(growable: false);
    final otherFiles = _attachments
        .where((path) => diaryMediaKindForPath(path) != DiaryMediaKind.image)
        .toList(growable: false);
    final audioFiles = otherFiles
        .where((path) => diaryMediaKindForPath(path) == DiaryMediaKind.audio)
        .toList(growable: false);
    final nonAudioFiles = otherFiles
        .where((path) => diaryMediaKindForPath(path) != DiaryMediaKind.audio)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _pickingAttachment || _recordingActive
                  ? null
                  : _addAttachment,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('添加附件'),
            ),
            SizedBox(
              width: 180,
              child: HoldToRecordButton(
                buttonKey: const Key('entry-hold-record'),
                enabled: !_pickingAttachment && !_saving,
                onActivityChanged: _setRecordingActivity,
                onError: _showRecordingError,
                onRecorded: _addRecordedAudio,
                recorder: widget.audioRecorder,
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          SelectedPhotoStrip(
            paths: photos,
            keyPrefix: 'editor-photo',
            onRemove: (path) {
              setState(() => _attachments = [..._attachments]..remove(path));
              _scheduleDraftSave();
            },
          ),
          if (audioFiles.isNotEmpty) ...[
            if (photos.isNotEmpty) const SizedBox(height: 8),
            ...audioFiles.map(
              (path) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: DiaryAudioPlayer(
                  path: path,
                  label: '语音',
                  compact: true,
                  onRemove: () {
                    setState(
                      () => _attachments = [..._attachments]..remove(path),
                    );
                    _scheduleDraftSave();
                  },
                ),
              ),
            ),
          ],
          if (nonAudioFiles.isNotEmpty)
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: nonAudioFiles
                  .map(
                    (path) => InputChip(
                      label: Text(
                        _fileName(path),
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: const Icon(Icons.attach_file, size: 15),
                      onDeleted: () {
                        setState(
                          () => _attachments = [..._attachments]..remove(path),
                        );
                        _scheduleDraftSave();
                      },
                    ),
                  )
                  .toList(),
            ),
        ],
      ],
    );
  }

  Widget _saveBar(BuildContext context, {required bool desktop}) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        desktop ? 34 : 20,
        12,
        desktop ? 34 : 20,
        14,
      ),
      decoration: BoxDecoration(
        color: colors.onHero,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: desktop ? 1180 : 760),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  desktop ? 'Ctrl + Enter 保存 · Esc 返回' : '先保存在本机',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _saving || _pickingAttachment || _recordingActive
                    ? null
                    : _save,
                icon: _saving
                    ? SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onHero,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_saving ? '正在保存…' : '保存日记'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorChoice(DiaryEditorType type) {
    final colors = DiaryThemeColors.of(context);
    final selected = _editorType == type;
    return ChoiceChip(
      label: Text(type.label),
      selected: selected,
      onSelected: (_) => setState(() => _editorType = type),
      showCheckmark: false,
      selectedColor: colors.hero,
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? colors.hero : colors.line),
      labelStyle: TextStyle(
        color: selected ? colors.onHero : colors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _categoryChoice(String category) {
    final colors = DiaryThemeColors.of(context);
    final selected = _category == category;
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      onSelected: (_) => setState(() => _category = category),
      showCheckmark: false,
      selectedColor: colors.hero,
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? colors.hero : colors.line),
      labelStyle: TextStyle(
        color: selected ? colors.onHero : colors.ink,
        fontSize: 12,
      ),
    );
  }

  Widget _moodChoice(String mood) {
    final colors = DiaryThemeColors.of(context);
    final selected = _selectedMood == mood;
    return ChoiceChip(
      label: Text(mood),
      selected: selected,
      onSelected: (_) => setState(() => _selectedMood = mood),
      showCheckmark: false,
      selectedColor: colors.hero,
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? colors.hero : colors.line),
      labelStyle: TextStyle(
        color: selected ? colors.onHero : colors.ink,
        fontSize: 12,
      ),
    );
  }

  Widget _editorBody(BuildContext context, {bool desktop = false}) {
    final colors = DiaryThemeColors.of(context);
    switch (_editorType) {
      case DiaryEditorType.richText:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            children: [
              quill.QuillSimpleToolbar(
                controller: _quillController,
                config: quill.QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showFontFamily: false,
                  showFontSize: false,
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: desktop ? 500 : 240,
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  config: quill.QuillEditorConfig(
                    scrollable: true,
                    padding: const EdgeInsets.fromLTRB(8, 15, 8, 15),
                    placeholder: '从一个词开始……',
                    embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
                  ),
                ),
              ),
            ],
          ),
        );
      case DiaryEditorType.markdown:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('entry-content-field'),
              controller: _contentController,
              minLines: desktop ? 18 : 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: '# 今天\n\n写下你的 Markdown 日记……',
              ),
            ),
            const SizedBox(height: 15),
            Text('预览', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _contentController,
              builder: (context, value, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: value.text.isEmpty ? '预览会出现在这里。' : value.text,
                  ),
                ),
              ),
            ),
          ],
        );
      case DiaryEditorType.plainText:
        return TextField(
          key: const Key('entry-content-field'),
          controller: _contentController,
          minLines: desktop ? 18 : 12,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: '此刻的你，正在想什么？\n\n不必完整，也不必漂亮。',
          ),
        );
    }
  }

  Future<void> _addAttachment() async {
    if (_pickingAttachment || _saving || _recordingActive) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.desktopLayout)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('从相册选择图片'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('选择文件'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    setState(() => _pickingAttachment = true);
    if (choice == 'image' || choice == 'camera') {
      final externalPicker = choice == 'camera' || widget.desktopLayout;
      if (externalPicker) widget.onExternalActivityStart?.call();
      try {
        final picker = ImagePicker();
        final List<String> pickedPaths;
        if (choice == 'camera') {
          final photo = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 92,
          );
          pickedPaths = photo == null ? [] : [photo.path];
        } else if (widget.desktopLayout) {
          pickedPaths = (await picker.pickMultiImage(
            imageQuality: 92,
          )).map((image) => image.path).toList(growable: false);
        } else {
          pickedPaths = await _pickGalleryPhotos();
        }
        if (pickedPaths.isNotEmpty) {
          final imported =
              await widget.onImportPhotos?.call(pickedPaths) ?? pickedPaths;
          if (mounted) {
            setState(() => _attachments = [..._attachments, ...imported]);
            _scheduleDraftSave();
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('照片没有添加成功，请重试')));
        }
      } finally {
        if (externalPicker) widget.onExternalActivityEnd?.call();
        if (mounted) setState(() => _pickingAttachment = false);
      }
      return;
    }
    widget.onExternalActivityStart?.call();
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null && mounted) {
        setState(
          () => _attachments = [
            ..._attachments,
            ...result.files.map((file) => file.path).whereType<String>(),
          ],
        );
        _scheduleDraftSave();
      }
    } finally {
      widget.onExternalActivityEnd?.call();
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  Future<List<String>> _pickGalleryPhotos() =>
      widget.pickGalleryPhotos?.call() ?? pickDiaryPhotos(context);

  Future<void> _addRecordedAudio(String path) async {
    if (!mounted) return;
    setState(() {
      if (!_attachments.contains(path)) _attachments = [..._attachments, path];
    });
    _scheduleDraftSave();
  }

  void _setRecordingActivity(bool active) {
    if (!mounted || _recordingActive == active) return;
    setState(() => _recordingActive = active);
  }

  void _showRecordingError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving || _pickingAttachment || _recordingActive) return;
    final title = _titleController.text.trim();
    final plainText = _editorType == DiaryEditorType.richText
        ? _quillController.document.toPlainText().trim()
        : _contentController.text.trim();
    if (title.isEmpty && plainText.isEmpty && _attachments.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先写下一点什么吧')));
      return;
    }
    _draftTimer?.cancel();
    setState(() => _saving = true);
    final now = DateTime.now();
    final saved = DiaryEntry(
      id: widget.entry?.id ?? now.microsecondsSinceEpoch.toString(),
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
      title: title.isEmpty
          ? (_attachments.isEmpty
                ? '无题'
                : _attachments.any(
                    (path) =>
                        diaryMediaKindForPath(path) == DiaryMediaKind.audio,
                  )
                ? '此刻的录音'
                : '此刻的照片')
          : title,
      content: _editorType == DiaryEditorType.richText
          ? jsonEncode(_quillController.document.toDelta().toJson())
          : plainText,
      contentText: plainText,
      editorType: _editorType,
      mood: _moodValue(_selectedMood),
      category: _category,
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(growable: false),
      imagePaths: _attachments
          .where(
            (path) =>
                diaryMediaKindForPath(path) == DiaryMediaKind.image ||
                diaryMediaKindForPath(path) == DiaryMediaKind.file,
          )
          .toList(growable: false),
      audioPaths: _attachments
          .where((path) => diaryMediaKindForPath(path) == DiaryMediaKind.audio)
          .toList(growable: false),
      videoPaths: _attachments
          .where((path) => diaryMediaKindForPath(path) == DiaryMediaKind.video)
          .toList(growable: false),
      isFavorite: widget.entry?.isFavorite ?? false,
    );
    try {
      await widget.onSave(saved);
      if (widget.draftId != null) {
        await widget.onClearDraft?.call(widget.draftId!);
      }
      if (widget.draftStore != null && widget.draftKey != null) {
        await widget.draftStore!.clear(widget.draftKey!);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后再试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

double _moodValue(String mood) {
  const values = {'阴天': .1, '低落': .3, '平常': .5, '平静': .7, '明亮': .9};
  return values[mood] ?? .5;
}

String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

bool _hasDraftContent(Map<String, dynamic>? draft) {
  if (draft == null) return false;
  final text = [
    draft['title'],
    draft['content'],
    draft['contentText'],
  ].whereType<String>().any((value) => value.trim().isNotEmpty);
  final attachments = draft['attachments'];
  return text || (attachments is List && attachments.isNotEmpty);
}

String _stringValue(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;
