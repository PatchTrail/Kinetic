import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoutineNumberBadge extends StatelessWidget {
  final int number;
  final double progress; // 0.0 to 1.0
  final double size;
  final Color activeColor;

  const RoutineNumberBadge({
    Key? key,
    required this.number,
    this.progress = 0.72,
    this.size = 46,
    this.activeColor = KineticTheme.accentFlame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(
          progress: progress,
          activeColor: activeColor,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  _BadgePainter({required this.progress, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Background track ring
    final bgPaint = Paint()
      ..color = KineticTheme.borderFaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, bgPaint);

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
