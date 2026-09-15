import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                const ListTile(title: Text('版本'), trailing: Text('1.0.0')),
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
