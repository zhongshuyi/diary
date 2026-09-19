import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/quick_audio_recorder.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';
import 'package:diary/widgets/hold_to_record_button.dart';
import 'package:diary/widgets/media_kind.dart';
import 'package:diary/widgets/selected_photo_strip.dart';

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({
    required this.onSave,
    required this.onOpenEditor,
    required this.importPhotos,
    this.onSaveWithAudio,
    this.audioRecorder,
    this.pickPhotos,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.onLoadDraft,
    this.onSaveDraft,
    this.onClearDraft,
    super.key,
  });

  final Future<void> Function(String content, List<String> imagePaths) onSave;
  final Future<void> Function(
    String content,
    List<String> imagePaths,
    List<String> audioPaths,
  )?
  onSaveWithAudio;
  final QuickAudioRecorder? audioRecorder;
  final Future<void> Function(String content, List<String> imagePaths)
  onOpenEditor;
  final Future<List<String>> Function(List<String> paths) importPhotos;
  final Future<List<String>> Function(ImageSource source)? pickPhotos;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<DraftPayload?> Function(String id)? onLoadDraft;
  final Future<void> Function(DraftPayload draft)? onSaveDraft;
  final Future<void> Function(String id)? onClearDraft;

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  static const _draftId = 'mobile-quick-capture';
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _imagePaths = [];
  final List<String> _audioPaths = [];
  Timer? _draftTimer;
  bool _restoring = false;
  bool _completed = false;
  bool _saving = false;
  bool _picking = false;
  bool _recordingActive = false;
  bool _draftDirty = false;
  int _draftRevision = 0;
  String _persistedContent = '';
  List<String> _persistedImagePaths = const [];
  List<String> _persistedAudioPaths = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scheduleDraftSave);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_finishEntrance()),
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_completed) unawaited(_persistDraft());
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _finishEntrance() async {
    await Future<void>.delayed(
      DiaryMotion.duration(context, DiaryMotion.emphasized),
    );
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        _picking ||
        _saving) {
      return;
    }
    unawaited(_restoreDraft());
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  Future<void> _restoreDraft() async {
    final draft = await widget.onLoadDraft?.call(_draftId);
    if (!mounted ||
        draft == null ||
        _controller.text.isNotEmpty ||
        _imagePaths.isNotEmpty ||
        _audioPaths.isNotEmpty)
      return;
    _restoring = true;
    final content = '${draft.payload['content'] ?? ''}';
    if (draft.payload['editorType'] == 'richText') {
      try {
        _controller.text = quill.Document.fromJson(
          jsonDecode(content) as List,
        ).toPlainText().trimRight();
      } catch (_) {
        _controller.text = content;
      }
    } else {
      _controller.text = content;
    }
    final savedPaths =
        draft.payload['imagePaths'] ?? draft.payload['attachments'];
    if (savedPaths is List) {
      _imagePaths.addAll(
        savedPaths.whereType<String>().where(
          (path) => diaryMediaKindForPath(path) == DiaryMediaKind.image,
        ),
      );
    }
    final savedAudioPaths = draft.payload['audioPaths'];
    if (savedAudioPaths is List) {
      _audioPaths.addAll(
        savedAudioPaths.whereType<String>().where(
          (path) => diaryMediaKindForPath(path) == DiaryMediaKind.audio,
        ),
      );
    }
    _persistedContent = _controller.text;
    _persistedImagePaths = List.of(_imagePaths);
    _persistedAudioPaths = List.of(_audioPaths);
    _restoring = false;
    setState(() {});
  }

  void _scheduleDraftSave() {
    if (_restoring) return;
    if (_controller.text == _persistedContent &&
        listEquals(_imagePaths, _persistedImagePaths) &&
        listEquals(_audioPaths, _persistedAudioPaths)) {
      _draftDirty = false;
      _draftTimer?.cancel();
      return;
    }
    _draftDirty = true;
    _draftRevision++;
    if (widget.onSaveDraft == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_persistDraft()),
    );
  }

  Future<void> _persistDraft() async {
    if (_completed || !_draftDirty || widget.onSaveDraft == null) return;
    final revision = _draftRevision;
    final content = _controller.text;
    final paths = List<String>.of(_imagePaths);
    final audioPaths = List<String>.of(_audioPaths);
    if (content.trim().isEmpty && paths.isEmpty && audioPaths.isEmpty) {
      await widget.onClearDraft?.call(_draftId);
      return;
    }
    await widget.onSaveDraft!(
      DraftPayload(
        id: _draftId,
        payload: {
          'content': content,
          'imagePaths': paths,
          'audioPaths': audioPaths,
        },
        updatedAt: DateTime.now(),
      ),
    );
    if (revision == _draftRevision) {
      _persistedContent = content;
      _persistedImagePaths = paths;
      _persistedAudioPaths = audioPaths;
      _draftDirty = false;
    }
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (_saving || _picking || _recordingActive) return;
    if (content.isEmpty && _imagePaths.isEmpty && _audioPaths.isEmpty) {
      setState(() => _errorMessage = '先写一句、添加照片或录一段声音');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final List<String> imagePaths = List.unmodifiable(_imagePaths);
      final List<String> audioPaths = List.unmodifiable(_audioPaths);
      if (widget.onSaveWithAudio != null) {
        await widget.onSaveWithAudio!(content, imagePaths, audioPaths);
      } else {
        await widget.onSave(content, imagePaths);
      }
      _draftTimer?.cancel();
      _completed = true;
      try {
        await widget.onClearDraft?.call(_draftId);
      } catch (_) {
        // The entry was saved; a stale draft should not report a save failure.
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      debugPrint('Quick capture save failed: $error');
      if (mounted) setState(() => _errorMessage = '保存失败，内容仍在这里，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFullEditor() async {
    if (_picking || _saving || _recordingActive) return;
    _draftTimer?.cancel();
    await _persistDraft();
    if (!mounted) return;
    final content = _controller.text;
    final attachmentPaths = [..._imagePaths, ..._audioPaths];
    Navigator.pop(context);
    await widget.onOpenEditor(content, attachmentPaths);
  }

  Future<void> _addPhotos(ImageSource source) async {
    if (_picking || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _picking = true;
      _errorMessage = null;
    });
    final externalPicker = source == ImageSource.camera;
    if (externalPicker) widget.onExternalActivityStart?.call();
    try {
      final paths =
          await (widget.pickPhotos?.call(source) ?? _pickPhotos(source));
      if (paths.isEmpty) return;
      final imported = await widget.importPhotos(paths);
      if (!mounted) return;
      setState(() {
        for (final path in imported) {
          if (!_imagePaths.contains(path)) _imagePaths.add(path);
        }
      });
      _scheduleDraftSave();
      await _persistDraft();
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '照片没有添加成功，请重试');
    } finally {
      if (externalPicker) widget.onExternalActivityEnd?.call();
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<List<String>> _pickPhotos(ImageSource source) async {
    if (source == ImageSource.camera) {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
      );
      return photo == null ? const [] : [photo.path];
    }
    return pickDiaryPhotos(context, maxAssets: 9 - _imagePaths.length);
  }

  Future<void> _addRecordedAudio(String path) async {
    if (!mounted) return;
    setState(() {
      if (!_audioPaths.contains(path)) _audioPaths.add(path);
    });
    _scheduleDraftSave();
    await _persistDraft();
  }

  void _setRecordingActivity(bool active) {
    if (!mounted || _recordingActive == active) return;
    setState(() => _recordingActive = active);
  }

  void _showRecordingError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '速记这一刻',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭速记',
                    onPressed: _recordingActive
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              KeyedSubtree(
                key: const Key('quick-capture-sheet-field'),
                child: TextField(
                  key: const Key('quick-capture-text'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: false,
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(hintText: '此刻想记下什么？'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _picking || _recordingActive
                        ? null
                        : () => _addPhotos(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('拍照'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _picking || _recordingActive || _imagePaths.length >= 9
                        ? null
                        : () => _addPhotos(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('相册'),
                  ),
                  if (_picking) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              HoldToRecordButton(
                buttonKey: const Key('quick-capture-hold-record'),
                enabled: !_picking && !_saving,
                onActivityChanged: _setRecordingActivity,
                onError: _showRecordingError,
                onRecorded: _addRecordedAudio,
                recorder: widget.audioRecorder,
              ),
              if (_imagePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectedPhotoStrip(
                  paths: _imagePaths,
                  keyPrefix: 'quick-photo',
                  onRemove: (path) {
                    setState(() => _imagePaths.remove(path));
                    _scheduleDraftSave();
                  },
                ),
              ],
              if (_audioPaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('已添加录音', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 7),
                ...List.generate(
                  _audioPaths.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _audioPaths.length - 1 ? 0 : 7,
                    ),
                    child: DiaryAudioPlayer(
                      path: _audioPaths[index],
                      label: '录音 ${index + 1}',
                      compact: true,
                      onRemove: () {
                        setState(() => _audioPaths.removeAt(index));
                        _scheduleDraftSave();
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _picking || _saving || _recordingActive
                        ? null
                        : _openFullEditor,
                    child: const Text('写完整日记'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving || _picking || _recordingActive
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_saving ? '保存中' : '记下'),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '先保存在本机',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
