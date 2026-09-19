import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import 'package:diary/app/app_theme.dart';

/// A read-only Quill renderer that is safe for imported and legacy entries.
class DiaryRichTextViewer extends StatefulWidget {
  const DiaryRichTextViewer({
    required this.content,
    required this.fallbackText,
    super.key,
  });

  final String content;
  final String fallbackText;

  @override
  State<DiaryRichTextViewer> createState() => _DiaryRichTextViewerState();
}

class _DiaryRichTextViewerState extends State<DiaryRichTextViewer> {
  quill.QuillController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.content);
  }

  @override
  void didUpdateWidget(covariant DiaryRichTextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller?.dispose();
      _controller = _createController(widget.content);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _FallbackContent(text: widget.fallbackText);
    }
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: quill.QuillEditor.basic(
        controller: controller,
        config: quill.QuillEditorConfig(
          padding: const EdgeInsets.all(20),
          minHeight: 120,
          scrollable: false,
          embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
        ),
      ),
    );
  }

  quill.QuillController? _createController(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      final operations = switch (decoded) {
        List<dynamic> value => value,
        Map<String, dynamic> value when value['ops'] is List =>
          value['ops'] as List<dynamic>,
        _ => null,
      };
      if (operations == null || operations.isEmpty) return null;
      return quill.QuillController(
        document: quill.Document.fromJson(operations),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } on Object {
      return null;
    }
  }
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '富文本内容已按纯文本安全显示',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.ink,
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
