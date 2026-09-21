import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MinimizablePageController {
  Future<void> Function()? _minimize;

  Future<void> minimize() => _minimize?.call() ?? Future.value();

  void _attach(Future<void> Function() minimize) => _minimize = minimize;

  void _detach() => _minimize = null;
}

class MinimizablePageSurface extends StatefulWidget {
  const MinimizablePageSurface({
    super.key,
    required this.controller,
    required this.top,
    required this.body,
    required this.onMinimize,
    required this.topHeight,
    this.foreground,
    this.animateFromMinimized = false,
  });

  final MinimizablePageController controller;
  final Widget top;
  final Widget body;
  final VoidCallback onMinimize;
  final double topHeight;
  final Widget? foreground;
  final bool animateFromMinimized;

  @override
  State<MinimizablePageSurface> createState() => _MinimizablePageSurfaceState();
}

class _MinimizablePageSurfaceState extends State<MinimizablePageSurface> {
  static const _animationDuration = Duration(milliseconds: 260);

  double _dragDistance = 0;
  double _progress = 0;
  bool _tracksDrag = false;
  bool _isDragging = false;
  bool _isCompleting = false;
  double? _measuredTopHeight;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_completeMinimize);
    if (widget.animateFromMinimized) {
      _progress = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _progress = 0);
        }
      });
    }
  }

  @override
  void didUpdateWidget(MinimizablePageSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(_completeMinimize);
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topHeight = _measuredTopHeight ?? widget.topHeight;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (details) {
            _tracksDrag =
                !_isCompleting && details.localPosition.dy <= topHeight;
            if (_tracksDrag) {
              setState(() => _isDragging = true);
            }
          },
          onVerticalDragUpdate: (details) {
            if (!_tracksDrag) {
              return;
            }
            _dragDistance = math.max(0, _dragDistance + details.delta.dy);
            final travel = math.max(280.0, constraints.maxHeight * 0.58);
            setState(() => _progress = (_dragDistance / travel).clamp(0, 1));
          },
          onVerticalDragCancel: _cancelDrag,
          onVerticalDragEnd: (details) {
            if (!_tracksDrag) {
              return;
            }
            final velocity = details.primaryVelocity ?? 0;
            if (_progress >= 0.38 || velocity > 650) {
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
              final height = constraints.maxHeight;
              final bodyOpacity = (1 - progress * 3.2).clamp(0, 1).toDouble();
              final topOpacity = (1 - progress * 0.68).clamp(0, 1).toDouble();
              final topScale = 1 - progress * 0.78;
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: 0.34 * (1 - progress),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: topHeight,
                    child: Opacity(
                      opacity: bodyOpacity,
                      child: Transform.translate(
                        offset: Offset(0, 110 * progress),
                        child: widget.body,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: topOpacity,
                      child: Transform.translate(
                        offset: Offset(0, (height - topHeight - 22) * progress),
                        child: Transform.scale(
                          alignment: Alignment.topRight,
                          scale: topScale,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99 * progress),
                            child: _SizeReporter(
                              onSizeChanged: _handleTopSizeChanged,
                              child: widget.top,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.foreground != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: bodyOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 110 * progress),
                          child: widget.foreground!,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _handleTopSizeChanged(Size size) {
    if (!mounted ||
        size.height <= 0 ||
        ((_measuredTopHeight ?? widget.topHeight) - size.height).abs() < 0.5) {
      return;
    }
    setState(() => _measuredTopHeight = size.height);
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

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSizeChanged, required super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SizeReportingRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _SizeReportingRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _SizeReportingRenderObject extends RenderProxyBox {
  _SizeReportingRenderObject(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _lastReportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _lastReportedSize) {
      return;
    }
    _lastReportedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSizeChanged(size));
  }
}
