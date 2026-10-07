import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityPillMatrix extends StatelessWidget {
  final int totalDays;
  final Set<int> completedDays; // 0 to 29 (day indices)
  final String title;
  final String statusText;
  final VoidCallback? onTap;

  const ActivityPillMatrix({
    Key? key,
    this.totalDays = 30,
    required this.completedDays,
    this.title = 'Last 30 days',
    this.statusText = '17 · goal 4/wk',
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: KineticTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: KineticTheme.textTertiary),
                    ],
                  ],
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: KineticTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // 3 rows of 10 pill blocks
          Column(
            children: List.generate(3, (row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: List.generate(10, (col) {
                    final dayIndex = row * 10 + col;
                    final isDone = completedDays.contains(dayIndex);
                    final isRecent = dayIndex >= 26;

                    return Expanded(
                      child: Container(
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color: isDone
                              ? (isRecent ? KineticTheme.accentFlame : KineticTheme.accentJade)
                              : KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(100),
                          border: isDone && isRecent
                              ? Border.all(color: KineticTheme.accentFlame.withOpacity(0.9), width: 1.2)
                              : null,
                          boxShadow: isDone && isRecent
                              ? [
                                  BoxShadow(
                                    color: KineticTheme.accentFlame.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}
}
