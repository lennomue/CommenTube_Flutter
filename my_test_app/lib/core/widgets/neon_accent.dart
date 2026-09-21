import 'package:flutter/material.dart';

const neonAccentGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFFFF174F),
    Color(0xFFFFF7FF),
    Color(0xFF24B8FF),
    Color(0xFF315CFF),
    Color(0xFFFF2B70),
  ],
  stops: [0, 0.19, 0.46, 0.72, 1],
);

class NeonOutline extends StatelessWidget {
  const NeonOutline({
    super.key,
    required this.child,
    this.enabled = true,
    this.borderRadius = 18,
    this.width = 2.5,
  });

  final Widget child;
  final bool enabled;
  final double borderRadius;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return DecoratedBox(
      key: const ValueKey('neon-new-outline'),
      decoration: BoxDecoration(
        gradient: neonAccentGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FF174F),
            blurRadius: 10,
            spreadRadius: 0.4,
          ),
          BoxShadow(
            color: Color(0x6624B8FF),
            blurRadius: 12,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(width),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - width),
          child: child,
        ),
      ),
    );
  }
}

class NeonTabIndicator extends Decoration {
  const NeonTabIndicator({this.height = 2.5});

  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _NeonTabIndicatorPainter(height);
  }
}

class _NeonTabIndicatorPainter extends BoxPainter {
  const _NeonTabIndicatorPainter(this.height);

  final double height;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) {
      return;
    }
    final rect = offset & size;
    final lineRect = Rect.fromLTWH(
      rect.left,
      rect.bottom - height,
      rect.width,
      height,
    );
    final shader = neonAccentGradient.createShader(lineRect);
    final start = Offset(lineRect.left, lineRect.center.dy);
    final end = Offset(lineRect.right, lineRect.center.dy);
    canvas
      ..drawLine(
        start,
        end,
        Paint()
          ..shader = shader
          ..strokeWidth = height * 3
          ..strokeCap = StrokeCap.square
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawLine(
        start,
        end,
        Paint()
          ..shader = shader
          ..strokeWidth = height
          ..strokeCap = StrokeCap.square,
      );
  }
}
