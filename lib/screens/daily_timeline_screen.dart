import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_routine_item.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class DailyTimelineScreen extends StatefulWidget {
  const DailyTimelineScreen({Key? key}) : super(key: key);

  @override
  State<DailyTimelineScreen> createState() => _DailyTimelineScreenState();
}

class _DailyTimelineScreenState extends State<DailyTimelineScreen> with SingleTickerProviderStateMixin {
  List<DailyRoutineItem> _items = [];
  bool _isLoading = true;
  late DateTime _selectedDate;
  late DateTime _weekStart;
  late AnimationController _gaugeAnimController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Find Monday of current week
    final daysSinceMonday = (_selectedDate.weekday - DateTime.monday) % 7;
    _weekStart = _selectedDate.subtract(Duration(days: daysSinceMonday));

    _gaugeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeAnimController,
      curve: Curves.easeOutCubic,
    );
    _gaugeAnimController.forward();

    DatabaseService.dataChangeNotifier.addListener(_loadItemsForSelectedDate);
    _loadItemsForSelectedDate();
  }

  @override
  void dispose() {
    DatabaseService.dataChangeNotifier.removeListener(_loadItemsForSelectedDate);
    _gaugeAnimController.dispose();
    super.dispose();
  }

  String _dateToString(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  Future<void> _loadItemsForSelectedDate() async {
    setState(() => _isLoading = true);
    final dateStr = _dateToString(_selectedDate);
    final items = await DatabaseService.instance.getRoutineItemsForDate(dateStr);

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(DailyRoutineItem item) async {
    final updated = !item.isCompleted;
    await DatabaseService.instance.toggleRoutineItem(item.id, updated);
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _items[idx] = item.copyWith(isCompleted: updated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: KineticTheme.accentFlame))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // 7-Day Field OS Horizon Selector
                    _build7DaySelector(),
                    const SizedBox(height: 16),

                    // Daily Readiness & Bio-Marker Gauge Card
                    _buildReadinessGaugeCard(),
                    const SizedBox(height: 20),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timeline, size: 16, color: KineticTheme.accentFlame),
                            SizedBox(width: 6),
                            Text(
                              'CIRCADIAN PROTOCOL SCHEDULE',
                              style: TextStyle(
                                color: KineticTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDate).toUpperCase(),
                          style: TextStyle(
                            color: KineticTheme.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Connected Vertical Timeline
                    _buildConnectedTimeline(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final completedCount = _items.where((i) => i.isCompleted).length;
    final totalCount = _items.length;
    final percent = totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  'FIELD OS // DAILY PROTOCOL',
                  style: TextStyle(
                    color: KineticTheme.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Routine & Flow',
              style: TextStyle(
                color: KineticTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: KineticTheme.accentJade.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: KineticTheme.accentJade.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: KineticTheme.accentJade),
              const SizedBox(width: 6),
              Text(
                '$completedCount / $totalCount ($percent%)',
                style: const TextStyle(
                  color: KineticTheme.accentJade,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build7DaySelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = _weekStart.add(Duration(days: index));
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;
          final dayName = DateFormat('E').format(date).toUpperCase();
          final dayNum = date.day.toString();

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
                _loadItemsForSelectedDate();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? KineticTheme.accentFlame
                      : (isToday ? KineticTheme.accentFlame.withValues(alpha: 0.08) : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? KineticTheme.accentFlame
                        : (isToday ? KineticTheme.accentFlame.withValues(alpha: 0.4) : Colors.transparent),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : KineticTheme.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNum,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday ? KineticTheme.accentFlame : KineticTheme.textPrimary),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? KineticTheme.accentFlame
                            : (isToday ? KineticTheme.accentFlame : Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReadinessGaugeCard() {
    final completedCount = _items.where((i) => i.isCompleted).length;
    final totalCount = _items.length;
    final percent = totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Readiness Score Dial
          AnimatedBuilder(
            animation: _gaugeAnimation,
            builder: (context, _) {
              return SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(82, 82),
                      painter: _ReadinessGaugePainter(
                        progress: totalCount == 0 ? 0.0 : (completedCount / totalCount) * _gaugeAnimation.value,
                        activeColor: KineticTheme.accentFlame,
                        trackColor: KineticTheme.borderFaint,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalCount == 0 ? '--' : '${(percent * _gaugeAnimation.value).toInt()}%',
                          style: TextStyle(
                            color: KineticTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          totalCount == 0 ? 'NO DATA' : 'READY',
                          style: TextStyle(
                            color: KineticTheme.textTertiary,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Bio-Markers & Strategy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      totalCount == 0 ? Icons.info_outline : Icons.bolt_rounded,
                      size: 14,
                      color: totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentFlame,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalCount == 0 ? 'NO PROTOCOL LOGGED' : 'OPTIMAL PROTOCOL ALIGNMENT',
                      style: TextStyle(
                        color: totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentFlame,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: totalCount == 0
                            ? KineticTheme.bgSurfaceElevated
                            : KineticTheme.accentJade.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        totalCount == 0 ? 'BASELINE' : 'ZONE 1 RECOVERY',
                        style: TextStyle(
                          color: totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentJade,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  totalCount == 0
                      ? 'No circadian protocol active for this date'
                      : 'Hypertrophy Overload + Thermal Contrast',
                  style: TextStyle(
                    color: KineticTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMicroStat(
                      'HRV',
                      totalCount == 0 ? '--' : '78 ms',
                      totalCount == 0 ? 'PENDING' : '+12%',
                      totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentJade,
                    ),
                    const SizedBox(width: 14),
                    _buildMicroStat(
                      'SLEEP',
                      totalCount == 0 ? '--' : '8.2 hrs',
                      totalCount == 0 ? 'OFFLINE' : '91% Q',
                      totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentCyan,
                    ),
                    const SizedBox(width: 14),
                    _buildMicroStat(
                      'HYDRATE',
                      totalCount == 0 ? '--' : '2.8 / 3.5 L',
                      totalCount == 0 ? 'STANDBY' : '80%',
                      totalCount == 0 ? KineticTheme.textTertiary : KineticTheme.accentAmber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroStat(String label, String value, String tag, Color tagColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: KineticTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectedTimeline() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        alignment: Alignment.center,
        decoration: KineticTheme.cardDecoration(
          backgroundColor: KineticTheme.bgSurface,
          border: Border.all(color: KineticTheme.borderMedium),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule_rounded, color: KineticTheme.textTertiary, size: 36),
            SizedBox(height: 10),
            Text(
              'NO PROTOCOL ITEMS SCHEDULED',
              style: TextStyle(
                color: KineticTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Circadian events and habits will appear here once logged or imported.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KineticTheme.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isLast = index == _items.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timestamp column
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    item.time,
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              // Rail and Node
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // Node icon circle
                    GestureDetector(
                      onTap: () => _toggleItem(item),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.isCompleted ? KineticTheme.accentJade : KineticTheme.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.isCompleted ? KineticTheme.accentJade : KineticTheme.borderMedium,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            item.isCompleted ? Icons.check : _getIcon(item.iconKey),
                            size: 14,
                            color: item.isCompleted ? Colors.white : Color(item.colorValue),
                          ),
                        ),
                      ),
                    ),
                    // Rail Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: KineticTheme.borderMedium,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _toggleItem(item),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: KineticTheme.cardDecoration(
                        backgroundColor: item.isCompleted ? KineticTheme.bgSurfaceElevated : KineticTheme.bgSurface,
                        border: Border.all(
                          color: item.isCompleted
                              ? KineticTheme.accentJade.withValues(alpha: 0.35)
                              : KineticTheme.borderMedium,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: item.isCompleted ? KineticTheme.textSecondary : KineticTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (item.category == 'workout')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KineticTheme.accentFlame.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'WORKOUT',
                                    style: TextStyle(
                                      color: KineticTheme.accentFlame,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (item.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: item.isCompleted ? KineticTheme.textTertiary : KineticTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          // Macro Pill indicators
                          if (item.macroProteinG != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildMacroPill('P', '${item.macroProteinG!.toInt()}g', Colors.blue),
                                const SizedBox(width: 6),
                                _buildMacroPill('C', '${item.macroCarbsG!.toInt()}g', Colors.teal),
                                const SizedBox(width: 6),
                                _buildMacroPill('F', '${item.macroFatG!.toInt()}g', Colors.orange),
                                if (item.calories != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.calories} kcal',
                                    style: TextStyle(
                                      color: KineticTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroPill(String code, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'sun':
        return Icons.whatshot_rounded;
      case 'snowflake':
        return Icons.ac_unit_rounded;
      case 'moon':
        return Icons.nightlight_round;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _ReadinessGaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _ReadinessGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReadinessGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
