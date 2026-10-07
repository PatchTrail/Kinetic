import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeTourModal extends StatefulWidget {
  const WelcomeTourModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const WelcomeTourModal(),
    );
  }

  @override
  State<WelcomeTourModal> createState() => _WelcomeTourModalState();
}

class _WelcomeTourModalState extends State<WelcomeTourModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'WELCOME TO KINETIC OS',
      'subtitle': 'Autonomous Fitness & Performance Hub',
      'icon': Icons.bolt_rounded,
      'badge': 'SYSTEM PRIMER',
      'description': 'Kinetic is your offline-first biometric operating system. Everything you log is calculated dynamically with zero telemetry cloud tracking.',
      'action': 'Swipe or tap Next to inspect core capabilities.',
    },
    {
      'title': 'ANATOMICAL RECOVERY MAP',
      'subtitle': '3D Muscle Fatigue & Strain',
      'icon': Icons.accessibility_new_rounded,
      'badge': 'BIOMETRIC TELEMETRY',
      'description': 'Your completed workout sets dynamically illuminate muscular load across anterior and posterior anatomy over a 72-hour decay curve. Tap any muscle belly to inspect local fatigue.',
      'action': 'Automatically syncs to your personal profile gender.',
    },
    {
      'title': 'CIRCADIAN PROTOCOLS',
      'subtitle': 'Daily Routines & Habit Flow',
      'icon': Icons.schedule_rounded,
      'badge': 'CIRCADIAN OS',
      'description': 'Align training with natural biology. Track morning photons, Zone 2 aerobic baselines, workout nutrition, contrast therapy, and sleep hygiene while building consistency streaks.',
      'action': 'Completing habits drives your daily readiness gauge.',
    },
    {
      'title': 'DATA SOVEREIGNTY',
      'subtitle': '100% Offline SQLite + Spreadsheet Control',
      'icon': Icons.table_chart_outlined,
      'badge': 'LOCAL FIRST',
      'description': 'You own your data. Export your entire history into standard spreadsheets (.csv) for Excel or Numbers anytime, and restore or merge backups with smart conflict resolution.',
      'action': 'Accessible anytime under Analytics or Profile.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: KineticTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KineticTheme.borderMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Skip button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: KineticTheme.accentFlame,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOUR ${_currentPage + 1}/${_slides.length}',
                      style: TextStyle(
                        color: KineticTheme.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'SKIP TOUR',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Carousel Pages
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: KineticTheme.accentFlame.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(slide['icon'] as IconData, color: KineticTheme.accentFlame, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide['badge'] as String,
                                  style: const TextStyle(
                                    color: KineticTheme.accentFlame,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  slide['title'] as String,
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slide['subtitle'] as String,
                        style: TextStyle(
                          color: KineticTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slide['description'] as String,
                        style: TextStyle(
                          color: KineticTheme.textTertiary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: KineticTheme.borderFaint),
                        ),
                        child: Text(
                          slide['action'] as String,
                          style: const TextStyle(
                            color: KineticTheme.accentJade,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Dots indicator & Next/Finish Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(_slides.length, (idx) {
                    final active = idx == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 5),
                      width: active ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? KineticTheme.accentFlame : KineticTheme.borderMedium,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'PREV',
                          style: TextStyle(color: KineticTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KineticTheme.accentFlame,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'ENTER SYSTEM' : 'NEXT',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
