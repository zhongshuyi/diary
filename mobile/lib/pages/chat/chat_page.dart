import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_chat_background.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/hold_to_record_button.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';
import 'package:diary/widgets/selected_photo_strip.dart';

typedef ChatMessageSender =
    Future<void> Function(
      String content,
      List<String> imagePaths,
      List<String> audioPaths,
      List<String> videoPaths,
      double mood,
      String? moodLabel,
    );

const _chatScrollDuration = Duration(milliseconds: 260);
const _chatMessageEntranceDuration = Duration(milliseconds: 280);
const _chatReducedMotionDuration = Duration(milliseconds: 140);
const _chatActionTransitionDuration = Duration(milliseconds: 160);
const _chatActionFeedbackDuration = Duration(milliseconds: 120);
const _chatMessageEntranceOffset = 12.0;

/// A second, conversational way to browse and create the same diary entries.
/// Nothing here owns a separate message store: a sent message remains visible
/// in the timeline, calendar, search and media library.
class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.entries,
    required this.onSend,
    required this.onOpenEntry,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenEditor,
    required this.onImportAttachments,
    required this.onNavigate,
    this.title = diaryDefaultChatTitle,
    this.chatBackground = const DiaryChatBackground(),
    this.pickGalleryPhotos,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ChatMessageSender onSend;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final Future<void> Function(DiaryEntry entry) onEdit;
  final Future<void> Function(DiaryEntry entry) onDelete;
  final VoidCallback onOpenEditor;
  final Future<List<String>> Function(List<String> paths) onImportAttachments;
  final ValueChanged<ChatPageDestination> onNavigate;
  final String title;
  final DiaryChatBackground chatBackground;
  final Future<List<String>> Function(int maxAssets)? pickGalleryPhotos;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  final _enteringMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousIds = oldWidget.entries.map((entry) => entry.id).toSet();
    final currentIds = widget.entries.map((entry) => entry.id).toSet();
    final addedIds = currentIds.difference(previousIds);
    final staleIds = _enteringMessageIds.difference(currentIds);
    if (addedIds.isNotEmpty || staleIds.isNotEmpty) {
      setState(() {
        _enteringMessageIds
          ..removeAll(staleIds)
          ..addAll(addedIds);
      });
    }
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: _chatScrollDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _finishMessageEntrance(String entryId) {
    if (!_enteringMessageIds.contains(entryId)) return;
    setState(() => _enteringMessageIds.remove(entryId));
  }

  List<_ChatDay> _groupedEntries() {
    final sorted = List<DiaryEntry>.of(widget.entries)
      ..sort(
        (left, right) =>
            left.effectiveOccurredAt.compareTo(right.effectiveOccurredAt),
      );
    final days = <_ChatDay>[];
    for (final entry in sorted) {
      final occurredAt = entry.effectiveOccurredAt;
      final date = DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
      if (days.isEmpty || !DateUtils.isSameDay(days.last.date, date)) {
        days.add(_ChatDay(date: date, entries: [entry]));
      } else {
        days.last.entries.add(entry);
      }
    }
    return days;
  }

  Future<void> _showEntryActions(DiaryEntry entry) async {
    final action = await showModalBottomSheet<_ChatEntryAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑这条日记'),
              onTap: () => Navigator.pop(context, _ChatEntryAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              title: const Text('移入回收站'),
              onTap: () => Navigator.pop(context, _ChatEntryAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _ChatEntryAction.edit) {
      await widget.onEdit(entry);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移入回收站？'),
        content: const Text('这条日记会保留在回收站，之后仍可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移入回收站'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.onDelete(entry);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final days = _groupedEntries();
    return ColoredBox(
      color: colors.paper,
      child: Column(
        children: [
          _ChatHeader(title: widget.title, onNavigate: widget.onNavigate),
          Expanded(
            child: DiaryChatBackgroundLayer(
              background: widget.chatBackground,
              fallbackColor: colors.paper,
              imageKey: widget.chatBackground.hasImage
                  ? ValueKey(
                      'chat-background-image-${widget.chatBackground.imagePath}',
                    )
                  : null,
              child: days.isEmpty
                  ? const _EmptyChat()
                  : ListView.builder(
                      key: const Key('chat-message-list'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        return _ChatDaySection(
                          day: day,
                          enteringMessageIds: _enteringMessageIds,
                          onMessageEntranceFinished: _finishMessageEntrance,
                          onOpenEntry: widget.onOpenEntry,
                          onLongPress: _showEntryActions,
                        );
                      },
                    ),
            ),
          ),
          _ChatComposer(
            onSend: widget.onSend,
            onSent: _scrollToLatest,
            onOpenEditor: widget.onOpenEditor,
            onImportAttachments: widget.onImportAttachments,
            pickGalleryPhotos: widget.pickGalleryPhotos,
            onExternalActivityStart: widget.onExternalActivityStart,
            onExternalActivityEnd: widget.onExternalActivityEnd,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title, required this.onNavigate});

  final String title;
  final ValueChanged<ChatPageDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('chat-back-to-timeline'),
              tooltip: '返回时间线',
              visualDensity: VisualDensity.compact,
              onPressed: () => onNavigate(ChatPageDestination.timeline),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<ChatPageDestination>(
              key: const Key('chat-more-menu'),
              tooltip: '打开日记功能',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.menu_rounded, size: 23),
              onSelected: onNavigate,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ChatPageDestination.timeline,
                  child: _ChatMenuItem(
                    icon: Icons.view_agenda_outlined,
                    label: '时间线',
                  ),
                ),
                PopupMenuItem(
                  value: ChatPageDestination.calendar,
                  child: _ChatMenuItem(
                    icon: Icons.calendar_month_outlined,
                    label: '日历',
                  ),
                ),
                PopupMenuItem(
                  value: ChatPageDestination.media,
                  child: _ChatMenuItem(
                    icon: Icons.collections_outlined,
                    label: '媒体库',
                  ),
                ),
                PopupMenuItem(
                  value: ChatPageDestination.insights,
                  child: _ChatMenuItem(
                    icon: Icons.auto_graph_outlined,
                    label: '洞察',
                  ),
                ),
                PopupMenuItem(
                  value: ChatPageDestination.profile,
                  child: _ChatMenuItem(icon: Icons.person_outline, label: '我的'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 19), const SizedBox(width: 10), Text(label)],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 42, color: colors.terracotta),
            const SizedBox(height: 14),
            Text('从一句话开始', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(
              '这里会按时间收拢你的想法、照片、视频和语音。',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatDaySection extends StatelessWidget {
  const _ChatDaySection({
    required this.day,
    required this.enteringMessageIds,
    required this.onMessageEntranceFinished,
    required this.onOpenEntry,
    required this.onLongPress,
  });

  final _ChatDay day;
  final Set<String> enteringMessageIds;
  final ValueChanged<String> onMessageEntranceFinished;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final Future<void> Function(DiaryEntry entry) onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in day.entries)
          KeyedSubtree(
            key: ValueKey('chat-entry-${entry.id}'),
            child: _ChatMessageEntrance(
              animate: enteringMessageIds.contains(entry.id),
              onEnd: () => onMessageEntranceFinished(entry.id),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 13, bottom: 8),
                    child: Text(
                      _chatTimestampLabel(entry.effectiveOccurredAt),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DiaryThemeColors.of(context).mutedInk,
                      ),
                    ),
                  ),
                  _ChatEntryBubble(
                    entry: entry,
                    onOpen: () => onOpenEntry(entry),
                    onLongPress: () => unawaited(onLongPress(entry)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatMessageEntrance extends StatelessWidget {
  const _ChatMessageEntrance({
    required this.animate,
    required this.onEnd,
    required this.child,
  });

  final bool animate;
  final VoidCallback onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? _chatReducedMotionDuration
          : _chatMessageEntranceDuration,
      curve: Curves.easeOutCubic,
      onEnd: onEnd,
      child: RepaintBoundary(child: child),
      builder: (context, value, child) {
        final offset = reduceMotion
            ? 0.0
            : (1 - value) * _chatMessageEntranceOffset;
        final scale = reduceMotion ? 1.0 : .98 + (.02 * value);
        return Opacity(
          opacity: .35 + (.65 * value),
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Transform.scale(
              alignment: Alignment.centerRight,
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ChatEntryBubble extends StatelessWidget {
  const _ChatEntryBubble({
    required this.entry,
    required this.onOpen,
    required this.onLongPress,
  });

  final DiaryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final content = entry.contentText.trim();
    final mood = _ChatMood.forLabel(entry.moodLabel);
    final isMoodOnly = content.isEmpty && mood != null && !entry.hasMedia;
    final isImageOnly =
        content.isEmpty &&
        mood == null &&
        entry.imagePaths.isNotEmpty &&
        entry.audioPaths.isEmpty &&
        entry.videoPaths.isEmpty;
    final isVoiceOnly =
        content.isEmpty &&
        mood == null &&
        entry.imagePaths.isEmpty &&
        entry.videoPaths.isEmpty &&
        entry.audioPaths.isNotEmpty;
    if (isMoodOnly) {
      return _ChatMoodEvent(
        mood: mood,
        onOpen: onOpen,
        onLongPress: onLongPress,
      );
    }
    if (isImageOnly) {
      return _ChatImageMessage(entry: entry, onLongPress: onLongPress);
    }

    final textBubbleColor = Color.lerp(
      colors.terracottaSoft,
      colors.terracotta,
      .12,
    )!;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FractionallySizedBox(
            widthFactor: isVoiceOnly ? .62 : .86,
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: isVoiceOnly ? colors.terracotta : textBubbleColor,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onOpen,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mood != null) ...[
                            _ChatMoodBadge(mood: mood),
                            if (content.isNotEmpty || entry.hasMedia)
                              const SizedBox(height: 8),
                          ],
                          if (content.isNotEmpty)
                            Text(
                              content,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                            ),
                          if (content.isNotEmpty && entry.hasMedia)
                            const SizedBox(height: 10),
                          if (entry.imagePaths.isNotEmpty)
                            _ChatImageGrid(entry: entry),
                          if (entry.imagePaths.isNotEmpty &&
                              (entry.audioPaths.isNotEmpty ||
                                  entry.videoPaths.isNotEmpty))
                            const SizedBox(height: 8),
                          for (
                            var index = 0;
                            index < entry.audioPaths.length;
                            index++
                          ) ...[
                            DiaryAudioPlayer(
                              path: entry.audioPaths[index],
                              compact: true,
                              chatStyle: true,
                              chatStyleHighContrast: isVoiceOnly,
                            ),
                            if (index < entry.audioPaths.length - 1 ||
                                entry.videoPaths.isNotEmpty)
                              const SizedBox(height: 8),
                          ],
                          for (
                            var index = 0;
                            index < entry.videoPaths.length;
                            index++
                          ) ...[
                            _ChatVideoAttachment(onTap: onOpen),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatImageMessage extends StatelessWidget {
  const _ChatImageMessage({required this.entry, required this.onLongPress});

  final DiaryEntry entry;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FractionallySizedBox(
            widthFactor: .78,
            alignment: Alignment.centerRight,
            child: GestureDetector(
              key: ValueKey('chat-image-message-${entry.id}'),
              behavior: HitTestBehavior.translucent,
              onLongPress: onLongPress,
              child: _ChatImageGrid(entry: entry),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMoodEvent extends StatelessWidget {
  const _ChatMoodEvent({
    required this.mood,
    required this.onOpen,
    required this.onLongPress,
  });

  final _ChatMood mood;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Semantics(
          label: '心情：${mood.label}',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpen,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(mood.icon, size: 18, color: colors.terracotta),
                    const SizedBox(width: 5),
                    Text(
                      '此刻 · ${mood.label}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatImageGrid extends StatelessWidget {
  const _ChatImageGrid({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.imagePaths.length > 1) {
      return _ChatImageStack(entry: entry);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min<double>(constraints.maxWidth, 310);
        return SizedBox(
          width: size,
          height: size,
          child: DiaryImageThumbnail(
            entryId: entry.id,
            imagePaths: entry.imagePaths,
            index: 0,
            borderRadius: 14,
            expand: true,
            heroScope: 'chat',
          ),
        );
      },
    );
  }
}

class _ChatImageStack extends StatelessWidget {
  const _ChatImageStack({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final visibleLayers = math.min(3, entry.imagePaths.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = math.min<double>(
          math.max(0, constraints.maxWidth - 16),
          236,
        );
        final imageHeight = imageWidth * .74;
        return SizedBox(
          key: ValueKey('chat-image-stack-${entry.id}'),
          width: imageWidth + 16,
          height: imageHeight + 16,
          child: Stack(
            children: [
              for (var index = visibleLayers - 1; index >= 0; index--)
                _ChatImageStackLayer(
                  entry: entry,
                  index: index,
                  imageWidth: imageWidth,
                  imageHeight: imageHeight,
                  colors: colors,
                ),
              Positioned(
                right: 7,
                bottom: 7,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .64),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.imagePaths.length} 张',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatImageStackLayer extends StatelessWidget {
  const _ChatImageStackLayer({
    required this.entry,
    required this.index,
    required this.imageWidth,
    required this.imageHeight,
    required this.colors,
  });

  final DiaryEntry entry;
  final int index;
  final double imageWidth;
  final double imageHeight;
  final DiaryThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final depth = math.min(index, 2);
    final isFrontImage = index == 0;
    final thumbnail = DiaryImageThumbnail(
      entryId: entry.id,
      imagePaths: entry.imagePaths,
      index: index,
      borderRadius: 14,
      expand: true,
      heroScope: 'chat',
    );
    return Positioned(
      left: 16 - (depth * 8),
      top: depth * 8,
      child: SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: isFrontImage
            ? thumbnail
            : IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: thumbnail,
                ),
              ),
      ),
    );
  }
}

class _ChatVideoAttachment extends StatelessWidget {
  const _ChatVideoAttachment({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline),
              SizedBox(width: 8),
              Text('视频'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({
    required this.onSend,
    required this.onSent,
    required this.onOpenEditor,
    required this.onImportAttachments,
    this.pickGalleryPhotos,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
  });

  final ChatMessageSender onSend;
  final VoidCallback onSent;
  final VoidCallback onOpenEditor;
  final Future<List<String>> Function(List<String> paths) onImportAttachments;
  final Future<List<String>> Function(int maxAssets)? pickGalleryPhotos;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePaths = <String>[];
  final _audioPaths = <String>[];
  final _videoPaths = <String>[];
  _ChatMood? _selectedMood;
  bool _isSending = false;
  bool _isImporting = false;

  bool get _hasDraft =>
      _controller.text.trim().isNotEmpty ||
      _imagePaths.isNotEmpty ||
      _audioPaths.isNotEmpty ||
      _videoPaths.isNotEmpty ||
      _selectedMood != null;

  bool get _hasTypedText => _controller.text.trim().isNotEmpty;

  bool get _hasMood => _selectedMood != null;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showAddMenu() async {
    if (_isSending || _isImporting) return;
    final choice = await showModalBottomSheet<_ChatAttachmentAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('照片'),
              onTap: () => Navigator.pop(context, _ChatAttachmentAction.image),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('视频'),
              onTap: () => Navigator.pop(context, _ChatAttachmentAction.video),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_outlined),
              title: const Text('录音'),
              onTap: () => Navigator.pop(context, _ChatAttachmentAction.audio),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('写完整日记'),
              onTap: () => Navigator.pop(context, _ChatAttachmentAction.entry),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _ChatAttachmentAction.image:
        await _pickImages();
        break;
      case _ChatAttachmentAction.video:
        await _pickVideos();
        break;
      case _ChatAttachmentAction.audio:
        await _recordVoice();
        break;
      case _ChatAttachmentAction.entry:
        widget.onOpenEditor();
        break;
    }
  }

  Future<void> _pickImages() async {
    final remaining = 9 - _imagePaths.length;
    if (remaining <= 0) {
      _showMessage('一次最多添加 9 张照片');
      return;
    }
    await _importExternal(
      () => _pickGalleryPhotos(remaining),
      _imagePaths,
      runsOutsideApp: !_usesInAppPhotoPicker,
    );
  }

  bool get _usesInAppPhotoPicker =>
      widget.pickGalleryPhotos != null ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS => true,
        _ => false,
      };

  Future<List<String>> _pickGalleryPhotos(int maxAssets) async {
    final overriddenPicker = widget.pickGalleryPhotos;
    if (overriddenPicker != null) return overriddenPicker(maxAssets);
    if (_usesInAppPhotoPicker) {
      return pickDiaryPhotos(context, maxAssets: maxAssets);
    }
    final files = await ImagePicker().pickMultiImage(imageQuality: 92);
    return files.map((file) => file.path).toList(growable: false);
  }

  Future<void> _pickVideos() async {
    await _importExternal(() async {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );
      return result?.files
              .map((file) => file.path)
              .whereType<String>()
              .toList(growable: false) ??
          const [];
    }, _videoPaths);
  }

  Future<void> _importExternal(
    Future<List<String>> Function() pick,
    List<String> target, {
    bool runsOutsideApp = true,
  }) async {
    if (_isImporting || _isSending) return;
    setState(() => _isImporting = true);
    if (runsOutsideApp) widget.onExternalActivityStart?.call();
    try {
      final picked = await pick();
      if (picked.isEmpty) return;
      final imported = await widget.onImportAttachments(picked);
      if (!mounted) return;
      setState(() {
        for (final path in imported) {
          if (!target.contains(path)) target.add(path);
        }
      });
    } catch (_) {
      if (mounted) _showMessage('附件没有添加成功，请重试');
    } finally {
      if (runsOutsideApp) widget.onExternalActivityEnd?.call();
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _recordVoice() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _VoiceRecordSheet(
        onRecorded: (path) async {
          if (!mounted) return;
          setState(() {
            if (!_audioPaths.contains(path)) _audioPaths.add(path);
          });
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
        onError: _showMessage,
      ),
    );
  }

  Future<void> _showMoodPicker() async {
    final result = await showModalBottomSheet<_ChatMoodPickerResult>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '此刻的心情',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      const _ChatMoodPickerResult(),
                    ),
                    child: const Text('不标记'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var index = 0; index < _ChatMood.values.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == _ChatMood.values.length - 1 ? 0 : 6,
                        ),
                        child: _ChatMoodChoice(
                          mood: _ChatMood.values[index],
                          selected: _selectedMood == _ChatMood.values[index],
                          onTap: () => Navigator.pop(
                            sheetContext,
                            _ChatMoodPickerResult(
                              mood: _ChatMood.values[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedMood = result.mood);
  }

  Future<void> _send() async {
    if (!_hasDraft || _isSending || _isImporting) return;
    final selectedMood = _selectedMood;
    setState(() => _isSending = true);
    try {
      await widget.onSend(
        _controller.text,
        List.of(_imagePaths),
        List.of(_audioPaths),
        List.of(_videoPaths),
        selectedMood?.value ?? .5,
        selectedMood?.label,
      );
      if (!mounted) return;
      setState(() {
        _controller.clear();
        _imagePaths.clear();
        _audioPaths.clear();
        _videoPaths.clear();
        _selectedMood = null;
      });
      widget.onSent();
    } catch (_) {
      if (mounted) _showMessage('发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasAttachments)
              _AttachmentPreview(
                imagePaths: _imagePaths,
                audioPaths: _audioPaths,
                videoPaths: _videoPaths,
                onRemoveImage: (path) =>
                    setState(() => _imagePaths.remove(path)),
                onRemoveAudio: (path) =>
                    setState(() => _audioPaths.remove(path)),
                onRemoveVideo: (path) =>
                    setState(() => _videoPaths.remove(path)),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: '录音',
                  onPressed: _isSending ? null : _recordVoice,
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 44,
                  ),
                  icon: const Icon(Icons.mic_none_rounded),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.paper,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      key: const Key('chat-message-field'),
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => unawaited(_send()),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '写点什么…',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('chat-mood-button'),
                  tooltip: _selectedMood == null
                      ? '记录心情'
                      : '心情：${_selectedMood!.label}',
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 44,
                  ),
                  onPressed: _isSending || _isImporting
                      ? null
                      : _showMoodPicker,
                  icon: _selectedMood == null
                      ? const Icon(Icons.mood_outlined)
                      : Icon(_selectedMood!.icon, color: colors.terracotta),
                ),
                const SizedBox(width: 2),
                AnimatedSwitcher(
                  duration: _chatActionTransitionDuration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: .92, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerRight,
                    children: [...previousChildren, ?currentChild],
                  ),
                  child: _hasTypedText || _hasAttachments || _hasMood
                      ? FilledButton(
                          key: const Key('chat-send-button'),
                          onPressed: _isSending || _isImporting ? null : _send,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(58, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: AnimatedSwitcher(
                            duration: _chatActionFeedbackDuration,
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _isSending
                                ? const SizedBox(
                                    key: ValueKey('chat-sending-indicator'),
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '发送',
                                    key: ValueKey('chat-send-label'),
                                  ),
                          ),
                        )
                      : IconButton(
                          key: const Key('chat-add-button'),
                          tooltip: '添加照片、视频或录音',
                          onPressed: _isImporting ? null : _showAddMenu,
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 44,
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasAttachments =>
      _imagePaths.isNotEmpty ||
      _audioPaths.isNotEmpty ||
      _videoPaths.isNotEmpty;
}

class _ChatMood {
  const _ChatMood({
    required this.label,
    required this.icon,
    required this.value,
  });

  static const values = [
    _ChatMood(label: '阴天', icon: Icons.cloud_outlined, value: .1),
    _ChatMood(
      label: '低落',
      icon: Icons.sentiment_dissatisfied_outlined,
      value: .3,
    ),
    _ChatMood(label: '平常', icon: Icons.sentiment_neutral_outlined, value: .5),
    _ChatMood(
      label: '平静',
      icon: Icons.sentiment_satisfied_alt_outlined,
      value: .7,
    ),
    _ChatMood(label: '明亮', icon: Icons.wb_sunny_outlined, value: .9),
  ];

  final String label;
  final IconData icon;
  final double value;

  static _ChatMood? forLabel(String? label) {
    for (final mood in values) {
      if (mood.label == label) return mood;
    }
    return null;
  }
}

class _ChatMoodPickerResult {
  const _ChatMoodPickerResult({this.mood});

  final _ChatMood? mood;
}

class _ChatMoodChoice extends StatelessWidget {
  const _ChatMoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final _ChatMood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: Material(
        color: selected ? colors.terracottaSoft : colors.paper,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('chat-mood-choice-${mood.label}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.terracotta : colors.line,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mood.icon,
                  size: 22,
                  color: selected ? colors.terracotta : colors.mutedInk,
                ),
                const SizedBox(height: 3),
                Text(
                  mood.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMoodBadge extends StatelessWidget {
  const _ChatMoodBadge({required this.mood});

  final _ChatMood mood;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mood.icon, size: 15, color: colors.terracotta),
          const SizedBox(width: 4),
          Text(
            mood.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.imagePaths,
    required this.audioPaths,
    required this.videoPaths,
    required this.onRemoveImage,
    required this.onRemoveAudio,
    required this.onRemoveVideo,
  });

  final List<String> imagePaths;
  final List<String> audioPaths;
  final List<String> videoPaths;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onRemoveAudio;
  final ValueChanged<String> onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectedPhotoStrip(
            paths: imagePaths,
            onRemove: onRemoveImage,
            keyPrefix: 'chat-selected-photo',
          ),
          for (final path in audioPaths) ...[
            DiaryAudioPlayer(
              path: path,
              label: '语音',
              onRemove: () => onRemoveAudio(path),
            ),
            const SizedBox(height: 8),
          ],
          if (videoPaths.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final path in videoPaths)
                  InputChip(
                    avatar: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('视频'),
                    onDeleted: () => onRemoveVideo(path),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VoiceRecordSheet extends StatelessWidget {
  const _VoiceRecordSheet({required this.onRecorded, required this.onError});

  final Future<void> Function(String path) onRecorded;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('录一段语音', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '按住开始，松开后加入待发送消息。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
            ),
            const SizedBox(height: 18),
            HoldToRecordButton(
              buttonKey: const Key('chat-hold-to-record'),
              onRecorded: onRecorded,
              onError: onError,
            ),
          ],
        ),
      ),
    );
  }
}

String _chatTimestampLabel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$month/$day ${diaryTimeLabel(value)}';
}

class _ChatDay {
  _ChatDay({required this.date, required this.entries});

  final DateTime date;
  final List<DiaryEntry> entries;
}

enum _ChatEntryAction { edit, delete }

enum _ChatAttachmentAction { image, video, audio, entry }

enum ChatPageDestination { timeline, calendar, media, insights, profile }
