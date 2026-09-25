import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_place.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/data/amap_location_bridge.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_avatar.dart';
import 'package:diary/widgets/diary_chat_background.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/diary_video_player.dart';
import 'package:diary/widgets/hold_to_record_button.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';
import 'package:diary/widgets/local_media_preview.dart';
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

const _chatMessageEntranceDuration = Duration(milliseconds: 300);
const _chatActionTransitionDuration = Duration(milliseconds: 160);
const _chatActionFeedbackDuration = Duration(milliseconds: 120);
const _chatMessageEntranceOffset = 18.0;
final _chatSelectionControls = _CompactChatSelectionControls();

class _CompactChatSelectionControls extends MaterialTextSelectionControls {
  static const _handleSize = 14.0;

  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(_handleSize, _handleSize);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return switch (type) {
      TextSelectionHandleType.collapsed => const Offset(_handleSize / 2, -3),
      TextSelectionHandleType.left => const Offset(_handleSize, 0),
      TextSelectionHandleType.right => Offset.zero,
    };
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    final color =
        TextSelectionTheme.of(context).selectionHandleColor ??
        Theme.of(context).colorScheme.primary;
    final handle = SizedBox.square(
      dimension: _handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: CustomPaint(painter: _CompactChatHandlePainter(color)),
      ),
    );
    return switch (type) {
      TextSelectionHandleType.left => Transform.rotate(
        angle: math.pi / 2,
        child: handle,
      ),
      TextSelectionHandleType.right => handle,
      TextSelectionHandleType.collapsed => Transform.rotate(
        angle: math.pi / 4,
        child: handle,
      ),
    };
  }
}

