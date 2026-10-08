import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/nutrition_service.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_progress_bar.dart';

class FoodTrackerScreen extends StatefulWidget {
  const FoodTrackerScreen({Key? key}) : super(key: key);

  @override
  State<FoodTrackerScreen> createState() => _FoodTrackerScreenState();
}

class _FoodTrackerScreenState extends State<FoodTrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  List<FoodEntry> _foodEntries = [];
  UserProfile? _userProfile;
  bool _isLoading = true;

  final List<String> _quickSuggestions = [
    'Chicken Breast (200g)',
    'Eggs & Toast',
    'Oatmeal & Whey',
    'Greek Yogurt with Berries',
    'White Rice & Ground Beef',
    'Banana with Peanut Butter',
    'Whey Protein Shake',
    'Salmon with Sweet Potato',
  ];

  @override
  void initState() {
    super.initState();
    DatabaseService.dataChangeNotifier.addListener(_onDataChanged);
    _loadData(showSpinner: true);
  }

  void _onDataChanged() {
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  @override
  void dispose() {
    DatabaseService.dataChangeNotifier.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  String get _dateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadData({bool showSpinner = false}) async {
    if (showSpinner) setState(() => _isLoading = true);
    final profile = await DatabaseService.instance.getUserProfile();
    final entries = await DatabaseService.instance.getFoodEntriesForDate(_dateString);
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _foodEntries = entries;
      _isLoading = false;
    });
  }

  int get _consumedCalories => _foodEntries.fold(0, (sum, e) => sum + e.calories);
  double get _consumedProtein => _foodEntries.fold(0.0, (sum, e) => sum + e.proteinG);
  double get _consumedCarbs => _foodEntries.fold(0.0, (sum, e) => sum + e.carbsG);
  double get _consumedFat => _foodEntries.fold(0.0, (sum, e) => sum + e.fatG);

  int get _targetCalories => _userProfile?.dailyCalorieTarget ?? 2600;
  double get _targetProtein => (_userProfile?.weightKg ?? 80.0) * 2.2; // 2.2g per kg
  double get _targetFat => (_targetCalories * 0.25) / 9.0;
  double get _targetCarbs => (_targetCalories - (_targetProtein * 4.0) - (_targetFat * 9.0)) / 4.0;

  void _promptAddFood([String? initialQuery]) async {
    final query = initialQuery ?? _searchController.text.trim();
    if (query.isEmpty) return;

    final estimate = await NutritionService.instance.estimateCaloriesAndMacros(query);
    if (!mounted) return;
    _showVerificationModal(estimate);
  }

  void _showVerificationModal(EstimatedNutrition estimate) {
    double portionMultiplier = 1.0;
    String selectedMeal = 'Lunch';
    final nameCtrl = TextEditingController(text: estimate.foodName);
    final calCtrl = TextEditingController(text: estimate.calories.toString());
    final protCtrl = TextEditingController(text: estimate.proteinG.toStringAsFixed(1));
    final carbCtrl = TextEditingController(text: estimate.carbsG.toStringAsFixed(1));
    final fatCtrl = TextEditingController(text: estimate.fatG.toStringAsFixed(1));

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
            void updateMultiplier(double mult) {
              setModalState(() {
                portionMultiplier = mult;
                calCtrl.text = (estimate.calories * mult).round().toString();
                protCtrl.text = (estimate.proteinG * mult).toStringAsFixed(1);
                carbCtrl.text = (estimate.carbsG * mult).toStringAsFixed(1);
                fatCtrl.text = (estimate.fatG * mult).toStringAsFixed(1);
              });
            }

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
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: const Text(
                            'VERIFY & LOG NUTRITION',
                            style: TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            estimate.source.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Food Name Field
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: KineticTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'ITEM DESCRIPTION',
                        labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Meal Type Selector
                    Text(
                      'MEAL CATEGORY',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Pre-Workout', 'Post-Workout'].map((m) {
                        final isSel = selectedMeal == m;
                        return ChoiceChip(
                          label: Text(m),
                          selected: isSel,
                          selectedColor: AppTheme.accentOrange,
                          backgroundColor: AppTheme.cardBackground,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : KineticTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          ),
                          onSelected: (_) => setModalState(() => selectedMeal = m),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Portion Multiplier
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PORTION SCALE',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1.2),
                        ),
                        Row(
                          children: [0.5, 1.0, 1.5, 2.0].map((scale) {
                            final isSel = portionMultiplier == scale;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () => updateMultiplier(scale),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppTheme.accentOrange : AppTheme.cardBackground,
                                    border: Border.all(color: isSel ? AppTheme.accentOrange : AppTheme.cardBorder),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${scale}x',
                                    style: TextStyle(
                                      color: isSel ? Colors.black : KineticTheme.textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Nutrient inputs
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniNumInput('CALORIES', calCtrl, 'KCAL', AppTheme.accentOrange),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniNumInput('PROTEIN', protCtrl, 'G', const Color(0xFF00E5FF)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniNumInput('CARBS', carbCtrl, 'G', AppTheme.accentGreen),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniNumInput('FAT', fatCtrl, 'G', Colors.amberAccent),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              side: BorderSide(color: AppTheme.cardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('DISCARD', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final entry = FoodEntry(
                                id: 'food_${DateTime.now().millisecondsSinceEpoch}',
                                dateString: _dateString,
                                mealType: selectedMeal,
                                foodName: nameCtrl.text.trim(),
                                calories: int.tryParse(calCtrl.text) ?? estimate.calories,
                                proteinG: double.tryParse(protCtrl.text) ?? estimate.proteinG,
                                carbsG: double.tryParse(carbCtrl.text) ?? estimate.carbsG,
                                fatG: double.tryParse(fatCtrl.text) ?? estimate.fatG,
                              );
                              await DatabaseService.instance.addFoodEntry(entry);
                              if (mounted) {
                                Navigator.of(context).pop();
                                _searchController.clear();
                                _loadData();
                              }
                            },
                            child: const Text(
                              'CONFIRM & LOG MEAL',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildMiniNumInput(String label, TextEditingController ctrl, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            filled: true,
            fillColor: AppTheme.cardBackground,
            suffixText: unit,
            suffixStyle: TextStyle(color: AppTheme.textMuted, fontSize: 8),
            border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cardBorder)),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteEntry(String id) async {
    await DatabaseService.instance.deleteFoodEntry(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final calorieRatio = (_consumedCalories / _targetCalories).clamp(0.0, 1.0);
    final remainingCalories = (_targetCalories - _consumedCalories).clamp(0, 9999);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'NUTRITION & MACROS // LOG',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // Date Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: KineticTheme.textPrimary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                        _loadData();
                      },
                    ),
                    Text(
                      DateFormat('EEE, MMM dd, yyyy').format(_selectedDate).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: KineticTheme.textPrimary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        _loadData();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Caloric HUD Dashboard Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL CALORIC INTAKE',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_consumedCalories',
                                    style: TextStyle(
                                      color: KineticTheme.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    ' / $_targetCalories KCAL',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'REMAINING',
                                  style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$remainingCalories',
                                  style: const TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Animated Breathing Progress Bar with Hatch Pattern
                      BreathingProgressBar(
                        value: calorieRatio,
                        height: 10,
                        color: calorieRatio > 1.0 ? KineticTheme.accentCrimson : KineticTheme.accentFlame,
                        backgroundColor: KineticTheme.bgSurfaceElevated,
                        showStripes: true,
                        showLeadingBeacon: true,
                      ),

                      const SizedBox(height: 16),

                      // Macro Split Rows
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroPill(
                              'PROTEIN',
                              _consumedProtein,
                              _targetProtein,
                              'G',
                              const Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroPill(
                              'CARBS',
                              _consumedCarbs,
                              _targetCarbs,
                              'G',
                              AppTheme.accentGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroPill(
                              'FATS',
                              _consumedFat,
                              _targetFat,
                              'G',
                              Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search & Log Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (val) => _promptAddFood(val),
                        style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'ENTER FOOD / BEVERAGE (E.G. CHICKEN BREAST)',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => _promptAddFood(),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quick Suggestion Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickSuggestions.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(item),
                          backgroundColor: AppTheme.surfaceDark,
                          side: BorderSide(color: AppTheme.cardBorder),
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                          onPressed: () => _promptAddFood(item),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Meals Logged Today List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAILY INGESTION LOG',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '${_foodEntries.length} ITEMS LOGGED',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_foodEntries.isEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu_outlined, color: AppTheme.textMuted, size: 36),
                        SizedBox(height: 12),
                        Text(
                          'NO MEALS LOGGED FOR THIS DATE',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter an item above to estimate calories & macros.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                else
                  ..._foodEntries.map((entry) {
                    return Dismissible(
                      key: ValueKey('food_entry_${entry.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'PURGE',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                          ],
                        ),
                      ),
                      onDismissed: (_) => _deleteEntry(entry.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 36,
                              color: AppTheme.accentOrange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardBackground,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          entry.mealType.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.accentOrange,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.foodName,
                                          style: TextStyle(
                                            color: KineticTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'P: ${entry.proteinG.toStringAsFixed(1)}g  ·  C: ${entry.carbsG.toStringAsFixed(1)}g  ·  F: ${entry.fatG.toStringAsFixed(1)}g',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.calories}',
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  'KCAL',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                              onPressed: () => _deleteEntry(entry.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                SizedBox(height: math.max(120.0, 96.0 + MediaQuery.of(context).padding.bottom)),
              ],
            ),
    );
  }

  Widget _buildMacroPill(String title, double current, double target, String unit, Color color) {
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '${(ratio * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
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
                current.toStringAsFixed(0),
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                ' / ${target.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BreathingProgressBar(
            value: ratio,
            height: 5,
            color: color,
            backgroundColor: KineticTheme.bgSurfaceElevated,
            showStripes: true,
            showLeadingBeacon: false,
          ),
        ],
      ),
    );
  }
}
