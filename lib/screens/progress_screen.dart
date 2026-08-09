import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_nutrition.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../models/fasting_session.dart';
import '../models/vitality_log.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/fasting_service.dart';
import '../services/app_events.dart';
import '../services/unit_converter.dart';
import '../services/sound_service.dart';
import '../services/gamification_service.dart';
import 'widgets/app_loading.dart';
import 'log_vitality_screen.dart';

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
  List<VitalityLog> _vitalityHistory = [];
  Map<String, dynamic> _streakInfo = {'current': 0, 'best': 0};
  int _xp = 0;
  int _level = 1;
  List<String> _achievements = [];
  int _currentCarouselPage = 0;
  final PageController _carouselController = PageController();
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
    _carouselController.dispose();
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
    final vitality = await _db.getVitalityHistory(userId, days);
    final gamification = await GamificationService.instance.getGamificationStats();

    if (mounted) {
      setState(() {
        _profile = profile;
        _nutritionHistory = nutrition;
        _waterHistory = water;
        _fastingHistory = fasting;
        _vitalityHistory = vitality;
        _streakInfo = {
          'current': gamification['current_streak'] ?? 0,
          'best': gamification['best_streak'] ?? 0,
        };
        _xp = gamification['xp'] ?? 0;
        _level = gamification['level'] ?? 1;
        _achievements = List<String>.from(gamification['achievements'] ?? []);
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
                    fontSize: 28, 
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
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
                        fontSize: 40, 
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
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildLevelCard(),
              const SizedBox(height: 12),
              _buildStreakCard(),
              const SizedBox(height: 24),
              _buildAchievementsSection(),
              const SizedBox(height: 32),
              _buildMacroAveragesCard(),
              const SizedBox(height: 20),
              _buildJourneyCard(),
              const SizedBox(height: 20),
              _buildVitalityTrendsCard(),
              const SizedBox(height: 20),
              _buildBmiCard(),
              const SizedBox(height: 100),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
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
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'See your trend over time', 
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.teal.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: !isDark ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
              ),
              child: const Icon(Icons.trending_up, color: Colors.teal, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = _streakInfo['current'] as int? ?? 0;
    final bestStreak = _streakInfo['best'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange.withValues(alpha: isDark ? 0.1 : 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Streak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Keep logging to grow!',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white12 : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStreakStat(
                  'CURRENT', 
                  currentStreak.toString(), 
                  'days', 
                  Colors.orange, 
                  isDark
                ),
              ),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              Expanded(
                child: _buildStreakStat(
                  'BEST', 
                  bestStreak.toString(), 
                  'days', 
                  isDark ? Colors.white70 : Colors.black54, 
                  isDark
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const xpPerLevel = GamificationService.xpPerLevel;
    final levelProgress = (_xp % xpPerLevel) / xpPerLevel;
    final xpToNext = xpPerLevel - (_xp % xpPerLevel);
    
    String levelTitle = 'Health Explorer';
    if (_level >= 5) levelTitle = 'Nutrient Ninja';
    if (_level >= 10) levelTitle = 'Wellness Warrior';
    if (_level >= 20) levelTitle = 'Lifestyle Legend';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E3A3A), const Color(0xFF121212)] 
            : [const Color(0xFFE0F2F1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Lvl $_level',
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '$_xp Total XP earned',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(Colors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_xp % xpPerLevel)} / $xpPerLevel XP',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '$xpToNext XP to Lvl ${_level + 1}',
                style: TextStyle(color: Colors.teal.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final allAchievements = [
      {'id': 'first_meal', 'name': 'First Bite', 'icon': Icons.restaurant, 'desc': 'Logged your first meal'},
      {'id': 'hydro_master', 'name': 'Hydro Master', 'icon': Icons.water_drop, 'desc': 'Reached daily water goal'},
      {'id': 'streak_7', 'name': 'Committed', 'icon': Icons.local_fire_department, 'desc': 'Reached a 7-day streak'},
      {'id': 'iron_will', 'name': 'Iron Will', 'icon': Icons.timer, 'desc': 'Completed a fasting session'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Achievements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: allAchievements.length,
          itemBuilder: (context, index) {
            final ach = allAchievements[index];
            final bool isUnlocked = _achievements.contains(ach['id']);
            
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ach['icon'] as IconData, size: 64, color: isUnlocked ? Colors.orangeAccent : Colors.grey),
                        const SizedBox(height: 24),
                        Text(ach['name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(ach['desc'] as String, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 32),
                        if (isUnlocked)
                          const Text('UNLOCKED!', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 2))
                        else
                          const Text('LOCKED', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isUnlocked 
                      ? Colors.orangeAccent.withValues(alpha: 0.3) 
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  ),
                  boxShadow: !isDark && isUnlocked ? [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ach['icon'] as IconData, 
                      color: isUnlocked ? Colors.orangeAccent : (isDark ? Colors.white10 : Colors.black12),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ach['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
        Text(
          value, 
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)
        ),
        Text(
          unit, 
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26)
        ),
      ],
    );
  }

  Widget _buildMacroAveragesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate averages for current period
    double avgCal = 0, avgProt = 0, avgCarb = 0, avgFat = 0;
    double avgFiber = 0, avgSugar = 0, avgSodium = 0, avgChol = 0;

    int days = _nutritionHistory.length;
    if (days > 0) {
      avgCal = _nutritionHistory.fold(0.0, (sum, n) => sum + n.calories) / days;
      avgProt = _nutritionHistory.fold(0.0, (sum, n) => sum + n.protein) / days;
      avgCarb = _nutritionHistory.fold(0.0, (sum, n) => sum + n.carbs) / days;
      avgFat = _nutritionHistory.fold(0.0, (sum, n) => sum + n.fat) / days;
      avgFiber = _nutritionHistory.fold(0.0, (sum, n) => sum + n.fiber) / days;
      avgSugar = _nutritionHistory.fold(0.0, (sum, n) => sum + n.sugar) / days;
      avgSodium = _nutritionHistory.fold(0.0, (sum, n) => sum + n.sodium) / days;
      avgChol = _nutritionHistory.fold(0.0, (sum, n) => sum + n.cholesterol) / days;
    }

    final hasHypertension = _profile?.healthConditions.contains('Hypertension') ?? false;
    final hasDiabetes = _profile?.healthConditions.contains('Diabetes') ?? false;
    final hasHeartHealth = _profile?.healthConditions.contains('Heart Health') ?? false;
    final hasDigestive = _profile?.healthConditions.contains('Digestive Health') ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Nutrition average', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              )
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTimeFilterRow(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130, // Increased for sparklines
            child: PageView(
              controller: _carouselController,
              onPageChanged: (idx) => setState(() => _currentCarouselPage = idx),
              children: [
                // PAGE 1: MACROS
                _buildCarouselPage([
                  _buildMacroAvgItem('CALORIES', avgCal.round().toString(), Colors.orangeAccent, trendData: _nutritionHistory.map((n) => n.calories).toList()),
                  _buildMacroAvgItem('PROTEIN', '${avgProt.round()}g', Colors.redAccent, trendData: _nutritionHistory.map((n) => n.protein).toList()),
                  _buildMacroAvgItem('CARBS', '${avgCarb.round()}g', Colors.blueAccent, trendData: _nutritionHistory.map((n) => n.carbs).toList()),
                  _buildMacroAvgItem('FATS', '${avgFat.round()}g', Colors.greenAccent, trendData: _nutritionHistory.map((n) => n.fat).toList()),
                ]),
                // PAGE 2: CLINICAL (CALORIES + MICROS)
                _buildCarouselPage([
                  _buildMacroAvgItem('CALORIES', avgCal.round().toString(), Colors.orangeAccent),
                  _buildMacroAvgItem('FIBER', '${avgFiber.round()}g', const Color(0xFF52A574), isPriority: hasDigestive),
                  _buildMacroAvgItem('SUGAR', '${avgSugar.round()}g', Colors.orangeAccent, isPriority: hasDiabetes),
                  _buildMacroAvgItem('SODIUM', '${avgSodium.round()}mg', const Color(0xFFC26DB7), isPriority: hasHypertension),
                ]),
                // PAGE 3: HEART HEALTH
                _buildCarouselPage([
                  _buildMacroAvgItem('CALORIES', avgCal.round().toString(), Colors.orangeAccent),
                  _buildMacroAvgItem('CHOL', '${avgChol.round()}mg', Colors.redAccent, isPriority: hasHeartHealth),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCarouselIndicators(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          const SizedBox(height: 20),
          _buildExtraAverages(isDark),
        ],
      ),
    );
  }

  Widget _buildCarouselPage(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(Expanded(child: items[i]));
      if (i < items.length - 1) {
        children.add(Container(width: 1, height: 32, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: children),
    );
  }

  Widget _buildCarouselIndicators() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (idx) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 4,
        width: _currentCarouselPage == idx ? 16 : 4,
        decoration: BoxDecoration(
          color: _currentCarouselPage == idx 
              ? (isDark ? Colors.white : Colors.black) 
              : (isDark ? Colors.white24 : Colors.black12),
          borderRadius: BorderRadius.circular(2),
        ),
      )),
    );
  }

  Widget _buildExtraAverages(bool isDark) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    
    // Map water history for easy lookup
    final Map<String, int> waterMap = {
      for (var w in _waterHistory) w['date'] as String: (w['amount_ml'] as num).toInt()
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSecondaryAvgItem('FASTING', '${_calculateAvgFasting()}h', 'avg', Colors.redAccent),
            _buildVerticalDivider(isDark),
            _buildSecondaryAvgItem('STEPS', '0', 'avg', Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          '7-DAY HYDRATION CONSISTENCY', 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45, letterSpacing: 1.1)
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (idx) {
            final date = sevenDaysAgo.add(Duration(days: idx));
            final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final ml = waterMap[dateStr] ?? 0;
            final bool isTargetMet = ml >= 2000; // Assuming 2L goal

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop, 
                    color: isTargetMet ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(date)[0], 
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black26)
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  double _calculateAvgFasting() {
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
    return totalFastingHours / fastingDays;
  }

  Widget _buildTimeFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['This week', 'Last week', '1 month', '6 months'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 6),
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
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide.none,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMacroAvgItem(String label, String value, Color color, {List<double>? trendData, bool isPriority = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPriority)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 8, color: color),
                const SizedBox(width: 2),
                Text('PRIORITY', style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w900, 
              color: color,
            )
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          )
        ),
        if (trendData != null && trendData.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            width: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: color.withValues(alpha: 0.5),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          Text(
            'avg / day', 
            style: TextStyle(
              fontSize: 9, 
              color: isDark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.bold,
            )
          ),
      ],
    );
  }

  Widget _buildSecondaryAvgItem(String label, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const TextSpan(text: ' '),
              TextSpan(text: unit, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(width: 1, height: 32, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
  }

  Widget _buildVitalityTrendsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate averages
    double avgSys = 0, avgDia = 0, avgGlu = 0;
    final bpLogs = _vitalityHistory.where((v) => v.hasBp).toList();
    final gluLogs = _vitalityHistory.where((v) => v.hasGlucose).toList();

    if (bpLogs.isNotEmpty) {
      avgSys = bpLogs.fold(0.0, (sum, v) => sum + (v.systolic ?? 0)) / bpLogs.length;
      avgDia = bpLogs.fold(0.0, (sum, v) => sum + (v.diastolic ?? 0)) / bpLogs.length;
    }
    if (gluLogs.isNotEmpty) {
      avgGlu = gluLogs.fold(0.0, (sum, v) => sum + (v.glucose ?? 0)) / gluLogs.length;
    }

    final hasBp = bpLogs.isNotEmpty;
    final hasGlu = gluLogs.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vitality Trends', 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const LogVitalityScreen())
                  );
                  _loadData();
                },
                icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildVitalityItem(
                  'BLOOD PRESSURE', 
                  hasBp ? '${avgSys.round()}/${avgDia.round()}' : '--', 
                  'mmHg', 
                  Colors.redAccent, 
                  trendData: bpLogs.reversed.map((v) => (v.systolic ?? 0).toDouble()).toList(),
                  isDark: isDark
                ),
              ),
              _buildVerticalDivider(isDark),
              Expanded(
                child: _buildVitalityItem(
                  'BLOOD GLUCOSE', 
                  hasGlu ? avgGlu.toStringAsFixed(1) : '--', 
                  'mg/dL', 
                  Colors.orangeAccent, 
                  trendData: gluLogs.reversed.map((v) => (v.glucose ?? 0).toDouble()).toList(),
                  isDark: isDark
                ),
              ),
            ],
          ),
          if (!hasBp && !hasGlu)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'Log your readings to see trends.', 
                  style: TextStyle(color: isDark ? Colors.white10 : Colors.black12, fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalityItem(String label, String value, String unit, Color color, {List<double>? trendData, required bool isDark}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black26)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(unit, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
        if (trendData != null && trendData.length >= 2) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            width: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Journey', 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              const SizedBox(height: 16),
              _buildJourneyChart(starting, current, target),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildJourneyStat('START', UnitConverter.fromMetric(starting, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('NOW', UnitConverter.fromMetric(current, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('GOAL', UnitConverter.fromMetric(target, system, 'weight'), weightUnit, isDark),
                  _buildJourneyStat('LEFT', UnitConverter.fromMetric(remaining, system, 'weight'), weightUnit, isDark),
                ],
              ),
              const SizedBox(height: 20),
              _buildTimelineTile(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _updateWeight,
                  child: Text(
                    'LOG WEIGHT', 
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2, 
                      color: isDark ? Colors.white70 : Colors.black54
                    )
                  ),
                ),
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
    
    String message = 'Reaching goal by';
    String dateDisplay = '---';
    bool isComplete = false;

    if (target <= 0 || paceStr.isEmpty) {
      message = 'Set goal weight';
      dateDisplay = 'to see timeline';
    } else {
      final diff = (current - target).abs();
      if (diff < 0.1) {
        message = 'Amazing work!';
        dateDisplay = 'Goal reached';
        isComplete = true;
      } else {
        final match = RegExp(r'[\d.]+').firstMatch(paceStr);
        final weeklyPace = match != null ? double.tryParse(match.group(0)!) ?? 0.0 : 0.0;
        
        if (weeklyPace <= 0) {
          message = 'Maintaining';
          dateDisplay = 'current weight';
        } else {
          final weeks = diff / weeklyPace;
          final targetDate = DateTime.now().add(Duration(days: (weeks * 7).round()));
          dateDisplay = DateFormat('MMM d, yyyy').format(targetDate);
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isComplete ? Colors.orange.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.star : Icons.calendar_today, 
              color: isComplete ? Colors.orange : Colors.green, 
              size: 16
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11),
                ),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
      height: 120,
      child: Stack(
        children: [
          Positioned(
            bottom: 30, left: 30, right: 30,
            child: Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          CustomPaint(
            size: const Size(double.infinity, 120),
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
        Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: val.toStringAsFixed(1), 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black87
                )
              ),
              TextSpan(text: ' $unit', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'YOUR BMI', 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white38 : Colors.black38, 
                  letterSpacing: 1.1
                )
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showBmiInfo,
                child: Icon(Icons.info_outline, size: 16, color: isDark ? Colors.white24 : Colors.black26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1), 
                style: TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black
                )
              ),
              const SizedBox(width: 10),
              Text(
                status, 
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBmiGauge(bmi),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BmiLabel(label: 'Under', color: Colors.blueAccent, isDark: isDark),
              _BmiLabel(label: 'Healthy', color: Colors.greenAccent, isDark: isDark),
              _BmiLabel(label: 'Over', color: Colors.orangeAccent, isDark: isDark),
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

        double normalized;
        if (bmi < 18.5) {
          normalized = ((bmi - 15) / (18.5 - 15)) * 0.25;
        } else if (bmi < 23.0) {
          normalized = 0.25 + ((bmi - 18.5) / (23.0 - 18.5)) * 0.25;
        } else if (bmi < 25.0) {
          normalized = 0.5 + ((bmi - 23.0) / (25.0 - 23.0)) * 0.25;
        } else {
          normalized = 0.75 + ((bmi - 25.0) / (35.0 - 25.0)) * 0.25;
        }
        normalized = normalized.clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.redAccent],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
            Positioned(
              left: normalized * (width - 4),
              child: Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(1.5),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What is BMI?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              Text(
                'BMI (Body Mass Index) estimates if your weight is in a healthy range.\n\nWHO Asian-Pacific ranges:\nBelow 18.5: Underweight\n18.5-22.9: Healthy\n23.0-24.9: Overweight\n25+: Obese',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  Widget build(BuildContext context) => Row(children: [CircleAvatar(radius: 3, backgroundColor: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black45))]);
}

class JourneyPainter extends CustomPainter {
  final double start, current, target;
  final bool isDark;
  
  JourneyPainter({required this.start, required this.current, required this.target, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    
    final xStart = 40.0;
    final xCurrent = size.width * 0.6;
    final xGoal = size.width - 40;
    
    double normalizeY(double val) {
      final allWeights = [start, current, target];
      final maxW = allWeights.reduce((a, b) => a > b ? a : b);
      final minW = allWeights.reduce((a, b) => a < b ? a : b);
      final range = (maxW - minW).abs();
      if (range == 0) return size.height / 2;
      return 30 + (1 - (val - minW) / range) * (size.height - 60);
    }
    
    final yStart = normalizeY(start);
    final yCurrent = normalizeY(current);
    final yGoal = normalizeY(target);
    
    linePaint.color = Colors.greenAccent;
    canvas.drawLine(Offset(xStart, yStart), Offset(xCurrent, yCurrent), linePaint);
    
    linePaint.color = Colors.orangeAccent.withValues(alpha: 0.3);
    const dashWidth = 6.0, dashSpace = 4.0;
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
      canvas.drawCircle(pos, 8, dotPaint);
      dotPaint.color = color;
      canvas.drawCircle(pos, 4, dotPaint);
      
      final fullLabel = prefix != null ? '$prefix $label' : label;
      textPainter.text = TextSpan(
        text: fullLabel, 
        style: TextStyle(
          color: isDark ? color : (color == Colors.greenAccent ? Colors.green : Colors.black), 
          fontWeight: FontWeight.bold, 
          fontSize: 12,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, labelAbove ? pos.dy - 24 : pos.dy + 12));
    }

    drawMarker(Offset(xStart, yStart), Colors.greenAccent, start.toStringAsFixed(1));
    drawMarker(Offset(xCurrent, yCurrent), Colors.orangeAccent, current.toStringAsFixed(1), labelAbove: true);
    drawMarker(Offset(xGoal, yGoal), Colors.orangeAccent.withValues(alpha: 0.5), target.toStringAsFixed(1), prefix: 'GOAL');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
