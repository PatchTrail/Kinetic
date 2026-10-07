import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VolumeSplineChart extends StatefulWidget {
  final List<double> volumePoints;
  final List<String> labels;
  final String title;
  final String subtitle;
  final double currentVolume;

  const VolumeSplineChart({
    Key? key,
    required this.volumePoints,
    required this.labels,
    this.title = 'Volume',
    this.subtitle = '3-week trend',
    this.currentVolume = 363.2,
  }) : super(key: key);

  @override
  State<VolumeSplineChart> createState() => _VolumeSplineChartState();
}

class _VolumeSplineChartState extends State<VolumeSplineChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 16, color: KineticTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KineticTheme.accentFlame.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: KineticTheme.accentFlame.withOpacity(0.3)),
                ),
                child: const Text(
                  '+12.4%',
                  style: TextStyle(
                    color: KineticTheme.accentFlame,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.currentVolume.toStringAsFixed(1)}k',
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'lbs',
                style: TextStyle(
                  color: KineticTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _SplineChartPainter(
                data: widget.volumePoints,
                hoverIndex: _hoveredIndex,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.labels.map((l) => Text(
              l,
              style: TextStyle(
                color: KineticTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  final List<double> data;
  final int? hoverIndex;

  _SplineChartPainter({required this.data, this.hoverIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double minVal = data.reduce(math.min) * 0.9;
    final double maxVal = data.reduce(math.max) * 1.05;
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double dx = size.width / (data.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final double x = i * dx;
      final double normY = (data[i] - minVal) / range;
      final double y = size.height - (normY * size.height);
      points.add(Offset(x, y));
    }

    // Generate smooth cubic bezier curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    // Gradient fill below path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        KineticTheme.accentFlame.withOpacity(0.35),
        KineticTheme.bgSurface.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Glowing line
    final linePaint = Paint()
      ..color = KineticTheme.accentFlame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Highlight dots on points
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      dotPaint.color = Colors.black;
      canvas.drawCircle(pt, 4.0, dotPaint);
      dotPaint.color = KineticTheme.accentFlame;
      canvas.drawCircle(pt, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.hoverIndex != hoverIndex;
  }
}
