import 'package:flutter/material.dart';
import '../models/muscle_group.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import '../widgets/anatomical_body_map.dart';
import '../widgets/left_right_balance_gauge.dart';
import '../widgets/breathing_progress_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  MuscleGroup? _selectedMuscle;
  String _exportStatusMessage = '';
  bool _isExporting = false;

  Map<MuscleGroup, double> _muscleFatigueMap = {};
  Map<String, double> _muscleVolumeMap = {
    'Quadriceps': 0.0,
    'Pectorals': 0.0,
    'Lats & Back': 0.0,
    'Triceps': 0.0,
    'Hamstrings': 0.0,
  };
  int _leftScore = 50;
  int _rightScore = 50;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    final fatigue = await DatabaseService.instance.getRecentMuscleFatigueMap();
    final volume = await DatabaseService.instance.get7DayVolumePerMuscleGroup();
    final balance = await DatabaseService.instance.getBilateralBalanceScores();

    if (mounted) {
      setState(() {
        _muscleFatigueMap = fatigue;
        _muscleVolumeMap = volume;
        _leftScore = balance['left'] ?? 50;
        _rightScore = balance['right'] ?? 50;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportStatusMessage = 'Compiling spreadsheet archive...';
    });

    final result = await ExcelService.instance.exportUserDataToSpreadsheet();

    setState(() {
      _isExporting = false;
      _exportStatusMessage = result.message;
    });
  }

  Future<void> _handleImport() async {
    setState(() {
      _isExporting = true;
      _exportStatusMessage = 'Selecting spreadsheet backup...';
    });

    final result = await ExcelService.instance.pickAndImportSpreadsheet();

    if (result.success) {
      await _loadTelemetry();
    }

    setState(() {
      _isExporting = false;
      _exportStatusMessage = result.message;
    });
  }

  void _showPurgeConfirmDialog() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: KineticTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'PURGE ALL APPLICATION DATA?',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'This will permanently delete all logged workouts, workout sets, custom routines, bodyweight history, food logs, and profile info.\n\nThe application will return to an initial fresh onboarding state.',
          style: TextStyle(color: KineticTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('CANCEL', style: TextStyle(color: KineticTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dCtx);
              await DatabaseService.instance.purgeAllUserData();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('PURGE EVERYTHING', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Anatomical Muscle Fatigue Heatmap
              _buildFatigueSection(),
              const SizedBox(height: 16),

              // Left-Right Bilateral Balance
              LeftRightBalanceGauge(
                leftScore: _leftScore,
                rightScore: _rightScore,
                muscleName: 'Bilateral Symmetry Index',
              ),
              const SizedBox(height: 16),

              // Volume Breakdown by Muscle Group
              _buildMuscleVolumeDistribution(),
              const SizedBox(height: 16),

              // Excel / CSV Export & Import Center
              _buildDataManagementSection(),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANATOMICAL TELEMETRY',
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Recovery & Muscle Map',
          style: TextStyle(
            color: KineticTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFatigueSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SYSTEMIC FATIGUE & STRAIN',
                  style: TextStyle(
                    color: KineticTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KineticTheme.accentFlame.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE VECTOR',
                  style: TextStyle(
                    color: KineticTheme.accentFlame,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnatomicalBodyMap(
            activationLevels: _muscleFatigueMap,
            showBothViews: true,
            height: 300,
            selectedMuscle: _selectedMuscle,
            onMuscleSelected: (muscle) {
              setState(() => _selectedMuscle = muscle);
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _selectedMuscle != null
                  ? 'SELECTED: ${_selectedMuscle!.displayName.toUpperCase()} (${((_muscleFatigueMap[_selectedMuscle] ?? 0.5) * 100).toInt()}% STRAIN)'
                  : 'TAP ANY REGION TO INSPECT STRAIN & RECOVERY',
              style: const TextStyle(
                color: KineticTheme.accentFlame,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleVolumeDistribution() {
    final totalVol = _muscleVolumeMap.values.fold(0.0, (a, b) => a + b);
    double maxVol = 0.0;
    for (final v in _muscleVolumeMap.values) {
      if (v > maxVol) maxVol = v;
    }
    if (maxVol == 0.0) maxVol = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(backgroundColor: KineticTheme.bgSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY VOLUME PER MUSCLE GROUP',
                style: TextStyle(
                  color: KineticTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (totalVol > 0)
                Text(
                  '${_formatKg(totalVol)} kg TOTAL',
                  style: const TextStyle(
                    color: KineticTheme.accentFlame,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (totalVol == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded, color: KineticTheme.textTertiary, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'NO WORKOUT VOLUME IN LAST 7 DAYS',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Complete workouts to track tonnage distribution per muscle group.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KineticTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._muscleVolumeMap.entries.map((entry) {
              final val = (entry.value / maxVol).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(color: KineticTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_formatKg(entry.value)} kg',
                          style: TextStyle(color: KineticTheme.textSecondary, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BreathingProgressBar(
                      value: val,
                      height: 8,
                      color: KineticTheme.accentFlame,
                      backgroundColor: KineticTheme.bgSurfaceElevated,
                      showStripes: true,
                      showLeadingBeacon: true,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatKg(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)}k';
    }
    return kg.toStringAsFixed(0);
  }

  Widget _buildDataManagementSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_outlined, color: KineticTheme.accentFlame, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DATA SOVEREIGNTY // EXCEL & CSV',
                  style: TextStyle(
                    color: KineticTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your data is 100% offline and stored in SQLite. Export anytime into standard spreadsheet workbooks (.csv / .xlsx) for Excel, Apple Numbers, or personal scripts.',
            style: TextStyle(
              color: KineticTheme.textTertiary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons: Export & Import
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _handleExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KineticTheme.bgSurfaceElevated,
                      foregroundColor: KineticTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: KineticTheme.borderMedium),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 15, color: KineticTheme.accentFlame),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'EXPORT CSV',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _handleImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KineticTheme.bgSurfaceElevated,
                      foregroundColor: KineticTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: KineticTheme.borderMedium),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file_rounded, size: 15, color: KineticTheme.accentJade),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'IMPORT CSV',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Purge Data Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: _showPurgeConfirmDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 16, color: Colors.redAccent),
                    SizedBox(width: 6),
                    Text(
                      'PURGE ALL APPLICATION DATA (RESET)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_exportStatusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: KineticTheme.bgSurfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KineticTheme.borderFaint),
              ),
              child: SelectableText(
                _exportStatusMessage,
                style: const TextStyle(
                  color: KineticTheme.accentJade,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
