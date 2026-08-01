import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../services/auth_service.dart';
import '../services/nutrition_feedback_service.dart';
import '../models/nutrition_feedback.dart';
import '../models/meal_log.dart';
import '../services/database_helper.dart';
import '../models/user_profile.dart';
import 'meal_log_screen.dart';
import 'add_meal_screen.dart';
import 'meal_plan_screen.dart';
import 'fasting_timer_screen.dart';
import 'widgets/dashboard_widgets.dart';
import '../models/fasting_session.dart';
import '../services/fasting_service.dart';
import '../services/app_events.dart';
import '../services/gamification_service.dart';
import '../services/health_sync_service.dart';
import 'shopping_list_screen.dart';
import 'widgets/app_toast.dart';
import 'widgets/water_tracker_widget.dart';
import 'widgets/recipe_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _feedbackService = NutritionFeedbackService();
  final _fastingService = FastingService();
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  
  NutritionFeedback? _latestFeedback;
  FastingSession? _activeFast;
  UserProfile? _profile;
  List<MealLog> _todayLogs = [];
  Map<String, double> _dailyProgress = {};
  int _streakCount = 0;
  double _steps = 0;
  double _burnedFromSync = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    AppEvents.instance.mealChanged.addListener(_loadData);
    AppEvents.instance.profileChanged.addListener(_loadData);
    AppEvents.instance.fastingChanged.addListener(_loadData);
    AppEvents.instance.weightChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    AppEvents.instance.mealChanged.removeListener(_loadData);
    AppEvents.instance.profileChanged.removeListener(_loadData);
    AppEvents.instance.fastingChanged.removeListener(_loadData);
    AppEvents.instance.weightChanged.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final dateStr = _formatDate(_selectedDate);
    
    try {
      final feedback = await _feedbackService.loadDailyFeedback(userId, dateStr);
      final logs = await _db.getMealLogsForDate(userId, dateStr);
      final activeFast = await _fastingService.getActiveSession();
      final profile = await _db.getUserProfile(userId);
      final streak = await GamificationService.instance.getCurrentStreak();
      
      // Activity Sync (Sync if it's today)
      if (dateStr == _formatDate(DateTime.now())) {
        final activity = await HealthSyncService.instance.fetchTodayActivity();
        _steps = activity['steps'] ?? 0;
        _burnedFromSync = activity['burned'] ?? 0;
      }
      
      // Fetch 14-day history for the calendar strip
      final now = DateTime.now();
      final stripStart = now.subtract(const Duration(days: 3));
      final stripEnd = stripStart.add(const Duration(days: 13));
     
      final history = await _db.getCalorieHistoryForRange(
        userId, 
        _formatDate(stripStart), 
        _formatDate(stripEnd)
      );

      // Calculate progress percentage for each day in history
      final Map<String, double> progressMap = {};
      final double targetKcal = feedback.target.energyKcal > 0 ? feedback.target.energyKcal : 2000.0;
      
      history.forEach((date, consumed) {
        progressMap[date] = consumed / targetKcal;
      });
      
      if (mounted) {
        setState(() {
          _latestFeedback = feedback;
          _todayLogs = logs;
          _activeFast = activeFast;
          _profile = profile;
          _dailyProgress = progressMap;
          _streakCount = streak;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            CalendarStrip(
              selectedDate: _selectedDate,
              dailyCalorieProgress: _dailyProgress,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _isLoading = true;
                });
                _loadData();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      if (_isLoading)
                        Column(
                          children: List.generate(4, (index) => const MealItemShimmer()),
                        )
                      else if (_latestFeedback != null) ...[
                        if (_activeFast != null) _buildActiveFastingWidget(),
                        _buildMainCalorieCard(_latestFeedback!),
                        const SizedBox(height: 12),
                        if (_steps > 0 || _burnedFromSync > 0) _buildActivityCard(isDark),
                        const SizedBox(height: 12),
                        WaterTrackerWidget(
                          userId: _auth.currentUser?.uid ?? '',
                          date: _formatDate(_selectedDate),
                        ),
                        const SizedBox(height: 12),
                        _buildMacroRow(_latestFeedback!),
                        const SizedBox(height: 24),
                        _buildMealsSection(),
                      ] else
                        const Center(child: Text('Setup your profile to see data.')),
                      const SizedBox(height: 16), // Reduced spacing
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    AppToast.show(
      context,
      message: 'The $feature feature is coming soon!',
      title: 'Coming Soon',
      type: ToastType.info,
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Priority logic for small screens (e.g. S24 Base, iPhone SE)
        final bool isExtraSmall = constraints.maxWidth < 420;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, ${_profile?.name?.split(' ').first ?? 'User'}',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getMonthName(_selectedDate.month),
                      style: TextStyle(
                        fontSize: isExtraSmall ? 22 : 26, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCircleAction(Icons.history, () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const MealLogScreen()));
                  }),
                  const SizedBox(width: 8),
                  _buildCircleAction(Icons.timer_outlined, () async {
                     await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const FastingTimerScreen()));
                     _loadData();
                  }),
                  if (!isExtraSmall) ...[
                    const SizedBox(width: 8),
                    _buildCircleAction(Icons.auto_awesome_rounded, () {
                       Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
                    }),
                    const SizedBox(width: 8),
                    _buildCircleAction(Icons.shopping_cart_outlined, () {
                       Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
                    }),
                  ],
                  if (isExtraSmall) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<int>(
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      elevation: 8,
                      onSelected: (val) {
                        if (val == 0) Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
                        if (val == 1) Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_horiz, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0, 
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent, size: 20),
                              const SizedBox(width: 12),
                              Text('Meal Planner', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ],
                          )
                        ),
                        PopupMenuItem(
                          value: 1, 
                          child: Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 12),
                              Text('Shopping List', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ],
                          )
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildTodayButton(),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTodayButton() {
    return InkWell(
      onTap: () {
        setState(() => _selectedDate = DateTime.now());
        _loadData();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Today', 
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)
        ),
      ),
    );
  }

  Widget _buildActivityCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Row(
        children: [
          _buildActivityItem(
            icon: Icons.directions_walk,
            value: '${_steps.round()}',
            label: 'Steps Today',
            color: Colors.blueAccent,
            isDark: isDark,
          ),
          const Spacer(),
          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          const Spacer(),
          _buildActivityItem(
            icon: Icons.local_fire_department,
            value: '${_burnedFromSync.round()}',
            label: 'Cal Burned',
            color: Colors.redAccent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({required IconData icon, required String value, required String label, required Color color, required bool isDark}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }

  Widget _buildActiveFastingWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = _activeFast!;
    final stage = session.currentStage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text('Active Fast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(session.timeRemaining, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: session.progress,
            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stage ${stage.index}: ${stage.name}', 
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)
              ),
              Text(
                '${(session.progress * 100).round()}%', 
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCalorieCard(NutritionFeedback feedback) {
    final goal = feedback.target.energyKcal.round();
    final consumed = feedback.intake.calories.round();
    int diff = goal - consumed;

    // Respect showSurplus customization
    final bool showSurplus = _profile?.showSurplus ?? true;
    
    String label = 'Calories left';
    int displayValue = diff;

    if (diff < 0) {
      if (showSurplus) {
        label = 'Calories over';
        displayValue = diff.abs();
      } else {
        displayValue = 0;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 350;
        
        return Container(
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
            ] : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (diff < 0 && showSurplus) ? '+$displayValue' : '$displayValue',
                            style: TextStyle(
                              fontSize: isSmall ? 42 : 54, 
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: diff < 0 && showSurplus ? Colors.redAccent : Colors.orangeAccent, 
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: isDark ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Goal: $goal · Consumed: $consumed',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26, 
                            fontSize: isSmall ? 9 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NutrientCircle(
                    progress: consumed / goal,
                    icon: Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: isSmall ? 75 : 90,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.show_chart, color: isDark ? Colors.white38 : Colors.black38, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'See burned calories', 
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45, 
                      fontWeight: FontWeight.w500,
                      fontSize: isSmall ? 11 : 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black26, size: 16),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMacroRow(NutritionFeedback feedback) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxWidth < 350 ? 140 : 160;
        
        final bool showSurplus = _profile?.showSurplus ?? true;

        // Protein
        final double pDiff = feedback.target.proteinGrams.mid - feedback.intake.protein;
        final bool pOver = pDiff < 0;
        final String pLabel = pOver && showSurplus ? 'Protein over' : 'Protein left';
        final String pValue = pOver ? (showSurplus ? '+${pDiff.abs().round()}g' : '0g') : '${pDiff.round()}g';

        // Carbs
        final double cDiff = feedback.target.carbsGrams.mid - feedback.intake.carbs;
        final bool cOver = cDiff < 0;
        final String cLabel = cOver && showSurplus ? 'Carbs over' : 'Carbs left';
        final String cValue = cOver ? (showSurplus ? '+${cDiff.abs().round()}g' : '0g') : '${cDiff.round()}g';

        // Fats
        final double fDiff = feedback.target.fatGrams.mid - feedback.intake.fat;
        final bool fOver = fDiff < 0;
        final String fLabel = fOver && showSurplus ? 'Fats over' : 'Fats left';
        final String fValue = fOver ? (showSurplus ? '+${fDiff.abs().round()}g' : '0g') : '${fDiff.round()}g';

        return SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(
                child: MacroCardSmall(
                  label: pLabel,
                  value: pValue,
                  progress: feedback.protein.progress,
                  icon: Icons.restaurant,
                  color: Colors.redAccent,
                  isOver: pOver && showSurplus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroCardSmall(
                  label: cLabel,
                  value: cValue,
                  progress: feedback.carbs.progress,
                  icon: Icons.bakery_dining,
                  color: Colors.blueAccent,
                  isOver: cOver && showSurplus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroCardSmall(
                  label: fLabel,
                  value: fValue,
                  progress: feedback.fat.progress,
                  icon: Icons.water_drop,
                  color: Colors.greenAccent,
                  isOver: fOver && showSurplus,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMealsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meals', 
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              )
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MealLogScreen())),
              icon: Text('See more', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
              label: Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black26, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todayLogs.isEmpty)
          _buildEmptyState(isDark, cardColor)
        else
          ..._todayLogs.map((log) => _buildMealItem(log)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded, 
              size: 40, 
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your personalized plan is ready.\nStart tracking to see your progress!',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(MealLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(log.id),
        endActionPane: ActionPane(
          extentRatio: 0.8,
          motion: const ScrollMotion(),
          children: [
            _buildSlidableAction(
              label: 'Delete',
              icon: Icons.delete_outline,
              color: const Color(0xFFC54D4D),
              onTap: () async {
                await _db.deleteMealLog(log.id!);
                AppEvents.instance.notifyMealChanged();
                if (context.mounted) {
                  AppToast.show(
                    context,
                    message: '${log.foodName} has been removed.',
                    title: 'Meal Deleted',
                    type: ToastType.info,
                  );
                }
              },
            ),
            _buildSlidableAction(
              label: 'Clarify',
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFD4A044),
              onTap: () => _showComingSoon('Clarify'),
            ),
            _buildSlidableAction(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: const Color(0xFF4A72C2),
              onTap: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => AddMealScreen(recipe: null, existingLog: log)),
                );
                // No need for _loadData() here anymore as AddMealScreen notifies
              },
            ),
            _buildSlidableAction(
              label: 'Share',
              icon: Icons.share_outlined,
              color: const Color(0xFF52A574),
              onTap: () => _showComingSoon('Share'),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
            ] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (log.imageUrl != null)
                    Image.network(
                      log.imageUrl!,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildMealImagePlaceholder(),
                    )
                  else
                    _buildMealImagePlaceholder(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getMealTypeColor(log.mealType).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getMealTypeColor(log.mealType).withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  log.mealType.toUpperCase(),
                                  style: TextStyle(
                                    color: _getMealTypeColor(log.mealType),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (log.mealTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), 
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text(log.mealTime!, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              log.foodName,
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                              const SizedBox(width: 4),
                              Text('${log.calories?.round() ?? 0} cal', 
                                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w500, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildMealMacroRow(log),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealImagePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      child: Icon(Icons.restaurant, color: isDark ? Colors.white12 : Colors.black12, size: 32),
    );
  }

  Widget _buildMealMacroRow(MealLog log) {
    String format(double? val) => val != null ? '${val.round()}g' : '0g';
    return Row(
      children: [
        _buildMealMacroItem(Icons.restaurant, format(log.protein), Colors.redAccent),
        const SizedBox(width: 12),
        _buildMealMacroItem(Icons.bakery_dining, format(log.carbs), Colors.blueAccent),
        const SizedBox(width: 12),
        _buildMealMacroItem(Icons.water_drop, format(log.fat), Colors.greenAccent),
      ],
    );
  }

  Widget _buildMealMacroItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildSlidableAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: color),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Colors.orangeAccent;
      case 'lunch': return Colors.greenAccent;
      case 'dinner': return Colors.blueAccent;
      default: return Colors.purpleAccent;
    }
  }
}
