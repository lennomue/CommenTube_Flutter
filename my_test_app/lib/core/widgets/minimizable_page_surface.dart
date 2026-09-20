import 'dart:math' as math;

import 'package:flutter/material.dart';

class MinimizablePageSurface extends StatefulWidget {
  const MinimizablePageSurface({
    super.key,
    required this.child,
    required this.onMinimize,
    required this.dragRegionHeight,
  });

  final Widget child;
  final VoidCallback onMinimize;
  final double dragRegionHeight;

  @override
  State<MinimizablePageSurface> createState() => _MinimizablePageSurfaceState();
}

class _MinimizablePageSurfaceState extends State<MinimizablePageSurface> {
  static const _animationDuration = Duration(milliseconds: 180);

  double _dragDistance = 0;
  double _progress = 0;
  bool _tracksDrag = false;
  bool _isDragging = false;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (details) {
            _tracksDrag =
                !_isCompleting &&
                details.localPosition.dy <= widget.dragRegionHeight;
            if (_tracksDrag) {
              setState(() => _isDragging = true);
            }
          },
          onVerticalDragUpdate: (details) {
            if (!_tracksDrag) {
              return;
            }
            _dragDistance = math.max(0, _dragDistance + details.delta.dy);
            setState(() => _progress = (_dragDistance / 260).clamp(0, 1));
          },
          onVerticalDragCancel: _cancelDrag,
          onVerticalDragEnd: (details) {
            if (!_tracksDrag) {
              return;
            }
            final velocity = details.primaryVelocity ?? 0;
            if (_progress >= 0.32 || velocity > 550) {
              _completeMinimize();
            } else {
              _cancelDrag();
            }
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _progress),
            duration: _isDragging ? Duration.zero : _animationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Opacity(
                opacity: 1 - (progress * 0.62),
                child: Transform.translate(
                  offset: Offset(
                    width * 0.36 * progress,
                    height * 0.58 * progress,
                  ),
                  child: Transform.scale(
                    alignment: Alignment.bottomRight,
                    scale: 1 - (progress * 0.72),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28 * progress),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }

  void _cancelDrag() {
    if (!_tracksDrag && !_isDragging) {
      return;
    }
    setState(() {
      _tracksDrag = false;
      _isDragging = false;
      _dragDistance = 0;
      _progress = 0;
    });
  }

  Future<void> _completeMinimize() async {
    if (_isCompleting) {
      return;
    }
    setState(() {
      _tracksDrag = false;
      _isDragging = false;
      _isCompleting = true;
      _progress = 1;
    });
    await Future<void>.delayed(_animationDuration);
    if (mounted) {
      widget.onMinimize();
    }
  }
}
