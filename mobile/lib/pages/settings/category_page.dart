import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    required this.categories,
    this.tags = const [],
    super.key,
  });

  final List<String> categories;
  final List<String> tags;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final List<String> _categories;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
    _tags = [...widget.tags];
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('分类与标签'),
        actions: [
          IconButton(
            onPressed: _addCategory,
            tooltip: '新增分类',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
        children: [
          Text(
            'NAME YOUR CHAPTERS',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
          ),
          const SizedBox(height: 9),
          Text('分类与标签', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('给不同的生活章节一个名字。', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 23),
          Card(
            child: Column(
              children: [
                for (final category in _categories)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: _colorFor(
                        _categories.indexOf(category),
                        colors,
                      ),
                      child: Icon(
                        Icons.folder_open_outlined,
                        size: 17,
                        color: colors.ink,
                      ),
                    ),
                    title: Text(category),
                    trailing: IconButton(
                      onPressed: () => _renameCategory(category),
                      icon: Icon(Icons.edit_outlined, color: colors.mutedInk),
                    ),
                  ),
                if (_categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('还没有分类'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '标签',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新增'),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _tags.isEmpty
                  ? const Text('还没有标签')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => InputChip(
                              label: Text('#$tag'),
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final name = await _askForName('新增分类');
    if (name != null && name.isNotEmpty && !_categories.contains(name)) {
      setState(() => _categories.add(name));
    }
  }

  Future<void> _renameCategory(String oldName) async {
    final name = await _askForName('重命名分类', initial: oldName);
    if (name != null && name.isNotEmpty && name != oldName) {
      setState(() => _categories[_categories.indexOf(oldName)] = name);
    }
  }

  Future<String?> _askForName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：读书'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _addTag() async {
    final name = await _askForName('新增标签');
    if (name != null && name.isNotEmpty && !_tags.contains(name)) {
      setState(() => _tags.add(name));
    }
  }
}

Color _colorFor(int index, DiaryThemeColors colors) => [
  colors.sage,
  colors.butter,
  colors.terracottaSoft,
  colors.lavender,
][index % 4];