class _CompactChatHandlePainter extends CustomPainter {
  const _CompactChatHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CompactChatHandlePainter oldDelegate) =>
      color != oldDelegate.color;
}

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
    this.onSendLocation,
    this.pickLocation,
    this.onOpenLocation,
    this.amapAndroidKey = '',
    this.entriesLoading = false,
    this.title = diaryDefaultChatTitle,
    this.chatBackground = const DiaryChatBackground(),
    this.showChatAvatar = false,
    this.profileAvatarPath,
    this.pickGalleryPhotos,
    this.pickCameraPhoto,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.onLoadDraft,
    this.onSaveDraft,
    this.onClearDraft,
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
  final Future<void> Function(DiaryPlace place)? onSendLocation;
  final Future<DiaryPlace?> Function()? pickLocation;
  final ValueChanged<DiaryEntry>? onOpenLocation;
  final String amapAndroidKey;
  final bool entriesLoading;
  final String title;
  final DiaryChatBackground chatBackground;
  final bool showChatAvatar;
  final String? profileAvatarPath;
  final Future<List<String>> Function(int maxAssets)? pickGalleryPhotos;
  final Future<String?> Function()? pickCameraPhoto;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<DraftPayload?> Function(String id)? onLoadDraft;
  final Future<void> Function(DraftPayload draft)? onSaveDraft;
  final Future<void> Function(String id)? onClearDraft;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _messagePageSize = 40;
  final _scrollController = ScrollController();
  final _composerFocusNode = FocusNode();
  final _enteringMessageIds = <String>{};
  bool _scrollToLatestScheduled = false;
  bool _loadOlderScheduled = false;
  int _visibleMessageCount = _messagePageSize;
  double? _lastChatViewportDimension;
  List<DiaryEntry>? _sortedSource;
  List<DiaryEntry> _sortedCache = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.entries, widget.entries)) return;
    final previousIds = oldWidget.entries.map((entry) => entry.id).toSet();
    final currentIds = widget.entries.map((entry) => entry.id).toSet();
    final addedIds = currentIds.difference(previousIds);
    final staleIds = _enteringMessageIds.difference(currentIds);
    _enteringMessageIds.removeAll(staleIds);
    if (!oldWidget.entriesLoading && addedIds.length == 1) {
      _enteringMessageIds.addAll(addedIds);
    }
    if (widget.entries.length > oldWidget.entries.length &&
        (!_scrollController.hasClients ||
            _composerFocusNode.hasFocus ||
            _scrollController.position.pixels < 120)) {
      _scheduleScrollToLatest();
    }
  }

  void _onScroll() {
    if (_loadOlderScheduled || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (_visibleMessageCount >= widget.entries.length ||
        position.pixels < position.maxScrollExtent - 200) {
      return;
    }
    _loadOlderScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOlderScheduled = false;
      if (!mounted) return;
      setState(() => _visibleMessageCount += _messagePageSize);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _scheduleScrollToLatest() {
    if (_scrollToLatestScheduled) return;
    _scrollToLatestScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatestScheduled = false;
      if (mounted) _scrollToLatest();
    });
  }

  void _finishMessageEntrance(String entryId) {
    _enteringMessageIds.remove(entryId);
  }

  void _openProfile() => widget.onNavigate(ChatPageDestination.profile);

  List<DiaryEntry> _sortedEntries() {
    if (!identical(_sortedSource, widget.entries)) {
      _sortedSource = widget.entries;
      _sortedCache = List<DiaryEntry>.of(widget.entries)
        ..sort(
          (left, right) =>
              left.effectiveOccurredAt.compareTo(right.effectiveOccurredAt),
        );
    }
    return _sortedCache;
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

  Future<void> _openLocation(DiaryEntry entry) async {
    widget.onExternalActivityStart?.call();
    try {
      await AmapLocationBridge.showEntry(context, entry, widget.amapAndroidKey);
    } finally {
      widget.onExternalActivityEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final entries = _sortedEntries();
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
              child: entries.isEmpty
                  ? const _EmptyChat()
                  : NotificationListener<ScrollMetricsNotification>(
                      onNotification: (notification) {
                        if (notification.depth != 0) return false;
                        final viewportDimension =
                            notification.metrics.viewportDimension;
                        final previousViewportDimension =
                            _lastChatViewportDimension;
                        final viewportChanged =
                            previousViewportDimension != null &&
                            previousViewportDimension != viewportDimension;
                        _lastChatViewportDimension = viewportDimension;
                        if (viewportChanged && _composerFocusNode.hasFocus) {
                          _scheduleScrollToLatest();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        key: const Key('chat-message-list'),
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        itemCount: entries.length < _visibleMessageCount
                            ? entries.length
                            : _visibleMessageCount,
                        itemBuilder: (context, index) {
                          final entry = entries[entries.length - index - 1];
                          return _ChatEntryItem(
                            entry: entry,
                            enteringMessageIds: _enteringMessageIds,
                            onMessageEntranceFinished: _finishMessageEntrance,
                            onOpenEntry: widget.onOpenEntry,
                            onOpenLocation:
                                widget.onOpenLocation ??
                                (entry) => unawaited(_openLocation(entry)),
                            onLongPress: _showEntryActions,
                            onAvatarTap: _openProfile,
                            showChatAvatar: widget.showChatAvatar,
                            profileAvatarPath: widget.profileAvatarPath,
                          );
                        },
                      ),
                    ),
            ),
          ),
          _ChatComposer(
            focusNode: _composerFocusNode,
            onSend: widget.onSend,
            onSendLocation: widget.onSendLocation,
            pickLocation:
                widget.pickLocation ??
                () => AmapLocationBridge.pick(context, widget.amapAndroidKey),
            amapAndroidKey: widget.amapAndroidKey,
            onSent: _scheduleScrollToLatest,
            onOpenEditor: widget.onOpenEditor,
            onImportAttachments: widget.onImportAttachments,
            pickGalleryPhotos: widget.pickGalleryPhotos,
            pickCameraPhoto: widget.pickCameraPhoto,
            onExternalActivityStart: widget.onExternalActivityStart,
            onExternalActivityEnd: widget.onExternalActivityEnd,
            onLoadDraft: widget.onLoadDraft,
            onSaveDraft: widget.onSaveDraft,
            onClearDraft: widget.onClearDraft,
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
          ],
        ),
      ),
    );
  }
}

