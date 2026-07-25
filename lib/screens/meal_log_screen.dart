import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_log.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/app_events.dart';
import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  final _searchController = TextEditingController();
  
  List<MealLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _auth.currentUser?.uid ?? '';
    final logs = await _db.getRecentMeals(userId, query: _searchController.text);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _relogMeal(MealLog log) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat.jm().format(now);

    final newLog = MealLog(
      userId: userId,
      mealDate: todayStr,
      mealTime: timeStr,
      mealType: log.mealType,
      foodName: log.foodName,
      calories: log.calories,
      protein: log.protein,
      carbs: log.carbs,
      fat: log.fat,
      imageUrl: log.imageUrl,
      apiMealId: log.apiMealId,
      ingredients: log.ingredients,
      baseCalories: log.baseCalories,
      baseProtein: log.baseProtein,
      baseCarbs: log.baseCarbs,
      baseFat: log.baseFat,
    );

    await _db.insertMealLog(newLog);
    AppEvents.instance.notifyMealChanged();

    if (mounted) {
      AppToast.show(
        context,
        message: '${log.foodName} relogged for today!',
        title: 'Meal Relogged',
        type: ToastType.success,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const AppLoading()
                  : _logs.isEmpty
                      ? Center(child: Text('No meals found.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) => _buildMealCard(_logs[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Meals',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
            style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ] : null,
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          onChanged: (_) => _load(),
          decoration: InputDecoration(
            hintText: 'Search by meal name or ingredient',
            hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black26),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(MealLog log) {
    final date = DateTime.tryParse(log.mealDate) ?? DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (log.imageUrl != null)
                Image.network(
                  log.imageUrl!,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
              else
                _buildImagePlaceholder(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.foodName,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), 
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(dateStr, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 4),
                          Text('${log.calories?.round() ?? 0} calories', 
                              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w500, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMacroRow(log),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            label: 'Relog', 
                            icon: Icons.add_task_rounded, 
                            onTap: () => _relogMeal(log), 
                            isPrimary: true, 
                            isDark: isDark
                          ),
                          const SizedBox(width: 8),
                          _buildPinButton(log),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDark,
  }) {
    return Material(
      color: isPrimary 
          ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isDark ? Colors.white70 : Colors.black87, 
                size: 16
              ),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 120,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      child: Icon(Icons.restaurant, color: isDark ? Colors.white12 : Colors.black12, size: 40),
    );
  }

  Widget _buildMacroRow(MealLog log) {
    String format(double? val) => val != null ? '${val.round()}g' : '0g';
    return Row(
      children: [
        _buildMacroItem(Icons.restaurant, format(log.protein), Colors.redAccent),
        const SizedBox(width: 12),
        _buildMacroItem(Icons.bakery_dining, format(log.carbs), Colors.blueAccent),
        const SizedBox(width: 12),
        _buildMacroItem(Icons.water_drop, format(log.fat), Colors.greenAccent),
      ],
    );
  }

  Widget _buildMacroItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildPinButton(MealLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: log.isPinned 
          ? (isDark ? Colors.white : Colors.black) 
          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () async {
          await _db.toggleMealPin(log.id!, !log.isPinned);
          _load();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.push_pin_outlined, 
                color: log.isPinned 
                    ? (isDark ? Colors.black : Colors.white) 
                    : (isDark ? Colors.white : Colors.black), 
                size: 16
              ),
              const SizedBox(width: 6),
              Text(
                'Pin', 
                style: TextStyle(
                  color: log.isPinned 
                      ? (isDark ? Colors.black : Colors.white) 
                      : (isDark ? Colors.white : Colors.black), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
