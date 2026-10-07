import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThreeMonthDotGrid extends StatefulWidget {
  final VoidCallback? onTap;
  final Set<String>? completedDates;

  const ThreeMonthDotGrid({
    Key? key,
    this.onTap,
    this.completedDates,
  }) : super(key: key);

  @override
  State<ThreeMonthDotGrid> createState() => _ThreeMonthDotGridState();
}

class _ThreeMonthDotGridState extends State<ThreeMonthDotGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final now = DateTime.now();
    // 3 displayed months matching References/Workouts Screen.jpg
    final m3 = DateTime(now.year, now.month, 1);
    final m2 = DateTime(now.year, now.month - 1, 1);
    final m1 = DateTime(now.year, now.month - 2, 1);

    final months = [m1, m2, m3];

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final double anim = _pulseController.value;
          final double pulseAlpha = 0.5 + 0.5 * sin(anim * 2 * pi);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: months.map((m) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthNames[m.month - 1].toUpperCase(),
                          style: TextStyle(
                            color: KineticTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildMonthDots(m, pulseAlpha),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthDots(DateTime monthDate, double pulseAlpha) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final now = DateTime.now();

    // 5 rows x 6 cols = 30 days grid
    return Column(
      children: List.generate(5, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (col) {
              final day = row * 6 + col + 1;
              if (day > daysInMonth) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                );
              }

              final dateStr = "${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
              final isDone = widget.completedDates?.contains(dateStr) ?? false;
              final isToday = day == now.day && monthDate.month == now.month && monthDate.year == now.year;

              Color dotColor;
              List<BoxShadow>? shadows;

              if (isDone) {
                dotColor = KineticTheme.accentFlame;
                shadows = [
                  BoxShadow(
                    color: KineticTheme.accentFlame.withValues(alpha: 0.35 + 0.35 * pulseAlpha),
                    blurRadius: 5,
                    spreadRadius: 0.8,
                  ),
                ];
              } else if (isToday) {
                dotColor = KineticTheme.accentJade;
                shadows = [
                  BoxShadow(
                    color: KineticTheme.accentJade.withValues(alpha: 0.4 + 0.4 * pulseAlpha),
                    blurRadius: 6,
                    spreadRadius: 1.0,
                  ),
                ];
              } else {
                dotColor = KineticTheme.borderMedium;
              }

              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: shadows,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