class _ChatEntryItem extends StatelessWidget {
  const _ChatEntryItem({
    required this.entry,
    required this.enteringMessageIds,
    required this.onMessageEntranceFinished,
    required this.onOpenEntry,
    required this.onOpenLocation,
    required this.onLongPress,
    required this.onAvatarTap,
    required this.showChatAvatar,
    required this.profileAvatarPath,
  });

  final DiaryEntry entry;
  final Set<String> enteringMessageIds;
  final ValueChanged<String> onMessageEntranceFinished;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final ValueChanged<DiaryEntry> onOpenLocation;
  final Future<void> Function(DiaryEntry entry) onLongPress;
  final VoidCallback onAvatarTap;
  final bool showChatAvatar;
  final String? profileAvatarPath;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
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
              onOpenLocation: () => onOpenLocation(entry),
              onLongPress: () => unawaited(onLongPress(entry)),
              onAvatarTap: onAvatarTap,
              showChatAvatar: showChatAvatar,
              profileAvatarPath: profileAvatarPath,
            ),
          ],
        ),
      ),
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
      duration: reduceMotion ? Duration.zero : _chatMessageEntranceDuration,
      curve: Curves.easeOutCubic,
      onEnd: onEnd,
      child: RepaintBoundary(child: child),
      builder: (context, value, child) => Opacity(
        opacity: .4 + (.6 * value),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * _chatMessageEntranceOffset),
          child: child,
        ),
      ),
    );
  }
}

class _ChatEntryBubble extends StatelessWidget {
  const _ChatEntryBubble({
    required this.entry,
    required this.onOpen,
    required this.onOpenLocation,
    required this.onLongPress,
    required this.onAvatarTap,
    required this.showChatAvatar,
    required this.profileAvatarPath,
  });

