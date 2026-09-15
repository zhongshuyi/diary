import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/widgets/page_intro.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.entryCount,
    required this.trashCount,
    required this.onOpenRecycle,
    required this.onOpenSettings,
    required this.onOpenCategories,
    required this.onOpenBackup,
    required this.onOpenAbout,
    this.desktopLayout = false,
    super.key,
  });

  final int entryCount;
  final int trashCount;
  final VoidCallback onOpenRecycle;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenBackup;
  final VoidCallback onOpenAbout;
  final bool desktopLayout;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DiaryPageIntro(
                eyebrow: 'A QUIET PLACE FOR YOU',
                title: '我的空间',
                description: '管理你的记录、偏好与私人边界。',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.hero,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.butter,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 29,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '写给自己的日记',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: colors.onHero),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '离线保存 · 只有你能看见',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.onHero.withValues(alpha: .68),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.verified_user_outlined, color: colors.sage),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProfileTile(
                icon: Icons.delete_outline,
                title: '回收站',
                subtitle: trashCount == 0 ? '这里还没有被丢弃的日记' : '$trashCount 篇待处理',
                onTap: onOpenRecycle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      number: '$entryCount',
                      label: '篇日记',
                      tint: colors.sage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountCard(
                      number: '$trashCount',
                      label: '待处理',
                      tint: colors.terracottaSoft,
                    ),
                  ),
                ],
              ),
              if (!desktopLayout) ...[
                const SizedBox(height: 25),
                Text('管理', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 9),
                _ProfileTile(
                  icon: Icons.tune_outlined,
                  title: '偏好设置',
                  subtitle: '主题、启动页与阅读体验',
                  onTap: onOpenSettings,
                ),
                _ProfileTile(
                  icon: Icons.sell_outlined,
                  title: '分类与标签',
                  subtitle: '整理你常写下的主题',
                  onTap: onOpenCategories,
                ),
                _ProfileTile(
                  icon: Icons.import_export_outlined,
                  title: '备份与恢复',
                  subtitle: '用 JSON 保存或迁移你的日记',
                  onTap: onOpenBackup,
                ),
                const SizedBox(height: 25),
                Text('关于', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 9),
                _ProfileTile(
                  icon: Icons.auto_awesome_outlined,
                  title: '关于此刻',
                  subtitle: '版本、设计理念与隐私说明',
                  onTap: onOpenAbout,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.number,
    required this.label,
    required this.tint,
  });

  final String number;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(number, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.transparent,
        splashColor: colors.terracotta.withValues(alpha: .12),
        hoverColor: colors.terracotta.withValues(alpha: .06),
        focusColor: colors.terracotta.withValues(alpha: .08),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.terracotta, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
      ),
    );
  }
}
