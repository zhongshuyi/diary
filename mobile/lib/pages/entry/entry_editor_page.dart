import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/desktop_window_bar.dart';
import 'package:diary/widgets/local_media_preview.dart';

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    required this.categories,
    required this.onSave,
    this.defaultEditorType = DiaryEditorType.plainText,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.entry,
    this.desktopLayout = false,
    this.showDesktopWindowBar = true,
    this.onToggleTheme,
    this.onDesktopBack,
    super.key,
  });

  final DiaryEntry? entry;
  final List<String> categories;
  final Future<void> Function(DiaryEntry entry) onSave;
  final DiaryEditorType defaultEditorType;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final bool desktopLayout;
  final bool showDesktopWindowBar;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onDesktopBack;

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

  static const _moods = ['阴天', '低落', '平常', '平静', '明亮'];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _editorType = entry?.editorType ?? widget.defaultEditorType;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(text: entry?.contentText ?? '');
    _tagsController = TextEditingController(text: entry?.tags.join(', ') ?? '');
    _category =
        entry?.category ??
        (widget.categories.isEmpty ? '生活' : widget.categories.first);
    _selectedMood = diaryMoodLabel(entry?.mood ?? .5);
    _attachments = [
      ...?entry?.imagePaths,
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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _quillController.dispose();
    super.dispose();
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
                    onPressed: _saving ? null : _save,
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
                    onPressed: _saving ? null : _save,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _addAttachment,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('添加附件'),
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _attachments
                .map(
                  (path) => InputChip(
                    label: Text(
                      _fileName(path),
                      overflow: TextOverflow.ellipsis,
                    ),
                    avatar: const Icon(Icons.attach_file, size: 15),
                    onDeleted: () => setState(
                      () => _attachments = _attachments
                          .where((item) => item != path)
                          .toList(),
                    ),
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
                  desktop ? 'Ctrl + Enter 保存 · Esc 返回' : '内容只保存在你的设备上',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
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
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('选择图片'),
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
    if (!mounted || choice == null) return;
    if (choice == 'image') {
      widget.onExternalActivityStart?.call();
      try {
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 92,
        );
        if (image != null && mounted) {
          setState(() => _attachments = [..._attachments, image.path]);
        }
      } finally {
        widget.onExternalActivityEnd?.call();
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
      }
    } finally {
      widget.onExternalActivityEnd?.call();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final plainText = _editorType == DiaryEditorType.richText
        ? _quillController.document.toPlainText().trim()
        : _contentController.text.trim();
    if (title.isEmpty && plainText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先写下一点什么吧')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final saved = DiaryEntry(
      id: widget.entry?.id ?? now.microsecondsSinceEpoch.toString(),
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
      title: title.isEmpty ? '无题' : title,
      content: _editorType == DiaryEditorType.richText
          ? jsonEncode(_quillController.document.toDelta().toJson())
          : plainText,
      contentText: plainText.isEmpty ? '今天的这一页，留给一个念头。' : plainText,
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
