import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/local_media_preview.dart';

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    required this.categories,
    required this.onSave,
    this.defaultEditorType = DiaryEditorType.plainText,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.entry,
    super.key,
  });

  final DiaryEntry? entry;
  final List<String> categories;
  final Future<void> Function(DiaryEntry entry) onSave;
  final DiaryEditorType defaultEditorType;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

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
    _category = entry?.category ?? widget.categories.first;
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
    return Scaffold(
      backgroundColor: DiaryPalette.paper,
      appBar: AppBar(
        backgroundColor: DiaryPalette.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.entry == null ? '写下此刻' : '编辑日记'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diaryDateLabel(
                            widget.entry?.createdAt ?? DateTime.now(),
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          key: const Key('entry-title-field'),
                          controller: _titleController,
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 32),
                          decoration: const InputDecoration(
                            hintText: '给这一页起个标题',
                          ),
                        ),
                        const SizedBox(height: 19),
                        Text(
                          '编辑方式',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: DiaryEditorType.values
                              .map(_editorChoice)
                              .toList(),
                        ),
                        const SizedBox(height: 15),
                        _editorBody(context),
                        const SizedBox(height: 25),
                        Text(
                          '分类',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.categories
                              .map(_categoryChoice)
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '标签',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          key: const Key('entry-tags-field'),
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            hintText: '用逗号分隔，例如：读书, 灵感',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '附件',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: _addAttachment,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 18,
                          ),
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
                                    avatar: const Icon(
                                      Icons.attach_file,
                                      size: 15,
                                    ),
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
                        const SizedBox(height: 22),
                        Text(
                          '今天的情绪',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _moods.map(_moodChoice).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: DiaryPalette.surface,
                border: Border(top: BorderSide(color: DiaryPalette.line)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DiaryPalette.surface,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_saving ? '正在保存…' : '保存日记'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editorChoice(DiaryEditorType type) {
    final selected = _editorType == type;
    return ChoiceChip(
      label: Text(type.label),
      selected: selected,
      onSelected: (_) => setState(() => _editorType = type),
      showCheckmark: false,
      selectedColor: DiaryPalette.ink,
      backgroundColor: DiaryPalette.surface,
      side: BorderSide(color: selected ? DiaryPalette.ink : DiaryPalette.line),
      labelStyle: TextStyle(
        color: selected ? DiaryPalette.surface : DiaryPalette.ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _categoryChoice(String category) {
    final selected = _category == category;
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      onSelected: (_) => setState(() => _category = category),
      showCheckmark: false,
      selectedColor: DiaryPalette.ink,
      backgroundColor: DiaryPalette.surface,
      side: BorderSide(color: selected ? DiaryPalette.ink : DiaryPalette.line),
      labelStyle: TextStyle(
        color: selected ? DiaryPalette.surface : DiaryPalette.ink,
        fontSize: 12,
      ),
    );
  }

  Widget _moodChoice(String mood) {
    final selected = _selectedMood == mood;
    return ChoiceChip(
      label: Text(mood),
      selected: selected,
      onSelected: (_) => setState(() => _selectedMood = mood),
      showCheckmark: false,
      selectedColor: DiaryPalette.ink,
      backgroundColor: DiaryPalette.surface,
      side: BorderSide(color: selected ? DiaryPalette.ink : DiaryPalette.line),
      labelStyle: TextStyle(
        color: selected ? DiaryPalette.surface : DiaryPalette.ink,
        fontSize: 12,
      ),
    );
  }

  Widget _editorBody(BuildContext context) {
    switch (_editorType) {
      case DiaryEditorType.richText:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DiaryPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DiaryPalette.line),
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
                height: 240,
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
              minLines: 10,
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
          minLines: 12,
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
    await widget.onSave(saved);
    if (mounted) Navigator.pop(context);
  }
}

double _moodValue(String mood) {
  const values = {'阴天': .1, '低落': .3, '平常': .5, '平静': .7, '明亮': .9};
  return values[mood] ?? .5;
}

String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
