import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Breathing & Animated Diagonal Hatch Progress Bar
/// Inspired by Teenage Engineering, Nothing OS, and industrial precision telemetry.
/// Features:
/// - Breathing glow & pulsation
/// - Continuous sliding 45-degree hatched texture (///)
/// - Blinking / breathing leading-edge beacon
class BreathingProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final bool showStripes;
  final bool showLeadingBeacon;
  final bool glow;

  const BreathingProgressBar({
    Key? key,
    required this.value,
    this.color,
    this.secondaryColor,
    this.backgroundColor,
    this.height = 10.0,
    this.borderRadius = 6.0,
    this.showStripes = true,
    this.showLeadingBeacon = true,
    this.glow = true,
  }) : super(key: key);

  @override
  State<BreathingProgressBar> createState() => _BreathingProgressBarState();
}

class _BreathingProgressBarState extends State<BreathingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double clampedVal = widget.value.clamp(0.0, 1.0);
    final Color barColor = widget.color ?? KineticTheme.accentFlame;
    final Color trackColor = widget.backgroundColor ?? KineticTheme.bgSurfaceElevated;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final double anim = _pulseController.value;
        // Breathing pulse between 0.82 and 1.0
        final double breathingAlpha = 0.82 + 0.18 * sin(anim * 2 * pi);

        return RepaintBoundary(
          child: CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _HatchedProgressBarPainter(
              progress: clampedVal,
              animProgress: anim,
              breathingAlpha: breathingAlpha,
              barColor: barColor,
              secondaryColor: widget.secondaryColor,
              trackColor: trackColor,
              borderRadius: widget.borderRadius,
              showStripes: widget.showStripes,
              showBeacon: widget.showLeadingBeacon,
              glow: widget.glow,
            ),
          ),
        );
      },
    );
  }
}

class _HatchedProgressBarPainter extends CustomPainter {
  final double progress;
  final double animProgress;
  final double breathingAlpha;
  final Color barColor;
  final Color? secondaryColor;
  final Color trackColor;
  final double borderRadius;
  final bool showStripes;
  final bool showBeacon;
  final bool glow;

  _HatchedProgressBarPainter({
    required this.progress,
    required this.animProgress,
    required this.breathingAlpha,
    required this.barColor,
    this.secondaryColor,
    required this.trackColor,
    required this.borderRadius,
    required this.showStripes,
    required this.showBeacon,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect totalRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // 1. Draw Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(totalRRect, trackPaint);

    final trackBorderPaint = Paint()
      ..color = KineticTheme.borderFaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(totalRRect, trackBorderPaint);

    if (progress <= 0.0) return;

    // Filled width
    final double filledWidth = size.width * progress;
    final Rect filledRect = Rect.fromLTWH(0, 0, filledWidth, size.height);
    final RRect filledRRect = RRect.fromRectAndRadius(
      filledRect,
      Radius.circular(borderRadius),
    );

    // Save layer to clip strictly within rounded bar bounds
    canvas.save();
    canvas.clipRRect(totalRRect);
    canvas.clipRRect(filledRRect);

    // 2. Draw Soft Breathing Glow (behind filled bar)
    if (glow) {
      final glowPaint = Paint()
        ..color = barColor.withValues(alpha: 0.28 * breathingAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(filledRRect, glowPaint);
    }

    // 3. Draw Filled Gradient / Solid Bar
    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (secondaryColor != null) {
      fillPaint.shader = LinearGradient(
        colors: [barColor, secondaryColor!],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(filledRect);
    } else {
      fillPaint.color = barColor.withValues(alpha: 0.92 * breathingAlpha);
    }
    canvas.drawRect(filledRect, fillPaint);

    // 4. Draw Sliding 45-degree Diagonal Hatched Stripes (///)
    if (showStripes && filledWidth > 4) {
      final stripePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22 * breathingAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      const double stripeGap = 7.0;
      final double driftOffset = (animProgress * stripeGap);

      for (double x = -size.height + driftOffset; x < filledWidth + size.height; x += stripeGap) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          stripePaint,
        );
      }
    }

    canvas.restore();

    // 5. Draw Leading-Edge Breathing Light Beacon
    if (showBeacon && progress > 0.02 && progress < 0.99) {
      final double beaconX = filledWidth;
      final double beaconY = size.height / 2;
      final double beaconRadius = (size.height / 2) + 1.5;

      // Halo
      final haloPaint = Paint()
        ..color = barColor.withValues(alpha: 0.45 * breathingAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(beaconX, beaconY), beaconRadius + 2.5, haloPaint);

      // Core LED
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(beaconX, beaconY), beaconRadius - 1.0, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchedProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.breathingAlpha != breathingAlpha ||
        oldDelegate.barColor != barColor;
  }
}
