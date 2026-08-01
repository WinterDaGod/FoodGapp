import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_nutrition.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../models/fasting_session.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/fasting_service.dart';
import '../services/app_events.dart';
import '../services/gamification_service.dart';
import '../services/unit_converter.dart';
import '../services/sound_service.dart';
import 'widgets/app_loading.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  final _fastingService = FastingService();

  UserProfile? _profile;
  List<DailyNutrition> _nutritionHistory = [];
  List<Map<String, dynamic>> _waterHistory = [];
  List<FastingSession> _fastingHistory = [];
  Map<String, dynamic> _streakInfo = {'current': 0, 'best': 0};
  bool _isLoading = true;
  String _selectedTimeFilter = 'This week';

  @override
  void initState() {
    super.initState();
    _loadData();
    AppEvents.instance.mealChanged.addListener(_loadData);
    AppEvents.instance.weightChanged.addListener(_loadData);
    AppEvents.instance.profileChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    AppEvents.instance.mealChanged.removeListener(_loadData);
    AppEvents.instance.weightChanged.removeListener(_loadData);
    AppEvents.instance.profileChanged.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    int days = 7;
    if (_selectedTimeFilter == '1 month') days = 30;
    if (_selectedTimeFilter == '6 months') days = 180;

    final profile = await _db.getUserProfile(userId);
    final nutrition = await _db.getNutritionHistory(userId, days);
    final water = await _db.getWaterHistory(userId, days);
    final fasting = await _fastingService.getHistory();
    final streak = await GamificationService.instance.getStreakInfo();

    if (mounted) {
      setState(() {
        _profile = profile;
        _nutritionHistory = nutrition;
        _waterHistory = water;
        _fastingHistory = fasting;
        _streakInfo = streak;
        _isLoading = false;
      });
    }
  }

  double _calculateBmi() {
    if (_profile == null || _profile!.heightCm == null || _profile!.heightCm! <= 0) return 0;
    final heightM = _profile!.heightCm! / 100;
    return (_profile!.weightKg ?? 0) / (heightM * heightM);
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'UNDERWEIGHT';
    if (bmi < 23.0) return 'HEALTHY';
    if (bmi < 25.0) return 'OVERWEIGHT';
    return 'OBESE';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 23.0) return Colors.greenAccent;
    if (bmi < 25.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Future<void> _updateWeight() async {
    final system = _profile?.unitSystem ?? 'Metric';
    final currentVal = UnitConverter.fromMetric(_profile?.weightKg ?? 0.0, system, 'weight');
    final controller = TextEditingController(text: currentVal.toStringAsFixed(1));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = system == 'Imperial' ? 'lbs' : 'kg';

    final newWeightInput = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Update Weight', 
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black
                  )
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                boxShadow: !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black, 
                        fontSize: 48, 
                        fontWeight: FontWeight.bold
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0.0',
                        hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                  ),
                  Text(
                    unit, 
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (newWeightInput != null && _profile != null) {
      final metricWeight = UnitConverter.toMetric(newWeightInput, system, 'weight');
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _db.insertWeightLog(WeightLog(
        userId: _profile!.userId,
        date: dateStr,
        weightKg: metricWeight,
      ));
      
      SoundService.instance.playSuccess();
      
      AppEvents.instance.notifyWeightChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: AppLoading());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildGamificationCard(),
              const SizedBox(height: 32),
              _buildMacroAveragesCard(),
              const SizedBox(height: 32),
              _buildJourneyCard(),
              const SizedBox(height: 32),
              _buildBmiCard(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress', 
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'See your trend over time', 
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: !isDark ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
                boxShadow: !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: const Icon(Icons.trending_up, color: Colors.teal),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -40,
            child: Text(
              'F', 
              style: TextStyle(
                fontSize: 120, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = _streakInfo['current'] as int? ?? 0;
    final bestStreak = _streakInfo['best'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF2C1A0F), const Color(0xFF1E1E1E)] 
            : [const Color(0xFFFFF3E0), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
        border: Border.all(
          color: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Streak', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    )
                  ),
                  Text(
                    'Keep logging to grow your flame!', 
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStreakStat(
                  'CURRENT STREAK', 
                  currentStreak.toString(), 
                  'days', 
                  Colors.orange, 
                  isDark
                ),
              ),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              Expanded(
                child: _buildStreakStat(
                  'BEST STREAK', 
                  bestStreak.toString(), 
                  'days', 
                  isDark ? Colors.white70 : Colors.black54, 
                  isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStreakMilestoneProgress(currentStreak, isDark),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, String unit, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white24 : Colors.black26,
            letterSpacing: 1.1,
          )
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)
            ),
            const SizedBox(width: 4),
            Text(
              unit, 
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white24 : Colors.black26)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakMilestoneProgress(int current, bool isDark) {
    // Calculate next milestone (e.g. 3, 7, 14, 30, 50, 100...)
    final milestones = [3, 7, 14, 30, 50, 100, 365];
    int nextMilestone = milestones.firstWhere((m) => m > current, orElse: () => 1000);
    int prevMilestone = milestones.lastWhere((m) => m <= current, orElse: () => 0);
    
    double progress = (current - prevMilestone) / (nextMilestone - prevMilestone);
    progress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next Milestone: $nextMilestone days', 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white38 : Colors.black45
              )
            ),
            Text(
              '${(progress * 100).round()}%', 
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? Colors.white24 : Colors.black26
              )
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroAveragesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate averages for current period
    double avgCal = 0, avgProt = 0, avgCarb = 0, avgFat = 0;
    int days = _nutritionHistory.length;
    if (days > 0) {
      avgCal = _nutritionHistory.fold(0.0, (sum, n) => sum + n.calories) / days;
      avgProt = _nutritionHistory.fold(0.0, (sum, n) => sum + n.protein) / days;
      avgCarb = _nutritionHistory.fold(0.0, (sum, n) => sum + n.carbs) / days;
      avgFat = _nutritionHistory.fold(0.0, (sum, n) => sum + n.fat) / days;
    }

    double avgWaterMl = 0;
    if (_waterHistory.isNotEmpty) {
      avgWaterMl = _waterHistory.fold(0.0, (sum, w) => sum + (w['amount_ml'] as num)) / _waterHistory.length;
    }
    final avgCups = (avgWaterMl / 250).round();

    double totalFastingHours = 0;
    int fastingDays = 7;
    if (_selectedTimeFilter == '1 month') fastingDays = 30;
    if (_selectedTimeFilter == '6 months') fastingDays = 180;
    
    final now = DateTime.now();
    final filterStart = now.subtract(Duration(days: fastingDays));
    final periodFasts = _fastingHistory.where((f) => f.startTime.isAfter(filterStart)).toList();
    if (periodFasts.isNotEmpty) {
      totalFastingHours = periodFasts.fold(0.0, (sum, f) => sum + f.elapsedHours);
    }
    final avgFasting = totalFastingHours / fastingDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro\'s average', 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            )
          ),
          const SizedBox(height: 20),
          _buildTimeFilterRow(),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroAvgItem('CALORIES', avgCal.round().toString(), Colors.orangeAccent),
              _buildVerticalDivider(isDark),
              _buildMacroAvgItem('PROTEIN', '${avgProt.round()}g', Colors.redAccent),
              _buildVerticalDivider(isDark),
              _buildMacroAvgItem('CARBS', '${avgCarb.round()}g', Colors.blueAccent),
              _buildVerticalDivider(isDark),
              _buildMacroAvgItem('FATS', '${avgFat.round()}g', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                const CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent), 
                const SizedBox(width: 8), 
                CircleAvatar(radius: 4, backgroundColor: isDark ? Colors.white10 : Colors.black12), 
                const SizedBox(width: 8), 
                CircleAvatar(radius: 4, backgroundColor: isDark ? Colors.white10 : Colors.black12)
              ]
            )
          ),
          const SizedBox(height: 32),
          Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSecondaryAvgItem('WATER', avgCups.toString(), 'cups', Colors.blueAccent),
              _buildVerticalDivider(isDark),
              _buildSecondaryAvgItem('FASTING', '${avgFasting.toStringAsFixed(1)}h', 'avg', Colors.redAccent),
              _buildVerticalDivider(isDark),
              _buildSecondaryAvgItem('STEPS', '0', 'avg', Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['This week', 'Last week', '1 month', '6 months'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedTimeFilter == f,
            onSelected: (val) {
              setState(() => _selectedTimeFilter = f);
              _loadData();
            },
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            selectedColor: isDark ? Colors.white : Colors.black,
            labelStyle: TextStyle(
              color: _selectedTimeFilter == f 
                  ? (isDark ? Colors.black : Colors.white) 
                  : (isDark ? Colors.white38 : Colors.black45),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMacroAvgItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45)),
        Text('avg / day', style: TextStyle(fontSize: 10, color: isDark ? Colors.white12 : Colors.black26)),
      ],
    );
  }

  Widget _buildSecondaryAvgItem(String label, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const TextSpan(text: ' '),
              TextSpan(text: unit, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
  }

  Widget _buildJourneyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _profile?.weightKg ?? 0.0;
    final target = _profile?.targetWeightKg ?? 0.0;
    
    return FutureBuilder<double?>(
      future: _db.getStartingWeight(_auth.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final starting = snapshot.data ?? current;
        final remaining = (current - target).abs();
        final weightUnit = _profile?.unitSystem == 'Imperial' ? 'lbs' : 'kg';
        final system = _profile?.unitSystem ?? 'Metric';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Journey', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              const SizedBox(height: 4),
              Text(
                'Every step brings you closer to your goal.', 
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)
              ),
              const SizedBox(height: 32),
              _buildJourneyChart(starting, current, target),
              const SizedBox(height: 48),
              Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildJourneyStat('STARTING', UnitConverter.fromMetric(starting, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('CURRENT', UnitConverter.fromMetric(current, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('GOAL', UnitConverter.fromMetric(target, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('REMAINING', UnitConverter.fromMetric(remaining, system, 'weight'), weightUnit, isDark),
                ],
              ),
              const SizedBox(height: 32),
              Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 24),
              _buildTimelineTile(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _updateWeight,
                  child: Text(
                    'LOG WEIGHT', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.5, 
                      color: isDark ? Colors.white70 : Colors.black54
                    )
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Keeps your BMI, & progress up to date.',
                  style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 11)
                )
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTimelineTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _profile?.weightKg ?? 0;
    final target = _profile?.targetWeightKg ?? 0;
    final paceStr = _profile?.goalPace ?? '';
    
    String message = 'On pace to reach your goal by';
    String dateDisplay = '---';
    bool isComplete = false;

    if (target <= 0 || paceStr.isEmpty) {
      message = 'Set a goal weight and pace';
      dateDisplay = 'to see your timeline';
    } else {
      final diff = (current - target).abs();
      if (diff < 0.1) {
        message = 'Amazing work!';
        dateDisplay = 'Goal weight reached';
        isComplete = true;
      } else {
        final match = RegExp(r'[\d.]+').firstMatch(paceStr);
        final weeklyPace = match != null ? double.tryParse(match.group(0)!) ?? 0.0 : 0.0;
        
        if (weeklyPace <= 0) {
          message = 'Maintaining your';
          dateDisplay = 'current healthy weight';
        } else {
          final weeks = diff / weeklyPace;
          final targetDate = DateTime.now().add(Duration(days: (weeks * 7).round()));
          dateDisplay = DateFormat('MMMM d, yyyy').format(targetDate);
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isComplete ? Colors.orange.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.star : Icons.calendar_today, 
              color: isComplete ? Colors.orange : Colors.green, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45, 
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyChart(double start, double current, double target) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final system = _profile?.unitSystem ?? 'Metric';
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned(
            bottom: 40, left: 40, right: 40,
            child: Container(height: 1, color: Colors.white10),
          ),
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: JourneyPainter(
              start: UnitConverter.fromMetric(start, system, 'weight'), 
              current: UnitConverter.fromMetric(current, system, 'weight'), 
              target: UnitConverter.fromMetric(target, system, 'weight'), 
              isDark: isDark
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStat(String label, double val, String unit, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: val.toStringAsFixed(1), 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black87
                )
              ),
              const TextSpan(text: ' '),
              TextSpan(text: unit, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBmiCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bmi = _calculateBmi();
    final status = _getBmiStatus(bmi);
    final color = _getBmiColor(bmi);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_right, color: isDark ? Colors.white38 : Colors.black38, size: 16),
              Text(
                ' YOUR BMI', 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white38 : Colors.black38, 
                  letterSpacing: 1.2
                )
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showBmiInfo,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
                  ),
                  child: Icon(Icons.question_mark, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1), 
                style: TextStyle(
                  fontSize: 56, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45, 
                      fontSize: 16,
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      const TextSpan(text: 'Your weight is '),
                      TextSpan(
                        text: status, 
                        style: TextStyle(color: color, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildBmiGauge(bmi),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BmiLabel(label: 'Underweight', color: Colors.blueAccent, isDark: isDark),
              _BmiLabel(label: 'Healthy', color: Colors.greenAccent, isDark: isDark),
              _BmiLabel(label: 'Overweight', color: Colors.orangeAccent, isDark: isDark),
              _BmiLabel(label: 'Obese', color: Colors.redAccent, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiGauge(double bmi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Map BMI to 0.0 - 1.0 based on WHO Asian-Pacific categories
        // Thresholds: 18.5 (Underweight), 23.0 (Healthy), 25.0 (Overweight)
        double normalized;
        if (bmi < 18.5) {
          // Map [15, 18.5] to [0.0, 0.25]
          normalized = ((bmi - 15) / (18.5 - 15)) * 0.25;
        } else if (bmi < 23.0) {
          // Map [18.5, 23.0] to [0.25, 0.5]
          normalized = 0.25 + ((bmi - 18.5) / (23.0 - 18.5)) * 0.25;
        } else if (bmi < 25.0) {
          // Map [23.0, 25.0] to [0.5, 0.75]
          normalized = 0.5 + ((bmi - 23.0) / (25.0 - 23.0)) * 0.25;
        } else {
          // Map [25.0, 35.0] to [0.75, 1.0]
          normalized = 0.75 + ((bmi - 25.0) / (35.0 - 25.0)) * 0.25;
        }
        normalized = normalized.clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.redAccent],
                  stops: [0.0, 0.35, 0.65, 1.0], // Slightly adjusted for visual balance
                ),
              ),
            ),
            Positioned(
              left: normalized * (width - 4),
              child: Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showBmiInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151518) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What is BMI?', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black
                )
              ),
              const SizedBox(height: 24),
              Text(
                'BMI (Body Mass Index) is a simple measurement that uses your height and weight to estimate whether your body weight falls within a general health range.\n\nBMI ranges (WHO Asian-Pacific):\n\nBelow 18.5 — Underweight\n18.5 to 22.9 — Healthy range\n23 to 24.9 — Overweight\n25 and above — Obesity\n\nThese cutoffs are lower than the Western standard because Asian bodies typically carry more body fat at the same BMI, and elevated risk of type 2 diabetes and cardiovascular disease shows up at lower BMI values.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BmiLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _BmiLabel({required this.label, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [CircleAvatar(radius: 4, backgroundColor: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45))]);
}

class JourneyPainter extends CustomPainter {
  final double start, current, target;
  final bool isDark;
  
  JourneyPainter({required this.start, required this.current, required this.target, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    
    final xStart = 50.0;
    final xCurrent = size.width * 0.65;
    final xGoal = size.width - 50;
    
    double normalizeY(double val) {
      final allWeights = [start, current, target];
      final maxW = allWeights.reduce((a, b) => a > b ? a : b);
      final minW = allWeights.reduce((a, b) => a < b ? a : b);
      final range = (maxW - minW).abs();
      if (range == 0) return size.height / 2;
      return 40 + (1 - (val - minW) / range) * (size.height - 80);
    }
    
    final yStart = normalizeY(start);
    final yCurrent = normalizeY(current);
    final yGoal = normalizeY(target);
    
    linePaint.color = Colors.greenAccent;
    canvas.drawLine(Offset(xStart, yStart), Offset(xCurrent, yCurrent), linePaint);
    
    linePaint.color = Colors.orangeAccent.withValues(alpha: 0.3);
    const dashWidth = 8.0, dashSpace = 6.0;
    final fullDistance = (Offset(xGoal, yGoal) - Offset(xCurrent, yCurrent)).distance;
    final direction = (Offset(xGoal, yGoal) - Offset(xCurrent, yCurrent)) / (fullDistance == 0 ? 1 : fullDistance);
    
    double distance = 0;
    while (distance < fullDistance) {
      final startPoint = Offset(xCurrent, yCurrent) + direction * distance;
      final nextDist = distance + dashWidth;
      final endPoint = Offset(xCurrent, yCurrent) + direction * (nextDist > fullDistance ? fullDistance : nextDist);
      canvas.drawLine(startPoint, endPoint, linePaint);
      distance += dashWidth + dashSpace;
    }

    void drawMarker(Offset pos, Color color, String label, {bool labelAbove = false, String? prefix}) {
      dotPaint.color = color.withValues(alpha: 0.2);
      canvas.drawCircle(pos, 12, dotPaint);
      dotPaint.color = color;
      canvas.drawCircle(pos, 6, dotPaint);
      dotPaint.color = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      canvas.drawCircle(pos, 2, dotPaint);
      
      final fullLabel = prefix != null ? '$prefix $label' : label;
      textPainter.text = TextSpan(
        text: fullLabel, 
        style: TextStyle(
          color: isDark ? color : (color == Colors.greenAccent ? Colors.green : Colors.black), 
          fontWeight: FontWeight.bold, 
          fontSize: 14,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, labelAbove ? pos.dy - 32 : pos.dy + 16));
    }

    drawMarker(Offset(xStart, yStart), Colors.greenAccent, start.toStringAsFixed(1));
    drawMarker(Offset(xCurrent, yCurrent), Colors.orangeAccent, current.toStringAsFixed(1), labelAbove: true);
    drawMarker(Offset(xGoal, yGoal), Colors.orangeAccent.withValues(alpha: 0.5), target.toStringAsFixed(1), prefix: 'GOAL');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
