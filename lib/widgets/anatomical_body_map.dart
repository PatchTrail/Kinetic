import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/muscle_group.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class AnatomicalBodyMap extends StatefulWidget {
  final Map<MuscleGroup, double> activationLevels; // 0.0 to 1.0
  final Function(MuscleGroup)? onMuscleSelected;
  final MuscleGroup? selectedMuscle;
  final bool showBothViews;
  final double height;
  final String? gender; // 'male' or 'female'

  const AnatomicalBodyMap({
    Key? key,
    required this.activationLevels,
    this.onMuscleSelected,
    this.selectedMuscle,
    this.showBothViews = true,
    this.height = 270.0,
    this.gender,
  }) : super(key: key);

  @override
  State<AnatomicalBodyMap> createState() => _AnatomicalBodyMapState();
}

class _AnatomicalBodyMapState extends State<AnatomicalBodyMap> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showingFront = true;
  late String _currentGender;

  @override
  void initState() {
    super.initState();
    _currentGender = widget.gender ?? 'male';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    // If gender wasn't passed, load from database profile
    if (widget.gender == null) {
      _loadProfileGender();
    }
  }

  Future<void> _loadProfileGender() async {
    final profile = await DatabaseService.instance.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentGender = profile.gender;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnatomicalBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gender != null && widget.gender != _currentGender) {
      setState(() {
        _currentGender = widget.gender!;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getAssetPath({required bool isFront}) {
    final isMale = _currentGender.toLowerCase() == 'male';
    if (isMale) {
      return isFront
          ? 'assets/images/mesh_male_front.png'
          : 'assets/images/mesh_male_back.png';
    } else {
      return isFront
          ? 'assets/images/mesh_female_front.png'
          : 'assets/images/mesh_female_back.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderMedium),
      ),
      child: Column(
        children: [
          // Top Control Bar: View Title + Gender & View Segmented Toggles
          _buildTopControlBar(),
          const SizedBox(height: 6),

          // Main Interactive Visualizer View
          Expanded(
            child: widget.showBothViews ? _buildSideBySideView() : _buildSingleView(),
          ),

          // Selected Muscle HUD Indicator Bar
          if (widget.selectedMuscle != null)
            _buildSelectedMuscleHud(),
        ],
      ),
    );
  }

  Widget _buildTopControlBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title / Active Count
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: KineticTheme.accentFlame,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'HEAT MAP',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: KineticTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Single View Front/Back Switch
        if (!widget.showBothViews)
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: KineticTheme.bgSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniSegment(
                  label: 'FRONT',
                  isActive: _showingFront,
                  onTap: () => setState(() => _showingFront = true),
                ),
                _buildMiniSegment(
                  label: 'BACK',
                  isActive: !_showingFront,
                  onTap: () => setState(() => _showingFront = false),
                ),
              ],
            ),
          ),

      ],
    );
  }

  Widget _buildMiniSegment({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? KineticTheme.accentFlame : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : KineticTheme.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideView() {
    return Row(
      children: [
        // Anterior
        Expanded(
          child: Column(
            children: [
              Text(
                'ANTERIOR',
                style: TextStyle(
                  color: KineticTheme.textTertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _buildBodyMeshInteractive(isFront: true),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          color: KineticTheme.borderFaint,
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        // Posterior
        Expanded(
          child: Column(
            children: [
              Text(
                'POSTERIOR',
                style: TextStyle(
                  color: KineticTheme.textTertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _buildBodyMeshInteractive(isFront: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleView() {
    return Column(
      children: [
        Text(
          _showingFront ? 'ANTERIOR VIEW' : 'POSTERIOR VIEW',
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _buildBodyMeshInteractive(isFront: _showingFront),
        ),
      ],
    );
  }

  Widget _buildBodyMeshInteractive({required bool isFront}) {
    final assetPath = _getAssetPath(isFront: isFront);

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 380,
            height: 700,
            child: Stack(
              children: [
                // 1. Photographic 3D Base Mesh
                Image.asset(
                  assetPath,
                  width: 380,
                  height: 700,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),

                // 2. Dynamic Thermo-Luminescent Heat Map Overlay
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(380, 700),
                      painter: _ThermoHeatMapPainter(
                        isFront: isFront,
                        activationMap: widget.activationLevels,
                        selectedMuscle: widget.selectedMuscle,
                        pulseValue: _pulseAnimation.value,
                      ),
                    );
                  },
                ),

                // 3. Interactive Tap Region Target Detection
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleCanvasTap(details, isFront),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedMuscleHud() {
    final m = widget.selectedMuscle!;
    final level = (widget.activationLevels[m] ?? 0.85);
    final percent = (level * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KineticTheme.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
      ),
      child: Row(
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
              const SizedBox(width: 6),
              Text(
                m.displayName.toUpperCase(),
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: KineticTheme.borderFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: level.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: KineticTheme.accentFlame,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$percent% STRAIN',
                style: const TextStyle(
                  color: KineticTheme.accentFlame,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCanvasTap(TapUpDetails details, bool isFront) {
    final localPos = details.localPosition;
    final x = localPos.dx;
    final y = localPos.dy;

    MuscleGroup? bestMatch;
    double minDistance = double.infinity;

    final targetDefinitions = _ThermoHeatMapPainter.getMuscleDefinitions(isFront);

    for (final def in targetDefinitions) {
      for (final node in def.nodes) {
        // Normalized Euclidean distance accounting for node radius
        final dx = (x - node.center.dx) / node.radiusX;
        final dy = (y - node.center.dy) / node.radiusY;
        final dist = dx * dx + dy * dy;

        if (dist <= 1.4 && dist < minDistance) {
          minDistance = dist;
          bestMatch = def.muscle;
        }
      }
    }

    if (bestMatch != null) {
      widget.onMuscleSelected?.call(bestMatch);
    }
  }
}

class _MuscleNode {
  final Offset center;
  final double radiusX;
  final double radiusY;

  const _MuscleNode(this.center, this.radiusX, this.radiusY);
}

class _MuscleDefinition {
  final MuscleGroup muscle;
  final List<_MuscleNode> nodes;

  const _MuscleDefinition(this.muscle, this.nodes);
}

class _ThermoHeatMapPainter extends CustomPainter {
  final bool isFront;
  final Map<MuscleGroup, double> activationMap;
  final MuscleGroup? selectedMuscle;
  final double pulseValue;

  _ThermoHeatMapPainter({
    required this.isFront,
    required this.activationMap,
    required this.selectedMuscle,
    required this.pulseValue,
  });

  static List<_MuscleDefinition> getMuscleDefinitions(bool isFront) {
    if (isFront) {
      return [
        // Upper Chest
        _MuscleDefinition(MuscleGroup.upperChest, [
          _MuscleNode(const Offset(148, 172), 24, 15),
          _MuscleNode(const Offset(232, 172), 24, 15),
        ]),
        // Chest (Pectorals)
        _MuscleDefinition(MuscleGroup.chest, [
          _MuscleNode(const Offset(142, 195), 30, 24),
          _MuscleNode(const Offset(238, 195), 30, 24),
        ]),
        // Front Shoulders (Anterior Delts)
        _MuscleDefinition(MuscleGroup.anteriorDelts, [
          _MuscleNode(const Offset(105, 175), 22, 22),
          _MuscleNode(const Offset(275, 175), 22, 22),
        ]),
        // Side Shoulders (Lateral Delts)
        _MuscleDefinition(MuscleGroup.lateralDelts, [
          _MuscleNode(const Offset(90, 186), 18, 24),
          _MuscleNode(const Offset(290, 186), 18, 24),
        ]),
        // Biceps
        _MuscleDefinition(MuscleGroup.biceps, [
          _MuscleNode(const Offset(94, 235), 20, 32),
          _MuscleNode(const Offset(286, 235), 20, 32),
        ]),
        // Forearms
        _MuscleDefinition(MuscleGroup.forearms, [
          _MuscleNode(const Offset(72, 310), 18, 44),
          _MuscleNode(const Offset(308, 310), 18, 44),
        ]),
        // Abdominals (Core)
        _MuscleDefinition(MuscleGroup.abs, [
          _MuscleNode(const Offset(190, 232), 26, 15),
          _MuscleNode(const Offset(190, 258), 28, 15),
          _MuscleNode(const Offset(190, 284), 26, 16),
        ]),
        // Obliques
        _MuscleDefinition(MuscleGroup.obliques, [
          _MuscleNode(const Offset(152, 265), 16, 30),
          _MuscleNode(const Offset(228, 265), 16, 30),
        ]),
        // Quadriceps (Quads)
        _MuscleDefinition(MuscleGroup.quads, [
          _MuscleNode(const Offset(152, 430), 34, 62),
          _MuscleNode(const Offset(228, 430), 34, 62),
        ]),
        // Calves (Front Shin/Calf)
        _MuscleDefinition(MuscleGroup.calves, [
          _MuscleNode(const Offset(148, 560), 24, 50),
          _MuscleNode(const Offset(232, 560), 24, 50),
        ]),
      ];
    } else {
      return [
        // Traps (Trapezius)
        _MuscleDefinition(MuscleGroup.traps, [
          _MuscleNode(const Offset(190, 145), 44, 25),
          _MuscleNode(const Offset(190, 178), 30, 25),
        ]),
        // Rear Delts (Posterior Delts)
        _MuscleDefinition(MuscleGroup.posteriorDelts, [
          _MuscleNode(const Offset(108, 175), 22, 20),
          _MuscleNode(const Offset(272, 175), 22, 20),
        ]),
        // Triceps
        _MuscleDefinition(MuscleGroup.triceps, [
          _MuscleNode(const Offset(92, 230), 20, 34),
          _MuscleNode(const Offset(288, 230), 20, 34),
        ]),
        // Latissimus Dorsi (Lats)
        _MuscleDefinition(MuscleGroup.lats, [
          _MuscleNode(const Offset(146, 225), 34, 40),
          _MuscleNode(const Offset(234, 225), 34, 40),
        ]),
        // Lower Back (Erector Spinae)
        _MuscleDefinition(MuscleGroup.lowerBack, [
          _MuscleNode(const Offset(190, 275), 28, 24),
        ]),
        // Glutes
        _MuscleDefinition(MuscleGroup.glutes, [
          _MuscleNode(const Offset(154, 340), 32, 34),
          _MuscleNode(const Offset(226, 340), 32, 34),
        ]),
        // Hamstrings
        _MuscleDefinition(MuscleGroup.hamstrings, [
          _MuscleNode(const Offset(150, 435), 32, 58),
          _MuscleNode(const Offset(230, 435), 32, 58),
        ]),
        // Calves (Gastrocnemius & Soleus)
        _MuscleDefinition(MuscleGroup.calves, [
          _MuscleNode(const Offset(150, 560), 26, 50),
          _MuscleNode(const Offset(230, 560), 26, 50),
        ]),
      ];
    }
  }

  Color _getHeatColor(double activation) {
    if (activation >= 0.75) {
      return const Color(0xFFFF2A00); // Intense Thermo Flame
    } else if (activation >= 0.45) {
      return const Color(0xFFFF8500); // Amber Energy
    } else if (activation >= 0.20) {
      return const Color(0xFFFFB700); // Warm Gold
    } else {
      return const Color(0xFF00E5FF); // Resting Cyan
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final definitions = getMuscleDefinitions(isFront);

    for (final def in definitions) {
      final isSelected = selectedMuscle == def.muscle;
      final activation = activationMap[def.muscle] ?? (isSelected ? 0.90 : 0.0);

      if (activation <= 0.05 && !isSelected) continue;

      final baseColor = _getHeatColor(activation);
      final pulseFactor = isSelected ? (0.8 + 0.35 * pulseValue) : 1.0;
      final effectiveIntensity = (activation * pulseFactor).clamp(0.15, 1.0);

      for (final node in def.nodes) {
        canvas.save();
        canvas.translate(node.center.dx, node.center.dy);
        // Scale for elliptical shape
        canvas.scale(node.radiusX, node.radiusY);

        final radialPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            1.0,
            [
              baseColor.withValues(alpha: effectiveIntensity * 0.72),
              baseColor.withValues(alpha: effectiveIntensity * 0.38),
              baseColor.withValues(alpha: 0.0),
            ],
            [0.0, 0.55, 1.0],
          )
          ..blendMode = BlendMode.screen;

        canvas.drawCircle(Offset.zero, 1.0, radialPaint);

        if (isSelected) {
          // Luminous aura contour
          final borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.65 * pulseValue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.08 / node.radiusX;
          canvas.drawCircle(Offset.zero, 0.92, borderPaint);
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThermoHeatMapPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.activationMap != activationMap;
  }
}
