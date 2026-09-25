import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/data/diary_backup_service.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/portable_backup_exporter.dart';
import 'package:diary/domain/diary_entry.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    required this.entries,
    required this.onImport,
    this.onImportPackage,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.pickBackupBytes,
    super.key,
  });

  final List<DiaryEntry> entries;
  final Future<void> Function(List<DiaryEntry> entries) onImport;
  final Future<void> Function(ImportPackage package)? onImportPackage;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<List<int>?> Function()? pickBackupBytes;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  static const _backupService = DiaryBackupService();

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
            '将日记和照片一起保存为 ZIP，随时可以恢复。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 23),
          _BackupAction(
            icon: Icons.archive_outlined,
            title: '保存完整备份',
            subtitle: '${widget.entries.length} 篇日记 · ZIP 含本地附件',
            onTap: _exportZip,
          ),
          const SizedBox(height: 10),
          _BackupAction(
            icon: Icons.upload_outlined,
            title: '分享 JSON 文本',
            subtitle: '仅记录和媒体路径，不含附件文件',
            onTap: _export,
          ),
          const SizedBox(height: 10),
          _BackupAction(
            icon: Icons.download_outlined,
            title: '导入日记备份',
            subtitle: '选择 ZIP 或 JSON 文件',
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
                      '完整 ZIP 保存在你选的位置，包含正文、分类、标签、心情和本机附件。',
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

  Future<void> _exportZip() async {
    setState(() => _busy = true);
    try {
      final bytes = await PortableBackupExporter().export(widget.entries);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 14);
      widget.onExternalActivityStart?.call();
      final saved = await FilePicker.saveFile(
        dialogTitle: '保存日记完整备份',
        fileName: 'diary-backup-$stamp.zip',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('完整备份已保存')));
      }
    } on FileSystemException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('有附件无法读取，完整备份未保存')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存备份失败，请重试')));
      }
    } finally {
      widget.onExternalActivityEnd?.call();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    widget.onExternalActivityStart?.call();
    FilePickerResult? result;
    List<int>? injectedBytes;
    try {
      if (widget.pickBackupBytes != null) {
        injectedBytes = await widget.pickBackupBytes!();
      } else {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json', 'zip'],
          withData: true,
        );
      }
    } finally {
      widget.onExternalActivityEnd?.call();
    }
    final bytes = injectedBytes ?? result?.files.single.bytes;
    if (!mounted || bytes == null) return;
    setState(() => _busy = true);
    try {
      final extension = result?.files.single.extension?.toLowerCase();
      final package = extension == 'zip'
          ? _backupService.importZip(bytes)
          : null;
      final entries =
          package?.entries ??
          (() {
            final decoded = jsonDecode(utf8.decode(bytes));
            if (decoded is! List) throw const FormatException();
            return decoded
                .whereType<Map>()
                .map(
                  (item) =>
                      DiaryEntry.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false);
          })();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入备份？'),
          content: Text(
            package == null
                ? '将导入 ${entries.length} 篇日记，并替换当前本地日记。'
                : '将合并 ${entries.length} 篇日记到本机；相同 ID 的现有日记会保留。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (package != null && widget.onImportPackage != null) {
        await widget.onImportPackage!(package);
      } else {
        await widget.onImport(entries);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              package == null ? '已导入 ${entries.length} 篇日记' : '备份导入完成',
            ),
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份格式不正确或附件校验失败')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入失败，请检查备份文件和可用空间')));
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
