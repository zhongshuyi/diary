import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';

class SharePage extends StatefulWidget {
  const SharePage({
    required this.entry,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    super.key,
  });

  final DiaryEntry entry;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  bool _includeMeta = true;

  String get _shareText {
    final buffer = StringBuffer(widget.entry.title);
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(widget.entry.contentText);
    if (_includeMeta) {
      buffer.writeln();
      buffer.writeln();
      buffer.write(
        '${diaryDateLabel(widget.entry.createdAt)} · ${widget.entry.category}',
      );
      if (widget.entry.tags.isNotEmpty) {
        buffer.write(' · ${widget.entry.tags.map((tag) => '#$tag').join(' ')}');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiaryPalette.paper,
      appBar: AppBar(
        backgroundColor: DiaryPalette.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('分享日记'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A SMALL PIECE OF TODAY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DiaryPalette.terracotta,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '把这一页交给你信任的人。',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          widget.entry.contentText,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: DiaryPalette.ink, height: 1.8),
                        ),
                        if (_includeMeta) ...[
                          const SizedBox(height: 18),
                          Text(
                            '${diaryDateLabel(widget.entry.createdAt)} · ${widget.entry.category}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile.adaptive(
                    title: const Text('附带日期与标签'),
                    subtitle: const Text('分享时保留这篇日记的上下文'),
                    value: _includeMeta,
                    onChanged: (value) => setState(() => _includeMeta = value),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('打开系统分享'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回详情'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    widget.onExternalActivityStart?.call();
    try {
      await SharePlus.instance.share(
        ShareParams(subject: widget.entry.title, text: _shareText),
      );
    } finally {
      widget.onExternalActivityEnd?.call();
    }
  }
}
