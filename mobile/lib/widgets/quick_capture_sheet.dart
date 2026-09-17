import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

Future<void> showQuickCaptureSheet(
  BuildContext context, {
  required Future<void> Function(String) onSubmit,
  String initialText = '',
  ValueChanged<String>? onDraftChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _QuickCaptureSheet(
      initialText: initialText,
      onSubmit: onSubmit,
      onDraftChanged: onDraftChanged,
    ),
  );
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet({
    required this.initialText,
    required this.onSubmit,
    this.onDraftChanged,
  });

  final String initialText;
  final Future<void> Function(String) onSubmit;
  final ValueChanged<String>? onDraftChanged;

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.bolt_outlined, color: colors.terracotta),
                    const SizedBox(width: 8),
                    Text('快速记录', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text(
                      '先留下，再慢慢整理',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('quick-capture-sheet-field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (value) {
                    widget.onDraftChanged?.call(value);
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: const InputDecoration(hintText: '此刻想到什么？先写下来……'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.terracotta),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '内容会先保存到本机',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward, size: 17),
                      label: Text(_saving ? '保存中' : '记下'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '先写下一点什么吧');
      _focusNode.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(content);
      widget.onDraftChanged?.call('');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '暂时没记下来，请再试一次';
        });
      }
    }
  }
}
