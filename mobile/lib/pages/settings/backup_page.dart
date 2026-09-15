import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    required this.entries,
    required this.onImport,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    super.key,
  });

  final List<DiaryEntry> entries;
  final Future<void> Function(List<DiaryEntry> entries) onImport;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('备份与恢复'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
        children: [
          Text(
            'KEEP YOUR PAGES SAFE',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
          ),
          const SizedBox(height: 9),
          Text('备份与恢复', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '数据属于你。用开放的 JSON 格式，随时带走你的日记。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 23),
          _BackupAction(
            icon: Icons.upload_outlined,
            title: '导出日记备份',
            subtitle: '${widget.entries.length} 篇日记 · JSON 格式',
            onTap: _export,
          ),
          const SizedBox(height: 10),
          _BackupAction(
            icon: Icons.download_outlined,
            title: '导入日记备份',
            subtitle: '从 JSON 文件恢复或迁移日记',
            onTap: _import,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: colors.sage, size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '备份不会上传到服务器。导出内容包含正文、分类、标签、心情和附件路径。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.entries.map((entry) => entry.toJson()).toList());
    widget.onExternalActivityStart?.call();
    try {
      await SharePlus.instance.share(
        ShareParams(subject: '我的日记备份.json', text: json),
      );
    } finally {
      widget.onExternalActivityEnd?.call();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _import() async {
    widget.onExternalActivityStart?.call();
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } finally {
      widget.onExternalActivityEnd?.call();
    }
    if (!mounted || result == null || result.files.single.bytes == null) return;
    setState(() => _busy = true);
    try {
      final decoded = jsonDecode(utf8.decode(result.files.single.bytes!));
      if (decoded is! List) throw const FormatException();
      final entries = decoded
          .whereType<Map>()
          .map((item) => DiaryEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      await widget.onImport(entries);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入 ${entries.length} 篇日记')));
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('文件格式不正确，请选择日记 JSON 备份')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _BackupAction extends StatelessWidget {
  const _BackupAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: colors.terracottaSoft,
          child: Icon(icon, color: colors.terracotta),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
      ),
    );
  }
}
