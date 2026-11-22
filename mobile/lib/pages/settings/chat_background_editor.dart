import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_background.dart';

class ChatBackgroundEditor extends StatefulWidget {
  const ChatBackgroundEditor({
    required this.initial,
    required this.onPickPhoto,
    required this.onApply,
    this.onImportPhotos,
    super.key,
  });

  final DiaryChatBackground initial;
  final Future<List<String>> Function() onPickPhoto;
  final Future<List<String>> Function(List<String> paths)? onImportPhotos;
  final Future<void> Function(DiaryChatBackground value) onApply;

  @override
  State<ChatBackgroundEditor> createState() => _ChatBackgroundEditorState();
}

class _ChatBackgroundEditorState extends State<ChatBackgroundEditor> {
  late DiaryChatBackground _background;
  bool _isPicking = false;
  String? _error;
  DiaryChatBackground? _cropStart;
  Offset? _cropStartFocalPoint;

  @override
  void initState() {
    super.initState();
    _background = widget.initial.normalized();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final selected = await widget.onPickPhoto();
      if (selected.isEmpty) return;
      final imported = widget.onImportPhotos == null
          ? selected
          : await widget.onImportPhotos!(selected);
      if (imported.isEmpty) return;
      if (!mounted) return;
      setState(
        () => _background = DiaryChatBackground(
          imagePath: imported.first,
          scale: 1,
          alignmentX: 0,
          alignmentY: 0,
          opacity: .22,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = '暂时无法读取这张图片，请换一张再试。');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _update(DiaryChatBackground next) {
    setState(() => _background = next.normalized());
  }

  void _startCrop(ScaleStartDetails details) {
    _cropStart = _background;
    _cropStartFocalPoint = details.localFocalPoint;
  }

  void _updateCrop(ScaleUpdateDetails details, BoxConstraints constraints) {
    final start = _cropStart;
    final focalPoint = _cropStartFocalPoint;
    if (start == null || focalPoint == null) return;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) return;
    final horizontalDelta =
        (details.localFocalPoint.dx - focalPoint.dx) / width;
    final verticalDelta = (details.localFocalPoint.dy - focalPoint.dy) / height;
    _update(
      start.copyWith(
        scale: start.scale * details.scale,
        alignmentX: start.alignmentX - horizontalDelta * 2,
        alignmentY: start.alignmentY - verticalDelta * 2,
      ),
    );
  }

  void _resetCrop() {
    _update(_background.copyWith(scale: 1, alignmentX: 0, alignmentY: 0));
  }

  Future<void> _apply() async {
    await widget.onApply(_background);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('聊天背景'),
        actions: [
          TextButton(
            key: const Key('chat-background-apply'),
            onPressed: _apply,
            child: Text(
              _background.hasImage ? '应用' : '恢复默认',
              style: TextStyle(color: colors.terracotta),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: _ChatBackgroundPreview(
                background: _background,
                onScaleStart: _background.hasImage ? _startCrop : null,
                onScaleUpdate: _background.hasImage ? _updateCrop : null,
                onDoubleTap: _background.hasImage ? _resetCrop : null,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.line)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _background.hasImage ? '调整背景' : '选择一张背景图',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _background.hasImage
                          ? '直接拖动预览调整位置，双指缩放；双击可恢复居中。'
                          : '图片会只出现在聊天消息区域，顶部和输入框保持清晰。',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('chat-background-select'),
                        onPressed: _isPicking ? null : _pickPhoto,
                        icon: _isPicking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _background.hasImage
                                    ? Icons.photo_library_outlined
                                    : Icons.add_photo_alternate_outlined,
                              ),
                        label: Text(_background.hasImage ? '更换图片' : '从相册选择图片'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.terracotta,
                        ),
                      ),
                    ],
                    if (_background.hasImage) ...[
                      const SizedBox(height: 16),
                      _BackgroundSlider(
                        key: const Key('chat-background-opacity-slider'),
                        label: '图片存在感',
                        value: _background.opacity,
                        min: .08,
                        max: .5,
                        divisions: 14,
                        onChanged: (value) =>
                            _update(_background.copyWith(opacity: value)),
                      ),
                      ExpansionTile(
                        key: const Key('chat-background-fine-tune'),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const Text('精细调整'),
                        subtitle: Text(
                          '缩放 ${(_background.scale * 100).round()}% · 可用滑杆微调取景',
                        ),
                        children: [
                          _BackgroundSlider(
                            key: const Key('chat-background-scale-slider'),
                            label: '缩放',
                            value: _background.scale,
                            min: 1,
                            max: 2.5,
                            divisions: 15,
                            onChanged: (value) =>
                                _update(_background.copyWith(scale: value)),
                          ),
                          _BackgroundSlider(
                            key: const Key('chat-background-horizontal-slider'),
                            label: '左右位置',
                            value: _background.alignmentX,
                            min: -1,
                            max: 1,
                            divisions: 20,
                            onChanged: (value) => _update(
                              _background.copyWith(alignmentX: value),
                            ),
                          ),
                          _BackgroundSlider(
                            key: const Key('chat-background-vertical-slider'),
                            label: '上下位置',
                            value: _background.alignmentY,
                            min: -1,
                            max: 1,
                            divisions: 20,
                            onChanged: (value) => _update(
                              _background.copyWith(alignmentY: value),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        key: const Key('chat-background-remove'),
                        onPressed: () => _update(const DiaryChatBackground()),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('移除背景图片'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBackgroundPreview extends StatelessWidget {
  const _ChatBackgroundPreview({
    required this.background,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onDoubleTap,
  });

  final DiaryChatBackground background;
  final ValueChanged<ScaleStartDetails>? onScaleStart;
  final void Function(ScaleUpdateDetails details, BoxConstraints constraints)?
  onScaleUpdate;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(color: colors.ink.withValues(alpha: .08), blurRadius: 14),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            Container(
              height: 50,
              color: colors.surface,
              alignment: Alignment.center,
              child: Text(
                '我的日记',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: const Key('chat-background-crop-canvas'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: onScaleStart,
                  onScaleUpdate: onScaleUpdate == null
                      ? null
                      : (details) => onScaleUpdate!(details, constraints),
                  onDoubleTap: onDoubleTap,
                  child: DiaryChatBackgroundLayer(
                    background: background,
                    fallbackColor: colors.paper,
                    imageKey: background.hasImage
                        ? ValueKey(
                            'chat-background-preview-${background.imagePath}',
                          )
                        : null,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            children: [
                              Text(
                                '09/19 20:18',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.mutedInk),
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _PreviewMessageBubble(
                                  color: colors.surface.withValues(alpha: .94),
                                  textColor: colors.ink,
                                  text: '今天的云很好看。',
                                ),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _PreviewMessageBubble(
                                  color: colors.terracotta,
                                  textColor: Colors.white,
                                  text: '把这一刻记下来',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (background.hasImage)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.ink.withValues(alpha: .58),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    '拖动调整 · 双指缩放',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 54,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    color: colors.mutedInk,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.line),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.add_circle_outline,
                    color: colors.mutedInk,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMessageBubble extends StatelessWidget {
  const _PreviewMessageBubble({
    required this.color,
    required this.textColor,
    required this.text,
  });

  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BackgroundSlider extends StatelessWidget {
  const _BackgroundSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: colors.terracotta,
          inactiveColor: colors.line,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
