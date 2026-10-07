import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 10x10 Dot-Matrix Wave Graphic
/// Direct recreation of the wave animation from References/Loading Loop.mp4
class DotMatrixWave extends StatefulWidget {
  final double size;
  final Color? dotColor;
  final bool isInteractive;

  const DotMatrixWave({
    Key? key,
    this.size = 140.0,
    this.dotColor,
    this.isInteractive = true,
  }) : super(key: key);

  @override
  State<DotMatrixWave> createState() => _DotMatrixWaveState();
}

class _DotMatrixWaveState extends State<DotMatrixWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _touchPoint = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!widget.isInteractive) return;
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = details.localPosition;
        setState(() {
          _touchPoint = Offset(
            (local.dx / box.size.width).clamp(0.0, 1.0),
            (local.dy / box.size.height).clamp(0.0, 1.0),
          );
        });
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _DotMatrixPainter(
                progress: _controller.value,
                dotColor: widget.dotColor ?? KineticTheme.textPrimary,
                touchPoint: _touchPoint,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  final double progress;
  final Color dotColor;
  final Offset touchPoint;

  _DotMatrixPainter({
    required this.progress,
    required this.dotColor,
    required this.touchPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 10;
    const int rows = 10;
    final double stepX = size.width / cols;
    final double stepY = size.height / rows;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = (c + 0.5) * stepX;
        final double y = (r + 0.5) * stepY;

        // Calculate distance from ripple origin
        final double normX = c / (cols - 1);
        final double normY = r / (rows - 1);
        final double dist = math.sqrt(
          math.pow(normX - touchPoint.dx, 2) + math.pow(normY - touchPoint.dy, 2),
        );

        // Circular ripple equation
        final double wave = math.sin((dist * 3.5 - progress * 2.0 * math.pi));
        final double normalizedWave = (wave + 1.0) / 2.0;

        // Size modulation: between small dot and expanded square
        final double maxDimension = stepX * 0.78;
        final double minDimension = stepX * 0.18;
        final double currentDimension = minDimension + (maxDimension - minDimension) * normalizedWave;

        paint.color = dotColor.withOpacity(0.25 + 0.75 * normalizedWave);

        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: currentDimension,
          height: currentDimension,
        );

        // Morph between rounded dot and crisp square
        final double radius = (1.0 - normalizedWave) * (currentDimension / 2);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.touchPoint != touchPoint ||
        oldDelegate.dotColor != dotColor;
  }
}
