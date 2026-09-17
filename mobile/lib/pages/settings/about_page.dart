import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/update_service.dart';

typedef AppVersionLoader = Future<String> Function();

Future<String> loadCurrentAppVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version.trim();
    if (version.isNotEmpty) return version;
  } on Object {
    // Keep the compile-time fallback usable in tests and unsupported hosts.
  }
  return currentAppVersion;
}

class AboutPage extends StatefulWidget {
  const AboutPage({
    this.updateService,
    this.loadCurrentVersion = loadCurrentAppVersion,
    super.key,
  });

  final AppUpdateService? updateService;
  final AppVersionLoader loadCurrentVersion;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final AppUpdateService _updateService =
      widget.updateService ?? AppUpdateService();
  AppUpdateResult? _update;
  String? _message;
  bool _checking = false;
  String _currentVersion = currentAppVersion;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await widget.loadCurrentVersion();
    if (mounted && version.trim().isNotEmpty) {
      setState(() => _currentVersion = version.trim());
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = null;
      _update = null;
    });
    try {
      final result = await _updateService.check(
        platform: 'mobile',
        currentVersion: _currentVersion,
      );
      if (!mounted) return;
      setState(() {
        _update = result;
        _message = result.hasUpdate
            ? '发现新版本 ${result.latestVersion}'
            : '当前已是最新版本';
      });
    } on UpdateCheckException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) setState(() => _message = '检查更新失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openDownload() async {
    final url = _update?.downloadUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      setState(() => _message = '下载地址无效');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _message = '无法打开下载地址');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('关于此刻'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 35),
        children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.hero,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: colors.butter,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '此刻 · diary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 7),
          Center(
            child: Text(
              '把今天留给自己',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 27),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '这是一个离线优先的私人日记。没有信息流，没有点赞，也不催你更新。你可以用文字、Markdown 或富文本记录生活，然后在日历和洞察里慢慢看见自己的轨迹。',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.ink, height: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('版本'),
                  subtitle: Text('当前版本 $_currentVersion'),
                  trailing: TextButton(
                    onPressed: _checking ? null : _checkForUpdate,
                    child: Text(_checking ? '检查中…' : '检查更新'),
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_message!),
                    ),
                  ),
                if (_update?.hasUpdate == true) ...[
                  if (_update!.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('更新说明：${_update!.notes}'),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _openDownload,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('前往下载'),
                      ),
                    ),
                  ),
                ],
                const ListTile(
                  title: Text('存储'),
                  trailing: Text('Isar · 离线优先'),
                ),
                const ListTile(title: Text('隐私'), trailing: Text('数据留在设备上')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '感谢你把一些真实的时刻交给这里。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
