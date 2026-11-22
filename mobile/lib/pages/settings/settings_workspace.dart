import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';

class SearchableSetting {
  const SearchableSetting({required this.keywords, required this.child});

  final String keywords;
  final Widget child;
}

class SettingsGroup {
  const SettingsGroup({
    required this.id,
    required this.title,
    required this.label,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final String label;
  final IconData icon;
  final List<SearchableSetting> items;
}

class SettingsWorkspace extends StatefulWidget {
  const SettingsWorkspace({
    required this.groups,
    required this.keyboardVisible,
    super.key,
  });

  final List<SettingsGroup> groups;
  final bool keyboardVisible;

  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _groupKeys = <String, GlobalKey>{};
  String _query = '';
  String? _selectedGroup;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _matches(String text) {
    final normalized = text.toLowerCase();
    return _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(normalized.contains);
  }

  void _setQuery(String value) {
    setState(() {
      _query = value.trim();
      _selectedGroup = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _clearSearch() {
    _search.clear();
    _setQuery('');
  }

  void _jumpToGroup(SettingsGroup group) {
    FocusManager.instance.primaryFocus?.unfocus();
    _search.clear();
    setState(() {
      _query = '';
      _selectedGroup = group.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sectionContext = _groupKeys[group.id]?.currentContext;
      if (sectionContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          sectionContext,
          alignment: 0,
          duration: DiaryMotion.duration(context, DiaryMotion.standard),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final keyboardVisible = widget.keyboardVisible;
    final sections = <Widget>[];
    for (final group in widget.groups) {
      final wholeGroup = _query.isEmpty || _matches(group.title);
      final items = group.items
          .where((item) => wholeGroup || _matches(item.keywords))
          .toList(growable: false);
      if (items.isEmpty) continue;
      sections.add(
        SettingsSection(
          key: _groupKeys.putIfAbsent(group.id, GlobalKey.new),
          sectionId: group.id,
          title: group.title,
          children: [for (final item in items) item.child],
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('settings-search'),
                      controller: _search,
                      onChanged: _setQuery,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: '搜索设置，例如模型、字体、同步',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.mutedInk),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('settings-search-clear'),
                                tooltip: '清除搜索',
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: colors.surface,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (!keyboardVisible) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        key: const Key('settings-group-strip'),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 6,
                          children: [
                            for (final group in widget.groups)
                              InputChip(
                                key: ValueKey('settings-group-${group.id}'),
                                avatar: Icon(group.icon, size: 16),
                                label: Text(group.label),
                                tooltip: group.title,
                                selected: _selectedGroup == group.id,
                                showCheckmark: false,
                                visualDensity: const VisualDensity(
                                  vertical: -1,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                onPressed: () => _jumpToGroup(group),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const Key('settings-list'),
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  children: [
                    if (sections.isEmpty)
                      Padding(
                        key: const Key('settings-search-empty'),
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              color: colors.mutedInk,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text('没有找到相关设置'),
                            const SizedBox(height: 10),
                            TextButton(
                              key: const Key('settings-search-clear-empty'),
                              onPressed: _clearSearch,
                              child: const Text('清除搜索'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(children: sections),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.sectionId,
    required this.title,
    required this.children,
    this.flatRows = true,
    super.key,
  });

  final String sectionId;
  final String title;
  final List<Widget> children;
  final bool flatRows;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                key: ValueKey('settings-section-$sectionId'),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.terracotta),
              ),
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (flatRows && index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: colors.line.withValues(alpha: .6),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
