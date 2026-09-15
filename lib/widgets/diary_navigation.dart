import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class DiarySideNavigation extends StatelessWidget {
  const DiarySideNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.onNewEntry,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onNewEntry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(20, 27, 16, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: colors.butter,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'MY / DIARY',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('你的日记本', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DiaryNavigationItem(
            icon: Icons.view_agenda_outlined,
            label: '时间线',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          DiaryNavigationItem(
            icon: Icons.calendar_month_outlined,
            label: '日历',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          DiaryNavigationItem(
            icon: Icons.collections_outlined,
            label: '媒体库',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          DiaryNavigationItem(
            icon: Icons.auto_graph_outlined,
            label: '洞察',
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
          DiaryNavigationItem(
            icon: Icons.person_outline,
            label: '我的',
            selected: selectedIndex == 4,
            onTap: () => onSelected(4),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNewEntry,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('写一篇'),
            ),
          ),
          const SizedBox(height: 14),
          Text('OFFLINE FIRST', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class DiaryNavigationItem extends StatelessWidget {
  const DiaryNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: selected ? colors.ink : Colors.transparent,
        leading: Icon(
          icon,
          size: 19,
          color: selected ? colors.surface : colors.mutedInk,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? colors.surface : colors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class DiaryBottomNavigation extends StatelessWidget {
  const DiaryBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      backgroundColor: colors.surface,
      indicatorColor: colors.sage,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.view_agenda_outlined),
          selectedIcon: Icon(Icons.view_agenda),
          label: '时间线',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: '日历',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_outlined),
          selectedIcon: Icon(Icons.collections),
          label: '媒体库',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_graph_outlined),
          selectedIcon: Icon(Icons.auto_graph),
          label: '洞察',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }
}