  final DiaryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onOpenLocation;
  final VoidCallback onLongPress;
  final VoidCallback onAvatarTap;
  final bool showChatAvatar;
  final String? profileAvatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    if (entry.isStandaloneLocation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('chat-location-${entry.id}'),
              onTap: onOpenLocation,
              onLongPress: onLongPress,
              child: SizedBox(
                width: 270,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 138,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (entry.imagePaths.isNotEmpty)
                            LocalMediaPreview(
                              path: entry.imagePaths.first,
                              kind: DiaryMediaKind.image,
                              cacheWidth: 560,
                              cacheHeight: 280,
                            )
                          else
                            CustomPaint(
                              painter: _LocationPreviewPainter(
                                background: colors.sage,
                                road: colors.surface,
                                line: colors.line,
                              ),
                            ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.ink.withValues(alpha: .18),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: colors.terracotta,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 11, 12, 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.locationDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (entry.locationDisplayAddress.isNotEmpty)
                                  Text(
                                    entry.locationDisplayAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.mutedInk,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
    final hasBubbleContent =
        content.isNotEmpty ||
        mood != null ||
        entry.imagePaths.isNotEmpty ||
        entry.audioPaths.isNotEmpty;
    if (isMoodOnly) {
      return _ChatMoodEvent(
        mood: mood,
        onOpen: onOpen,
        onLongPress: onLongPress,
      );
    }
    if (isImageOnly) {
      return _ChatImageMessage(
        entry: entry,
        onLongPress: onLongPress,
        onAvatarTap: onAvatarTap,
        showChatAvatar: showChatAvatar,
        profileAvatarPath: profileAvatarPath,
      );
    }

    final textBubbleColor = Color.lerp(
      colors.terracottaSoft,
      colors.terracotta,
      .12,
    )!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FractionallySizedBox(
                  widthFactor: isVoiceOnly ? .62 : .86,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasBubbleContent)
                        Material(
                          color: isVoiceOnly
                              ? colors.terracotta
                              : textBubbleColor,
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
                                    if (content.isNotEmpty ||
                                        entry.imagePaths.isNotEmpty ||
                                        entry.audioPaths.isNotEmpty)
                                      const SizedBox(height: 8),
                                  ],
                                  if (content.isNotEmpty)
                                    Text(
                                      content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: colors.ink,
                                            fontWeight: FontWeight.w500,
                                            height: 1.45,
                                          ),
                                    ),
                                  if (content.isNotEmpty &&
                                      (entry.imagePaths.isNotEmpty ||
                                          entry.audioPaths.isNotEmpty))
                                    const SizedBox(height: 10),
                                  if (entry.imagePaths.isNotEmpty)
                                    _ChatImageGrid(entry: entry),
                                  if (entry.imagePaths.isNotEmpty &&
                                      entry.audioPaths.isNotEmpty)
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
                                      loadMetadata: false,
                                      loadWaveform: false,
                                    ),
                                    if (index < entry.audioPaths.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (hasBubbleContent && entry.videoPaths.isNotEmpty)
                        const SizedBox(height: 8),
                      for (
                        var index = 0;
                        index < entry.videoPaths.length;
                        index++
                      ) ...[
                        DiaryVideoPreview(
                          key: Key('chat-video-${entry.id}-$index'),
                          path: entry.videoPaths[index],
                          label: entry.videoPaths.length == 1
                              ? '视频'
                              : '视频 ${index + 1}',
                          onLongPress: onLongPress,
                        ),
                        if (index < entry.videoPaths.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showChatAvatar) ...[
            const SizedBox(width: 8),
            _ChatProfileAvatar(
              key: ValueKey('chat-profile-avatar-${entry.id}'),
              imagePath: profileAvatarPath,
              onTap: onAvatarTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationPreviewPainter extends CustomPainter {
  const _LocationPreviewPainter({
    required this.background,
    required this.road,
    required this.line,
  });

  final Color background;
  final Color road;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);
    final majorRoad = Paint()
      ..color = road
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final minorRoad = Paint()
      ..color = line.withValues(alpha: .72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paths = [
      Path()
        ..moveTo(-20, size.height * .25)
        ..lineTo(size.width * .43, size.height * .52)
        ..lineTo(size.width + 20, size.height * .38),
      Path()
        ..moveTo(size.width * .24, -15)
        ..lineTo(size.width * .36, size.height * .48)
        ..lineTo(size.width * .25, size.height + 15),
      Path()
        ..moveTo(size.width * .75, -15)
        ..lineTo(size.width * .64, size.height * .57)
        ..lineTo(size.width * .85, size.height + 15),
    ];
    for (final path in paths) {
      canvas.drawPath(path, majorRoad);
      canvas.drawPath(path, minorRoad);
    }
  }

  @override
  bool shouldRepaint(covariant _LocationPreviewPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.road != road ||
      oldDelegate.line != line;
}

class _ChatImageMessage extends StatelessWidget {
  const _ChatImageMessage({
    required this.entry,
    required this.onLongPress,
    required this.onAvatarTap,
    required this.showChatAvatar,
    required this.profileAvatarPath,
  });

  final DiaryEntry entry;
  final VoidCallback onLongPress;
  final VoidCallback onAvatarTap;
  final bool showChatAvatar;
  final String? profileAvatarPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
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
          ),
          if (showChatAvatar) ...[
            const SizedBox(width: 8),
            _ChatProfileAvatar(
              key: ValueKey('chat-profile-avatar-${entry.id}'),
              imagePath: profileAvatarPath,
              onTap: onAvatarTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatProfileAvatar extends StatelessWidget {
  const _ChatProfileAvatar({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '打开我的页面',
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: DiaryAvatar(imagePath: imagePath, size: 40),
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

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({
    required this.focusNode,
    required this.onSend,
    this.onSendLocation,
    this.pickLocation,
    this.amapAndroidKey = '',
    required this.onSent,
    required this.onOpenEditor,
    required this.onImportAttachments,
    this.pickGalleryPhotos,
    this.pickCameraPhoto,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.onLoadDraft,
    this.onSaveDraft,
    this.onClearDraft,
  });

  final FocusNode focusNode;
  final ChatMessageSender onSend;
  final Future<void> Function(DiaryPlace place)? onSendLocation;
  final Future<DiaryPlace?> Function()? pickLocation;
  final String amapAndroidKey;
  final VoidCallback onSent;
  final VoidCallback onOpenEditor;
  final Future<List<String>> Function(List<String> paths) onImportAttachments;
  final Future<List<String>> Function(int maxAssets)? pickGalleryPhotos;
  final Future<String?> Function()? pickCameraPhoto;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<DraftPayload?> Function(String id)? onLoadDraft;
  final Future<void> Function(DraftPayload draft)? onSaveDraft;
  final Future<void> Function(String id)? onClearDraft;

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer>
    with WidgetsBindingObserver {
  static const _draftId = 'chat-composer';
  final _controller = TextEditingController();
  final _imagePaths = <String>[];
  final _audioPaths = <String>[];
  final _videoPaths = <String>[];
  _ChatMood? _selectedMood;
  bool _isSending = false;
  bool _isImporting = false;
  Timer? _draftTimer;
  Future<void> _draftWrites = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final load = widget.onLoadDraft;
    if (!mounted || load == null) return;
    final draft = await load(_draftId);
    if (!mounted || draft == null || _hasDraft) return;
    final payload = draft.payload;
    _controller.text = payload['content'] is String
        ? payload['content'] as String
        : '';
    _imagePaths.addAll(_draftPaths(payload['imagePaths']));
    _audioPaths.addAll(_draftPaths(payload['audioPaths']));
    _videoPaths.addAll(_draftPaths(payload['videoPaths']));
    final moodLabel = payload['moodLabel'];
    _selectedMood = moodLabel is String ? _ChatMood.forLabel(moodLabel) : null;
    if (_hasDraft) setState(() {});
  }

  List<String> _draftPaths(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  void _scheduleDraftSave() {
    if (widget.onSaveDraft == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _persistDraft);
  }

  void _persistDraft() {
    if (widget.onSaveDraft == null) return;
    final content = _controller.text;
    final images = List<String>.of(_imagePaths);
    final audio = List<String>.of(_audioPaths);
    final videos = List<String>.of(_videoPaths);
    final moodLabel = _selectedMood?.label;
    _draftWrites = _draftWrites
        .then((_) async {
          if (content.trim().isEmpty &&
              images.isEmpty &&
              audio.isEmpty &&
              videos.isEmpty &&
              moodLabel == null) {
            await widget.onClearDraft?.call(_draftId);
          } else {
            await widget.onSaveDraft!(
              DraftPayload(
                id: _draftId,
                payload: {
                  'content': content,
                  'imagePaths': images,
                  'audioPaths': audio,
                  'videoPaths': videos,
                  'moodLabel': moodLabel,
                },
                updatedAt: DateTime.now(),
              ),
            );
          }
        })
        .catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _draftTimer?.cancel();
      _persistDraft();
    }
  }

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
    WidgetsBinding.instance.removeObserver(this);
    if (_draftTimer?.isActive == true) _persistDraft();
    _draftTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showAddMenu() async {
    if (_isSending || _isImporting) return;
    final choice = await showModalBottomSheet<_ChatAttachmentAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('从相册添加图片'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.image),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('拍照'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.imageCamera),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('从相册添加视频'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.videoGallery),
              ),
              ListTile(
                leading: const Icon(Icons.video_camera_back_outlined),
                title: const Text('录制视频'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.videoCamera),
              ),
              ListTile(
                leading: const Icon(Icons.mic_none_outlined),
                title: const Text('录音'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.audio),
              ),
              if (widget.onSendLocation != null &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('位置'),
                  onTap: () =>
                      Navigator.pop(context, _ChatAttachmentAction.location),
                ),
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('写完整日记'),
                onTap: () =>
                    Navigator.pop(context, _ChatAttachmentAction.entry),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _ChatAttachmentAction.image:
        await _pickImages();
        break;
      case _ChatAttachmentAction.imageCamera:
        await _takePhoto();
        break;
      case _ChatAttachmentAction.videoGallery:
        await _pickVideo(ImageSource.gallery);
        break;
      case _ChatAttachmentAction.videoCamera:
        await _pickVideo(ImageSource.camera);
        break;
      case _ChatAttachmentAction.audio:
        await _recordVoice();
        break;
      case _ChatAttachmentAction.location:
        await _sendLocation();
        break;
      case _ChatAttachmentAction.entry:
        widget.onOpenEditor();
        break;
    }
  }

  Future<void> _sendLocation() async {
    if (widget.onSendLocation == null || widget.pickLocation == null) return;
    try {
      DiaryPlace? place;
      widget.onExternalActivityStart?.call();
      try {
        place = await widget.pickLocation!();
      } finally {
        widget.onExternalActivityEnd?.call();
      }
      if (!mounted || place == null) return;
      if (!place.isValid) {
        _showMessage('选择的位置无效，请重试');
        return;
      }
      await widget.onSendLocation!(place);
      widget.onSent();
    } catch (_) {
      if (mounted) _showMessage('位置没有发送成功，请重试');
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

  Future<void> _takePhoto() async {
    final remaining = 9 - _imagePaths.length;
    if (remaining <= 0) {
      _showMessage('一次最多添加 9 张照片');
      return;
    }
    await _importExternal(_pickCameraPhoto, _imagePaths);
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

  Future<List<String>> _pickCameraPhoto() async {
    final overriddenPicker = widget.pickCameraPhoto;
    final path = overriddenPicker == null
        ? (await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 92,
          ))?.path
        : await overriddenPicker();
    return path == null ? const [] : [path];
  }

  Future<void> _pickVideo(ImageSource source) async {
    await _importExternal(() async {
      final video = await ImagePicker().pickVideo(source: source);
      return video == null ? const [] : [video.path];
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
      _scheduleDraftSave();
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
          _scheduleDraftSave();
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
    _scheduleDraftSave();
  }

  Future<void> _send() async {
    if (!_hasDraft || _isSending || _isImporting) return;
    final content = _controller.text;
    final imagePaths = List<String>.of(_imagePaths);
    final audioPaths = List<String>.of(_audioPaths);
    final videoPaths = List<String>.of(_videoPaths);
    final selectedMood = _selectedMood;
    _draftTimer?.cancel();
    setState(() {
      _isSending = true;
      _controller.clear();
      _imagePaths.clear();
      _audioPaths.clear();
      _videoPaths.clear();
      _selectedMood = null;
    });
    try {
      await widget.onSend(
        content,
        imagePaths,
        audioPaths,
        videoPaths,
        selectedMood?.value ?? .5,
        selectedMood?.label,
      );
      _draftTimer?.cancel();
      await _draftWrites;
      try {
        await widget.onClearDraft?.call(_draftId);
      } catch (_) {
        if (mounted) _showMessage('消息已发送，草稿清理失败');
      }
      if (!mounted) return;
      if (_hasDraft) _persistDraft();
      if (!widget.focusNode.hasFocus) widget.onSent();
    } catch (_) {
      if (mounted) {
        setState(() {
          final nextContent = _controller.text;
          _controller.text = nextContent.isEmpty
              ? content
              : content.isEmpty
              ? nextContent
              : '$content\n$nextContent';
          _imagePaths.insertAll(0, imagePaths);
          _audioPaths.insertAll(0, audioPaths);
          _videoPaths.insertAll(0, videoPaths);
          _selectedMood ??= selectedMood;
        });
        _scheduleDraftSave();
        _showMessage('发送失败，请稍后重试');
      }
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
    final sendButtonColor = Theme.of(context).brightness == Brightness.dark
        ? Color.alphaBlend(const Color(0x59000000), colors.terracotta)
        : colors.terracotta;
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('chat-composer'),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
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
                onRemoveImage: (path) {
                  setState(() => _imagePaths.remove(path));
                  _scheduleDraftSave();
                },
                onRemoveAudio: (path) {
                  setState(() => _audioPaths.remove(path));
                  _scheduleDraftSave();
                },
                onRemoveVideo: (path) {
                  setState(() => _videoPaths.remove(path));
                  _scheduleDraftSave();
                },
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('chat-record-button'),
                  tooltip: '录音',
                  onPressed: _isSending ? null : _recordVoice,
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  icon: const Icon(Icons.mic_none_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    key: const Key('chat-input-surface'),
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    decoration: BoxDecoration(
                      color: colors.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.line),
                    ),
                    child: TextField(
                      key: const Key('chat-message-field'),
                      controller: _controller,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.center,
                      selectionControls: _chatSelectionControls,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.ink,
                        fontSize: 16,
                        height: 1.15,
                      ),
                      textInputAction: TextInputAction.send,
                      onEditingComplete: () {},
                      onSubmitted: (_) => unawaited(_send()),
                      onChanged: (_) {
                        setState(() {});
                        _scheduleDraftSave();
                      },
                      decoration: const InputDecoration(
                        hintText: '写点什么…',
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  key: const Key('chat-mood-button'),
                  tooltip: _selectedMood == null
                      ? '记录心情'
                      : '心情：${_selectedMood!.label}',
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
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
                AnimatedSize(
                  duration: DiaryMotion.duration(
                    context,
                    _chatActionTransitionDuration,
                  ),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: DiaryMotion.duration(
                      context,
                      _chatActionTransitionDuration,
                    ),
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
                      clipBehavior: Clip.none,
                      children: [
                        for (final child in previousChildren)
                          Positioned(right: 0, top: 0, child: child),
                        ?currentChild,
                      ],
                    ),
                    child:
                        _hasTypedText ||
                            _hasAttachments ||
                            _hasMood ||
                            _isSending
                        ? FilledButton(
                            key: const Key('chat-send-button'),
                            onPressed: _isSending || _isImporting
                                ? null
                                : _send,
                            style: FilledButton.styleFrom(
                              backgroundColor: sendButtonColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: sendButtonColor,
                              disabledForegroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(52, 40),
                              maximumSize: const Size(52, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: DiaryMotion.duration(
                                context,
                                _chatActionFeedbackDuration,
                              ),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _isSending
                                  ? SizedBox(
                                      key: const ValueKey(
                                        'chat-sending-indicator',
                                      ),
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
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
                              width: 44,
                              height: 44,
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
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
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final path = videoPaths[index];
                  return SizedBox(
                    width: 132,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DiaryVideoPreview(
                            key: Key('chat-selected-video-$index'),
                            path: path,
                            label: videoPaths.length == 1
                                ? '待发送视频'
                                : '待发送视频 ${index + 1}',
                            compact: true,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton.filledTonal(
                            tooltip: '移除视频 ${index + 1}',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            iconSize: 16,
                            onPressed: () => onRemoveVideo(path),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

enum _ChatEntryAction { edit, delete }

enum _ChatAttachmentAction {
  image,
  imageCamera,
  videoGallery,
  videoCamera,
  audio,
  location,
  entry,
}

enum ChatPageDestination { timeline, calendar, media, insights, profile }
