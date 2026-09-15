import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({required this.categories, super.key});

  final List<String> categories;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiaryPalette.paper,
      appBar: AppBar(
        backgroundColor: DiaryPalette.paper,
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
            ).textTheme.labelSmall?.copyWith(color: DiaryPalette.terracotta),
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
                      backgroundColor: _colorFor(_categories.indexOf(category)),
                      child: const Icon(
                        Icons.folder_open_outlined,
                        size: 17,
                        color: DiaryPalette.ink,
                      ),
                    ),
                    title: Text(category),
                    subtitle: Text('用于整理日记与回顾'),
                    trailing: IconButton(
                      onPressed: () => _renameCategory(category),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: DiaryPalette.mutedInk,
                      ),
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
          const SizedBox(height: 12),
          Text(
            '提示：新分类会从下一篇日记开始使用。',
            style: Theme.of(context).textTheme.bodyMedium,
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
}

Color _colorFor(int index) => [
  DiaryPalette.sage,
  DiaryPalette.butter,
  DiaryPalette.terracottaSoft,
  DiaryPalette.lavender,
][index % 4];
