import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated Dot Matrix Wave Background
/// Inspired by Teenage Engineering field interfaces, Nothing OS dot lattices,
/// and responsive metaball wave animations.
class AnimatedDotMatrixBackground extends StatefulWidget {
  final Widget? child;
  final double dotSpacing;
  final bool enableConnections;

  const AnimatedDotMatrixBackground({
    Key? key,
    this.child,
    this.dotSpacing = 24.0,
    this.enableConnections = true,
  }) : super(key: key);

  @override
  State<AnimatedDotMatrixBackground> createState() => _AnimatedDotMatrixBackgroundState();
}

class _AnimatedDotMatrixBackgroundState extends State<AnimatedDotMatrixBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !KineticTheme.isDarkMode;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _DotMatrixWavePainter(
                    progress: _controller.value,
                    dotSpacing: widget.dotSpacing,
                    isLight: isLight,
                    enableConnections: widget.enableConnections,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _DotMatrixWavePainter extends CustomPainter {
  final double progress;
  final double dotSpacing;
  final bool isLight;
  final bool enableConnections;

  _DotMatrixWavePainter({
    required this.progress,
    required this.dotSpacing,
    required this.isLight,
    required this.enableConnections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final Color baseColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color crestColor = isLight ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color accentGlow = KineticTheme.accentFlame;

    final double phaseOffset = progress * 2 * pi;
    final int cols = (size.width / dotSpacing).ceil() + 1;
    final int rows = (size.height / dotSpacing).ceil() + 1;

    // Buffer to hold high-intensity points for mesh connections
    final List<Offset> highCrestPoints = [];

    for (int r = 0; r < rows; r++) {
      final double y = r * dotSpacing;
      for (int c = 0; c < cols; c++) {
        final double x = c * dotSpacing;

        // Diagonal traveling sinusoidal wave with gentle harmonics
        final double waveAngle = (x * 0.012) + (y * 0.016) - phaseOffset;
        final double rawSin = sin(waveAngle);
        final double secondary = 0.25 * sin(waveAngle * 2.0 + (x * 0.008));
        final double waveVal = (rawSin + secondary).clamp(-1.0, 1.0);

        // Normalize wave intensity [0.0, 1.0] with exponential contrast
        final double intensity = pow((waveVal + 1.0) / 2.0, 3.0).toDouble();

        // Calculate dot radius and opacity
        final double baseRadius = isLight ? 1.0 : 1.1;
        final double maxRadius = isLight ? 2.8 : 3.0;
        final double radius = baseRadius + (maxRadius - baseRadius) * intensity;

        final double minAlpha = isLight ? 0.08 : 0.09;
        final double maxAlpha = isLight ? 0.38 : 0.42;
        final double alpha = minAlpha + (maxAlpha - minAlpha) * intensity;

        // Color blending between resting state and crest state
        Color dotColor;
        if (intensity > 0.82) {
          // Subtle warm accent spark at the absolute apex of the wave
          final double apexRatio = (intensity - 0.82) / 0.18;
          dotColor = Color.lerp(crestColor, accentGlow, apexRatio * 0.35)!;
          if (enableConnections && (c % 2 == 0 && r % 2 == 0)) {
            highCrestPoints.add(Offset(x, y));
          }
        } else {
          dotColor = Color.lerp(baseColor, crestColor, intensity)!;
        }

        dotPaint.color = dotColor.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), radius, dotPaint);

        // Optional tiny crosshair tick on select grid intersections
        if (c % 6 == 0 && r % 6 == 0 && intensity < 0.2) {
          final tickPaint = Paint()
            ..color = baseColor.withValues(alpha: isLight ? 0.14 : 0.18)
            ..strokeWidth = 0.7;
          canvas.drawLine(Offset(x - 2.5, y), Offset(x + 2.5, y), tickPaint);
          canvas.drawLine(Offset(x, y - 2.5), Offset(x, y + 2.5), tickPaint);
        }
      }
    }

    // Connect peak points with subtle lattice lines (metaball web effect)
    if (enableConnections && highCrestPoints.length > 1) {
      final double maxConnectDist = dotSpacing * 1.5;
      for (int i = 0; i < highCrestPoints.length; i++) {
        for (int j = i + 1; j < highCrestPoints.length; j++) {
          final Offset p1 = highCrestPoints[i];
          final Offset p2 = highCrestPoints[j];
          final double d = (p1 - p2).distance;
          if (d <= maxConnectDist) {
            final double lineAlpha = (1.0 - (d / maxConnectDist)) * (isLight ? 0.18 : 0.22);
            linePaint.color = (isLight ? crestColor : accentGlow).withValues(alpha: lineAlpha);
            canvas.drawLine(p1, p2, linePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isLight != isLight ||
        oldDelegate.dotSpacing != dotSpacing;
  }
}
