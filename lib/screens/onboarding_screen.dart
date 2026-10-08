import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing;
  final UserProfile? initialProfile;

  const OnboardingScreen({
    Key? key,
    this.isEditing = false,
    this.initialProfile,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String _selectedGender = 'male';
  String _selectedGoal = 'gain_muscle';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _ageController = TextEditingController(text: p != null ? p.age.toString() : '');
    _weightController = TextEditingController(text: p != null ? p.weightKg.toStringAsFixed(1) : '');
    _heightController = TextEditingController(text: p != null ? p.heightCm.toStringAsFixed(0) : '');
    _selectedGender = p?.gender ?? 'male';
    _selectedGoal = p?.goal ?? 'gain_muscle';

    _ageController.addListener(() => setState(() {}));
    _weightController.addListener(() => setState(() {}));
    _heightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double get _currentWeight => double.tryParse(_weightController.text) ?? 75.0;
  double get _currentHeight => double.tryParse(_heightController.text) ?? 175.0;
  int get _currentAge => int.tryParse(_ageController.text) ?? 25;

  int get _computedCalories => UserProfile.calculateDefaultCalories(
        _currentWeight,
        _currentHeight,
        _currentAge,
        _selectedGoal,
        gender: _selectedGender,
      );

  double get _computedBmi {
    if (_currentHeight <= 0) return 0;
    return _currentWeight / ((_currentHeight / 100.0) * (_currentHeight / 100.0));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final profile = UserProfile(
        id: widget.initialProfile?.id ?? 'current_user',
        name: _nameController.text.trim().isEmpty ? 'Athlete' : _nameController.text.trim(),
        age: _currentAge,
        weightKg: _currentWeight,
        heightCm: _currentHeight,
        gender: _selectedGender,
        goal: _selectedGoal,
        dailyCalorieTarget: _computedCalories,
        isOnboarded: true,
        createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
      );

      await DatabaseService.instance.saveUserProfile(profile);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell(showWelcomeTour: true)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: widget.isEditing
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: KineticTheme.textPrimary, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          widget.isEditing ? 'EDIT PROFILE // IDENTITY' : 'INITIAL SETUP // ONBOARDING',
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // System Badge Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'BIO-DATA PROFILE CONFIGURATION',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              _buildInputLabel('ATHLETE NAME / IDENTIFIER', '01'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. John',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),

              const SizedBox(height: 20),

              // Gender Selection
              _buildInputLabel('BIOLOGICAL GENDER / BASE MODEL', '02'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      title: 'MALE',
                      subtitle: 'Alpha Base Mesh',
                      icon: Icons.male,
                      value: 'male',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      title: 'FEMALE',
                      subtitle: 'Beta Base Mesh',
                      icon: Icons.female,
                      value: 'female',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Age & Weight in 2 columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('AGE', '03'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _ageController,
                          hint: 'e.g. 25',
                          icon: Icons.cake_outlined,
                          isNumeric: true,
                          suffix: 'YRS',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Age is required';
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 12 || n > 110) return 'Age: 12-110';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('WEIGHT', '04'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _weightController,
                          hint: 'e.g. 75.0',
                          icon: Icons.monitor_weight_outlined,
                          isNumeric: true,
                          suffix: 'KG',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Weight is required';
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 30 || n > 350) return 'Weight: 30-350 kg';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Height Field
              _buildInputLabel('HEIGHT', '05'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _heightController,
                hint: 'e.g. 178',
                icon: Icons.height_outlined,
                isNumeric: true,
                suffix: 'CM',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Height is required';
                  final n = double.tryParse(val.trim());
                  if (n == null || n < 100 || n > 250) return 'Height: 100-250 cm';
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Goal Selection
              _buildInputLabel('PRIMARY TRAINING OBJECTIVE', '06'),
              const SizedBox(height: 12),
              _buildGoalOption(
                goalKey: 'gain_muscle',
                title: 'GAIN MUSCLE & BULK',
                badge: '+350 KCAL SURPLUS',
                accentColor: AppTheme.accentOrange,
                description: 'Hypertrophic progressive overload for maximum lean mass accretion.',
              ),
              const SizedBox(height: 10),
              _buildGoalOption(
                goalKey: 'lose_fat',
                title: 'LOSE FAT & DEFICIT',
                badge: '-450 KCAL DEFICIT',
                accentColor: const Color(0xFF00E5FF),
                description: 'Caloric restriction targeted at body fat reduction while preserving lean tissue.',
              ),
              const SizedBox(height: 10),
              _buildGoalOption(
                goalKey: 'maintain',
                title: 'MAINTAIN STATS & RECOMP',
                badge: '±0 KCAL EQUILIBRIUM',
                accentColor: AppTheme.accentGreen,
                description: 'Iso-caloric balance to optimize neuromuscular strength, speed, and recovery.',
              ),

              const SizedBox(height: 28),

              // Real-Time Metrics Blueprint Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate_outlined, color: AppTheme.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ESTIMATED METABOLIC TELEMETRY',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricMini('DAILY TARGET', '$_computedCalories', 'KCAL/DAY', AppTheme.accentOrange),
                        _buildMetricMini('BMI INDEX', _computedBmi.toStringAsFixed(1), 'INDEX', AppTheme.accentGreen),
                        _buildMetricMini('WEIGHT', '$_currentWeight', 'KG', KineticTheme.textPrimary),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save / Continue Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.isEditing ? Icons.check : Icons.arrow_forward, size: 18, color: Colors.black),
                          const SizedBox(width: 10),
                          Text(
                            widget.isEditing ? 'UPDATE PROFILE & SAVE' : 'INITIALIZE PROFILE & LAUNCH',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String title, String index) {
    return Row(
      children: [
        Text(
          '[$index] ',
          style: const TextStyle(
            color: AppTheme.accentOrange,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumeric = false,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      style: TextStyle(
        color: KineticTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.cardBackground,
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppTheme.accentOrange,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide: const BorderSide(color: AppTheme.accentOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildGoalOption({
    required String goalKey,
    required String title,
    required String badge,
    required Color accentColor,
    required String description,
  }) {
    final isSelected = _selectedGoal == goalKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goalKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.1) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : AppTheme.textMuted,
                      width: 2,
                    ),
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? KineticTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                description,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedGender == value;
    final accentColor = isSelected ? AppTheme.accentOrange : AppTheme.cardBorder;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentOrange.withValues(alpha: 0.1) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: accentColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.accentOrange : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? KineticTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMini(String label, String value, String unit, Color highlightColor) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
