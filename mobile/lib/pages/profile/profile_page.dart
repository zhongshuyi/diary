import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/widgets/diary_avatar.dart';
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
    this.onOpenMedia,
    this.onOpenInsights,
    this.favoriteCount = 0,
    this.onOpenFavorites,
    this.conflictCount = 0,
    this.onOpenConflicts,
    this.syncState = const SyncState(),
    this.onOpenSyncSettings,
    this.profileAvatarPath,
    this.onPickAvatar,
    this.onClearAvatar,
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
  final VoidCallback? onOpenMedia;
  final VoidCallback? onOpenInsights;
  final int favoriteCount;
  final VoidCallback? onOpenFavorites;
  final int conflictCount;
  final VoidCallback? onOpenConflicts;
  final SyncState syncState;
  final VoidCallback? onOpenSyncSettings;
  final String? profileAvatarPath;
  final Future<void> Function()? onPickAvatar;
  final Future<void> Function()? onClearAvatar;
  final bool desktopLayout;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    if (!desktopLayout) {
      return _MobileProfileWorkspace(
        entryCount: entryCount,
        trashCount: trashCount,
        favoriteCount: favoriteCount,
        conflictCount: conflictCount,
        syncState: syncState,
        onOpenFavorites: onOpenFavorites,
        onOpenMedia: onOpenMedia,
        onOpenInsights: onOpenInsights,
        onOpenCategories: onOpenCategories,
        onOpenRecycle: onOpenRecycle,
        onOpenSyncSettings: onOpenSyncSettings ?? onOpenSettings,
        onOpenBackup: onOpenBackup,
        onOpenConflicts: onOpenConflicts,
        onOpenSettings: onOpenSettings,
        onOpenAbout: onOpenAbout,
        profileAvatarPath: profileAvatarPath,
        onPickAvatar: onPickAvatar,
        onClearAvatar: onClearAvatar,
      );
    }
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
                    DiaryAvatar(
                      imagePath: profileAvatarPath,
                      size: 58,
                      onTap: onPickAvatar,
                      editIndicatorKey: const Key(
                        'profile-desktop-avatar-edit-indicator',
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
                            '先保存在本机 · 可按设置同步',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.onHero.withValues(alpha: .68),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if ((profileAvatarPath?.trim().isNotEmpty ?? false) &&
                        onClearAvatar != null)
                      IconButton(
                        key: const Key('profile-desktop-avatar-reset-button'),
                        tooltip: '恢复默认头像',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async => await onClearAvatar!.call(),
                        icon: Icon(Icons.restart_alt, color: colors.onHero),
                      )
                    else
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
              if (onOpenConflicts != null) ...[
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.sync_problem_outlined,
                  title: '同步冲突',
                  subtitle: conflictCount == 0
                      ? '双端数据保持一致'
                      : '$conflictCount 篇待确认',
                  onTap: onOpenConflicts!,
                ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileProfileWorkspace extends StatelessWidget {
  const _MobileProfileWorkspace({
    required this.entryCount,
    required this.trashCount,
    required this.favoriteCount,
    required this.conflictCount,
    required this.syncState,
    required this.onOpenFavorites,
    required this.onOpenMedia,
    required this.onOpenInsights,
    required this.onOpenCategories,
    required this.onOpenRecycle,
    required this.onOpenSyncSettings,
    required this.onOpenBackup,
    required this.onOpenConflicts,
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.profileAvatarPath,
    required this.onPickAvatar,
    required this.onClearAvatar,
  });

  final int entryCount;
  final int trashCount;
  final int favoriteCount;
  final int conflictCount;
  final SyncState syncState;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenMedia;
  final VoidCallback? onOpenInsights;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenRecycle;
  final VoidCallback onOpenSyncSettings;
  final VoidCallback onOpenBackup;
  final VoidCallback? onOpenConflicts;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final String? profileAvatarPath;
  final Future<void> Function()? onPickAvatar;
  final Future<void> Function()? onClearAvatar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MobileProfileHeader(
                avatarPath: profileAvatarPath,
                onPickAvatar: onPickAvatar,
                onClearAvatar: onClearAvatar,
              ),
              const SizedBox(height: 26),
              _ProfileSection(
                title: '回看',
                children: [
                  if (onOpenFavorites != null)
                    _ProfileTile(
                      icon: Icons.bookmark_outline,
                      title: '收藏夹',
                      subtitle: favoriteCount == 0
                          ? '还没有收藏的日记'
                          : '$favoriteCount 篇已收藏',
                      onTap: onOpenFavorites!,
                    ),
                  if (onOpenMedia != null)
                    _ProfileTile(
                      icon: Icons.collections_outlined,
                      title: '媒体库',
                      subtitle: '照片、视频和语音都在这里',
                      onTap: onOpenMedia!,
                    ),
                  if (onOpenInsights != null)
                    _ProfileTile(
                      icon: Icons.auto_graph_outlined,
                      title: '洞察',
                      subtitle: '看看你的记录习惯与情绪变化',
                      onTap: onOpenInsights!,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _ProfileSection(
                title: '整理',
                children: [
                  _ProfileTile(
                    icon: Icons.sell_outlined,
                    title: '分类与标签',
                    subtitle: '整理你常写下的主题',
                    onTap: onOpenCategories,
                  ),
                  _ProfileTile(
                    icon: Icons.delete_outline,
                    title: '回收站',
                    subtitle: trashCount == 0
                        ? '这里还没有被丢弃的日记'
                        : '$trashCount 篇待处理',
                    onTap: onOpenRecycle,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _ProfileSection(
                title: '数据',
                children: [
                  _ProfileTile(
                    icon: _syncIcon(syncState.status),
                    title: '同步',
                    subtitle: _syncSubtitle(syncState, conflictCount),
                    onTap: onOpenSyncSettings,
                  ),
                  _ProfileTile(
                    icon: Icons.import_export_outlined,
                    title: '备份与恢复',
                    subtitle: '用 JSON 保存或迁移你的日记',
                    onTap: onOpenBackup,
                  ),
                  if (conflictCount > 0 && onOpenConflicts != null)
                    _ProfileTile(
                      icon: Icons.sync_problem_outlined,
                      title: '同步冲突',
                      subtitle: '$conflictCount 篇待确认',
                      onTap: onOpenConflicts!,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _ProfileSection(
                title: '应用',
                children: [
                  _ProfileTile(
                    icon: Icons.tune_outlined,
                    title: '偏好设置',
                    subtitle: '主题、启动页与阅读体验',
                    onTap: onOpenSettings,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _ProfileSection(
                title: '关于',
                children: [
                  _ProfileTile(
                    icon: Icons.auto_awesome_outlined,
                    title: '关于此刻',
                    subtitle: '版本、设计理念与隐私说明',
                    onTap: onOpenAbout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileProfileHeader extends StatelessWidget {
  const _MobileProfileHeader({
    required this.avatarPath,
    required this.onPickAvatar,
    required this.onClearAvatar,
  });

  final String? avatarPath;
  final Future<void> Function()? onPickAvatar;
  final Future<void> Function()? onClearAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final hasAvatar = avatarPath?.trim().isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DiaryPageIntro(
          eyebrow: 'A QUIET PLACE FOR YOU',
          title: '我的空间',
          description: '管理你的记录、偏好与私人边界。',
        ),
        const SizedBox(height: 24),
        Container(
          key: const Key('profile-identity-panel'),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DiaryAvatar(
                key: const Key('profile-avatar-button'),
                imagePath: avatarPath,
                size: 72,
                onTap: onPickAvatar,
                editIndicatorKey: const Key('profile-avatar-edit-indicator'),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '写给自己的日记',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '先保存在本机 · 轻触头像即可更换',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
                    ),
                  ],
                ),
              ),
              if (hasAvatar && onClearAvatar != null)
                IconButton(
                  key: const Key('profile-avatar-reset-button'),
                  tooltip: '恢复默认头像',
                  onPressed: () async => await onClearAvatar!.call(),
                  icon: Icon(Icons.restart_alt, color: colors.mutedInk),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        ...children,
      ],
    );
  }
}

String _syncSubtitle(SyncState state, int conflictCount) {
  return switch (state.status) {
    SyncStatus.syncing => '正在同步',
    SyncStatus.synced => '已同步',
    SyncStatus.pending => '待同步',
    SyncStatus.conflict => conflictCount > 0 ? '$conflictCount 篇待确认' : '有同步冲突',
    SyncStatus.failed => '同步失败 · 点击查看设置',
    SyncStatus.idle => '本地优先 · 未连接服务器',
  };
}

IconData _syncIcon(SyncStatus status) {
  return switch (status) {
    SyncStatus.syncing => Icons.sync,
    SyncStatus.synced => Icons.cloud_done_outlined,
    SyncStatus.pending => Icons.cloud_upload_outlined,
    SyncStatus.conflict => Icons.warning_amber_outlined,
    SyncStatus.failed => Icons.cloud_off_outlined,
    SyncStatus.idle => Icons.cloud_outlined,
  };
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
