import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FieldManualModal extends StatefulWidget {
  final int initialTab;
  const FieldManualModal({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FieldManualModal(initialTab: initialTab),
    );
  }

  @override
  State<FieldManualModal> createState() => _FieldManualModalState();
}

class _FieldManualModalState extends State<FieldManualModal> {
  late int _selectedTab;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'SYSTEM OVERVIEW',
      'icon': Icons.dashboard_outlined,
      'sections': [
        {
          'heading': '1. Starting & Tracking Workouts',
          'body': 'Tap any routine card on the dashboard or use "Quick Workout" to begin training. In active workouts, enter your weight and reps for each set, then tap the checkmark to log completion. An automatic rest timer starts as soon as a set is finished.',
        },
        {
          'heading': '2. Deleting Mistaken Logs',
          'body': 'Under "Recent Logged Sessions" on the dashboard, swipe any session card to the left to reveal the crimson Delete button. Tapping it permanently wipes the workout and its sets from the database and recalculates all telemetry.',
        },
        {
          'heading': '3. Finishing a Session',
          'body': 'Tapping FINISH in the top bar instantly freezes your elapsed session clock, tallies total volume tonnage, and logs your session to your consistency matrix.',
        },
      ],
    },
    {
      'title': 'ANATOMICAL TELEMETRY',
      'icon': Icons.accessibility_new_rounded,
      'sections': [
        {
          'heading': '1. Dynamic Strain & Recovery Heatmap',
          'body': 'The 3D anatomical model highlights muscular activation based on training volume logged over the last 72 hours. Primary muscles receive full load, while synergists receive proportional secondary load.',
        },
        {
          'heading': '2. Personalized Anatomy',
          'body': 'The anatomical model automatically syncs with your selected profile gender (male or female), displaying crisp anterior (front) and posterior (back) views.',
        },
        {
          'heading': '3. Inspecting Muscle Bellies',
          'body': 'Tap directly on any muscle group (Pectorals, Quads, Lats, Delts, Hamstrings) on the 3D map to inspect exact percentage strain, recovery state, and volume.',
        },
        {
          'heading': '4. Bilateral Symmetry Index',
          'body': 'Measures mechanical symmetry between your left and right sides to ensure balanced unilateral development and injury prevention.',
        },
      ],
    },
    {
      'title': 'CIRCADIAN PROTOCOLS',
      'icon': Icons.timeline_rounded,
      'sections': [
        {
          'heading': '1. Daily Routine & Flow',
          'body': 'The Protocol screen structures your day according to circadian biology: morning photons, Zone 2 aerobic baselines, pre/post workout nutrition, thermal contrast, and sleep hygiene.',
        },
        {
          'heading': '2. Bio-Marker Readiness Gauge',
          'body': 'The circular dial tracks your protocol completion rate for the selected day. Completing habits increments your daily readiness score.',
        },
        {
          'heading': '3. 7-Day Horizon',
          'body': 'Use the horizontal week bar to review past habit compliance or plan upcoming protocol milestones.',
        },
      ],
    },
    {
      'title': 'DATA SOVEREIGNTY (CSV/EXCEL)',
      'icon': Icons.table_chart_outlined,
      'sections': [
        {
          'heading': '1. 100% Offline-First Architecture',
          'body': 'All workouts, sets, bodyweight entries, and food logs are stored locally on your device in an embedded SQLite database. No external servers or cloud accounts required.',
        },
        {
          'heading': '2. Spreadsheet Export',
          'body': 'Under the Analytics tab or Data Management, tap EXPORT CSV to compile a multi-table spreadsheet backup of your entire training history.',
        },
        {
          'heading': '3. Spreadsheet Import & Restore',
          'body': 'You can import spreadsheet backups anytime. The import engine resolves record conflicts by primary key and preserves your existing data while merging imported entries.',
        },
        {
          'heading': '4. Data Purge (Reset)',
          'body': 'If you ever want to start completely fresh from scratch, the Purge button wipes all workout tables and returns the app to its baseline empty state.',
        },
      ],
    },
    {
      'title': 'AUDIO & MEDIA CAPSULE',
      'icon': Icons.music_note_rounded,
      'sections': [
        {
          'heading': '1. Floating Cross-Platform Music Capsule',
          'body': 'Kinetic includes an interactive media capsule with spinning vinyl artwork, track info, and playback controls (play/pause, next, previous) resting seamlessly above the bottom navigation dock.',
        },
        {
          'heading': '2. Linux Desktop D-Bus (MPRIS)',
          'body': 'On Linux desktop, Kinetic connects directly to the system session D-Bus (org.mpris.MediaPlayer2) with zero setup required, controlling Spotify, Brave, Chrome, Amberol, VLC, and others.',
        },
        {
          'heading': '3. Zero Sensitive Permissions (Standard)',
          'body': 'In this standard edition (v1.0.1), Kinetic requires zero special Android permissions, installing frictionlessly in one tap without Google Play Protect prompts.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_selectedTab];
    final sections = currentTab['sections'] as List<Map<String, String>>;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: KineticTheme.bgCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KineticTheme.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELD MANUAL // OPERATING GUIDE',
                      style: TextStyle(
                        color: KineticTheme.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'System Reference',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: KineticTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category Pill Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (idx) {
                final tab = _tabs[idx];
                final isSelected = idx == _selectedTab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : KineticTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab['title'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                            color: isSelected ? Colors.white : KineticTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: KineticTheme.accentFlame,
                    backgroundColor: KineticTheme.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? KineticTheme.accentFlame : KineticTheme.borderMedium,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedTab = idx);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: KineticTheme.borderFaint, height: 1),

          // Content List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sections.length,
              separatorBuilder: (separatorContext, separatorIndex) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final s = sections[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: KineticTheme.cardDecoration(
                    backgroundColor: KineticTheme.bgSurface,
                    border: Border.all(color: KineticTheme.borderFaint),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['heading']!,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s['body']!,
                        style: TextStyle(
                          color: KineticTheme.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      if (_selectedTab == 4 && index == 1 && Platform.isLinux) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: KineticTheme.accentJade.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: KineticTheme.accentJade),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: KineticTheme.accentJade, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'D-BUS MPRIS CONNECTED // AUTO',
                                style: TextStyle(
                                  color: KineticTheme.accentJade,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
