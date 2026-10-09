import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeftRightBalanceGauge extends StatelessWidget {
  final int leftScore;
  final int rightScore;
  final String muscleName;

  const LeftRightBalanceGauge({
    Key? key,
    required this.leftScore,
    required this.rightScore,
    this.muscleName = 'Chest / Pecs',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Balance ratio: 0.5 is perfectly centered
    final total = leftScore + rightScore;
    final ratio = total == 0 ? 0.5 : leftScore / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tier 1: Centered Title Badge / Label
          Center(
            child: Text(
              muscleName.toUpperCase(),
              style: TextStyle(
                color: KineticTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Tier 2: Arc Gauges & Center Balance Metric Row
          Row(
            children: [
              // Left Circular Arc Score
              _buildArcScore(leftScore, isLeft: true),
              const SizedBox(width: 12),

              // Center Balance Slider Track
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'L',
                      style: TextStyle(
                        color: KineticTheme.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: KineticTheme.borderMedium,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          Align(
                            alignment: Alignment((ratio - 0.5) * 2.0, 0),
                            child: Container(
                              width: 14,
                              height: 8,
                              decoration: BoxDecoration(
                                color: KineticTheme.accentFlame,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: KineticTheme.accentFlame.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'R',
                      style: TextStyle(
                        color: KineticTheme.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right Circular Arc Score
              _buildArcScore(rightScore, isLeft: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArcScore(int score, {required bool isLeft}) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _ArcGaugePainter(score: score, isLeft: isLeft),
        child: Center(
          child: Text(
            '$score',
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final int score;
  final bool isLeft;

  _ArcGaugePainter({required this.score, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final trackPaint = Paint()
      ..color = KineticTheme.borderMedium
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = (score / 100.0) * 2.0 * math.pi;
    final activePaint = Paint()
      ..color = isLeft ? KineticTheme.accentFlame : KineticTheme.accentAmber
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.isLeft != isLeft;
  }
}
