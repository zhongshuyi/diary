import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      home: const QuillTestPage(),
    );
  }
}

class QuillTestPage extends StatefulWidget {
  const QuillTestPage({super.key});

  @override
  State<QuillTestPage> createState() => _QuillTestPageState();
}

class _QuillTestPageState extends State<QuillTestPage> {
  final quill.QuillController _controller = quill.QuillController.basic();

  @override
  void initState() {
    super.initState();
    _controller.document.insert(0, '富文本测试\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDeltaJson() {
    final json = jsonEncode(_controller.document.toDelta().toJson());
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delta JSON'),
          content: SelectableText(json),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('富文本测试'),
        actions: [
          IconButton(
            onPressed: _showDeltaJson,
            icon: const Icon(Icons.code),
            tooltip: '查看 Delta JSON',
          ),
        ],
      ),
      body: Column(
        children: [
          quill.QuillSimpleToolbar(
            controller: _controller,
            config: const quill.QuillSimpleToolbarConfig(),
          ),
          Expanded(
            child: quill.QuillEditor.basic(
              controller: _controller,
              config: const quill.QuillEditorConfig(),
            ),
          ),
        ],
      ),
    );
  }
}
