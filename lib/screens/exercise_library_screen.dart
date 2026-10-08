import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/anatomical_body_map.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  List<Exercise> _allExercises = [];
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    KineticTheme.themeModeNotifier.addListener(_onThemeChanged);
    _loadExercises();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    KineticTheme.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.instance.getAllExercises();
    if (!mounted) return;
    setState(() {
      _allExercises = list;
      _isLoading = false;
    });
  }

  List<Exercise> get _filteredExercises {
    return _allExercises.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.equipment.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.primaryMuscles.any((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCat = _selectedCategory == 'ALL' || e.category.toUpperCase() == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();
  }

  void _showAddCustomExerciseModal() {
    final nameCtrl = TextEditingController();
    final equipCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final instCtrl = TextEditingController();
    String category = 'Push';
    final List<MuscleGroup> selectedMuscles = [MuscleGroup.chest];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).padding.bottom;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + math.max(20.0, bottomInset + 14.0),
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REGISTER CUSTOM EXERCISE',
                          style: TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Exercise Name
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: KineticTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'EXERCISE NAME',
                        labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                        hintText: 'e.g. Incline Cable Flyes',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category Selector
                    Text('CATEGORY', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Push', 'Pull', 'Legs', 'Core'].map((c) {
                        final isSel = category == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSel,
                          selectedColor: AppTheme.accentOrange,
                          backgroundColor: AppTheme.cardBackground,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : KineticTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          ),
                          onSelected: (_) => setModalState(() => category = c),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Target Muscles
                    Text('PRIMARY MUSCLE GROUP', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        MuscleGroup.chest,
                        MuscleGroup.upperChest,
                        MuscleGroup.anteriorDelts,
                        MuscleGroup.lateralDelts,
                        MuscleGroup.triceps,
                        MuscleGroup.biceps,
                        MuscleGroup.lats,
                        MuscleGroup.traps,
                        MuscleGroup.quads,
                        MuscleGroup.hamstrings,
                        MuscleGroup.glutes,
                        MuscleGroup.calves,
                        MuscleGroup.abs,
                      ].map((m) {
                        final isSel = selectedMuscles.contains(m);
                        return FilterChip(
                          label: Text(m.displayName),
                          selected: isSel,
                          selectedColor: AppTheme.accentOrange,
                          backgroundColor: AppTheme.cardBackground,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : KineticTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedMuscles.add(m);
                              } else {
                                if (selectedMuscles.length > 1) {
                                  selectedMuscles.remove(m);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Equipment
                    TextField(
                      controller: equipCtrl,
                      style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'EQUIPMENT *',
                        labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                        hintText: 'e.g. Dumbbells',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sets, Reps, Weight
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: setsCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: 'SETS *',
                              labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                              hintText: 'e.g. 3',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              filled: true,
                              fillColor: AppTheme.cardBackground,
                              border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: repsCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: 'REPS *',
                              labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                              hintText: 'e.g. 10',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              filled: true,
                              fillColor: AppTheme.cardBackground,
                              border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: 'KG *',
                              labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                              hintText: 'e.g. 20.0',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              filled: true,
                              fillColor: AppTheme.cardBackground,
                              border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Instructions
                    TextField(
                      controller: instCtrl,
                      maxLines: 2,
                      style: TextStyle(color: KineticTheme.textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'COACHING CUES / FORM NOTES',
                        labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                        hintText: 'e.g. Keep chest high and squeeze at peak contraction.',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exercise name is mandatory')),
                          );
                          return;
                        }
                        if (equipCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Equipment field is mandatory (e.g. Dumbbells)')),
                          );
                          return;
                        }
                        final parsedSets = int.tryParse(setsCtrl.text.trim());
                        if (setsCtrl.text.trim().isEmpty || parsedSets == null || parsedSets <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sets count is mandatory (e.g. 3)')),
                          );
                          return;
                        }
                        final parsedReps = int.tryParse(repsCtrl.text.trim());
                        if (repsCtrl.text.trim().isEmpty || parsedReps == null || parsedReps <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reps count is mandatory (e.g. 10)')),
                          );
                          return;
                        }
                        final parsedWeight = double.tryParse(weightCtrl.text.trim());
                        if (weightCtrl.text.trim().isEmpty || parsedWeight == null || parsedWeight < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Weight in KG is mandatory (e.g. 20.0)')),
                          );
                          return;
                        }

                        final newEx = Exercise(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          category: category,
                          primaryMuscles: selectedMuscles,
                          secondaryMuscles: [],
                          equipment: equipCtrl.text.trim(),
                          instructions: instCtrl.text.trim().isEmpty ? 'Execute with controlled tempo.' : instCtrl.text.trim(),
                          defaultSets: parsedSets,
                          defaultReps: parsedReps,
                          defaultWeightKg: parsedWeight,
                        );

                        await DatabaseService.instance.addCustomExercise(newEx);
                        if (mounted) {
                          Navigator.of(context).pop();
                          _loadExercises();
                        }
                      },
                      child: const Text(
                        'REGISTER & SAVE EXERCISE',
                        style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExerciseDetailsModal(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      builder: (ctx) {
        final Map<MuscleGroup, double> activations = {};
        for (final m in exercise.primaryMuscles) {
          activations[m] = 0.9;
        }
        for (final m in exercise.secondaryMuscles) {
          activations[m] = 0.45;
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name.toUpperCase(),
                          style: TextStyle(color: KineticTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exercise.category.toUpperCase()} · ${exercise.equipment.toUpperCase()}',
                          style: const TextStyle(color: AppTheme.accentOrange, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Anatomy Map & Instructions
              Expanded(
                child: Row(
                  children: [
                    // Anatomy preview
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnatomicalBodyMap(
                          activationLevels: activations,
                          showBothViews: true,
                          height: 240,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details & Cues
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TARGETED MUSCLES', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: exercise.primaryMuscles.map((m) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  m.displayName.toUpperCase(),
                                  style: const TextStyle(color: AppTheme.accentOrange, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Text('DEFAULT PARAMETERS', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.defaultSets} SETS × ${exercise.defaultReps} REPS @ ${exercise.defaultWeightKg} KG',
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 14),
                          Text('TECHNIQUE CUES', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                exercise.instructions,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'EXERCISE CATALOG // LIBRARY',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            fontFamily: 'monospace',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.divider, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'CUSTOM EXERCISE',
          style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 1.0),
        ),
        onPressed: _showAddCustomExerciseModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange))
          : Column(
              children: [
                // Top Search & Category Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  color: AppTheme.surfaceDark,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'SEARCH EXERCISES OR MUSCLE GROUPS...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                          filled: true,
                          fillColor: AppTheme.cardBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: AppTheme.accentOrange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'PUSH', 'PULL', 'LEGS', 'CORE'].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                selectedColor: AppTheme.accentOrange,
                                backgroundColor: AppTheme.cardBackground,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.black : KineticTheme.textPrimary,
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: AppTheme.cardBorder, height: 1),

                // Exercise List
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? Center(
                          child: Text(
                            'NO EXERCISES MATCH CRITERIA',
                            style: TextStyle(color: AppTheme.textMuted, fontFamily: 'monospace', fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (ctx, i) {
                            final ex = _filteredExercises[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: ListTile(
                                onTap: () => _showExerciseDetailsModal(ex),
                                title: Text(
                                  ex.name,
                                  style: TextStyle(color: KineticTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ex.category.toUpperCase()} · ${ex.equipment.toUpperCase()} · ${ex.defaultSets}S × ${ex.defaultReps}R @ ${ex.defaultWeightKg}KG',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: ex.primaryMuscles.map((m) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cardBackground,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            m.displayName.toUpperCase(),
                                            style: const TextStyle(
                                              color: AppTheme.accentOrange,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
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
