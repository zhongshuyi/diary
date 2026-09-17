import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/widgets/quick_capture_sheet.dart';

class DraggableQuickCaptureFab extends StatefulWidget {
  const DraggableQuickCaptureFab({
    required this.onSubmit,
    this.initialPosition,
    this.onPositionChanged,
    super.key,
  });

  final Future<void> Function(String) onSubmit;
  final Offset? initialPosition;
  final ValueChanged<Offset>? onPositionChanged;

  @override
  State<DraggableQuickCaptureFab> createState() =>
      _DraggableQuickCaptureFabState();
}

class _DraggableQuickCaptureFabState extends State<DraggableQuickCaptureFab> {
  static const _buttonSize = 60.0;
  static const _margin = 16.0;

  Offset? _position;
  BoxConstraints _constraints = const BoxConstraints();
  bool _dragging = false;
  String _draft = '';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _constraints = constraints;
        final position = _clamp(
          _position ?? widget.initialPosition ?? _defaultPosition(constraints),
          constraints,
        );
        final child = _button(position);
        if (_dragging || _position == null) {
          return Stack(
            children: [
              Positioned.fromRect(rect: _rect(position), child: child),
            ],
          );
        }
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              left: position.dx,
              top: position.dy,
              width: _buttonSize,
              height: _buttonSize,
              child: child,
            ),
          ],
        );
      },
    );
  }

  Widget _button(Offset position) {
    final colors = DiaryThemeColors.of(context);
    return GestureDetector(
      onPanStart: (_) => setState(() => _dragging = true),
      onPanUpdate: (details) {
        setState(() {
          final current = _position ?? position;
          _position = _clamp(current + details.delta, _constraints);
        });
      },
      onPanEnd: (_) => _snap(_constraints),
      child: Semantics(
        key: const Key('floating-quick-capture'),
        button: true,
        label: '快速记录',
        hint: '点击打开速记，拖动调整位置',
        child: Material(
          color: colors.hero,
          elevation: 5,
          shadowColor: colors.hero.withValues(alpha: .28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openSheet,
            splashColor: colors.terracotta.withValues(alpha: .25),
            child: Center(
              child: Icon(Icons.bolt_outlined, color: colors.butter, size: 27),
            ),
          ),
        ),
      ),
    );
  }

  Rect _rect(Offset position) =>
      Rect.fromLTWH(position.dx, position.dy, _buttonSize, _buttonSize);

  Offset _defaultPosition(BoxConstraints constraints) => Offset(
    math.max(_margin, constraints.maxWidth - _buttonSize - _margin),
    math.max(_margin, constraints.maxHeight - _buttonSize - _margin),
  );

  Offset _clamp(Offset position, BoxConstraints constraints) {
    final maxX = math.max(
      _margin,
      constraints.maxWidth - _buttonSize - _margin,
    );
    final maxY = math.max(
      _margin,
      constraints.maxHeight - _buttonSize - _margin,
    );
    return Offset(
      position.dx.clamp(_margin, maxX).toDouble(),
      position.dy.clamp(_margin, maxY).toDouble(),
    );
  }

  void _snap(BoxConstraints constraints) {
    final current = _clamp(
      _position ?? _defaultPosition(constraints),
      constraints,
    );
    final maxX = math.max(
      _margin,
      constraints.maxWidth - _buttonSize - _margin,
    );
    final snapped = Offset(
      current.dx + _buttonSize / 2 < constraints.maxWidth / 2 ? _margin : maxX,
      current.dy,
    );
    setState(() {
      _position = snapped;
      _dragging = false;
    });
    widget.onPositionChanged?.call(snapped);
  }

  Future<void> _openSheet() async {
    await showQuickCaptureSheet(
      context,
      initialText: _draft,
      onDraftChanged: (value) => setState(() => _draft = value),
      onSubmit: widget.onSubmit,
    );
  }
}
