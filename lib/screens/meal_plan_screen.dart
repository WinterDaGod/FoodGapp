import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/saved_meal.dart';
import '../models/weekly_plan.dart';
import '../services/api/api_exceptions.dart';
import '../services/meal_generation_service.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/nutrition_feedback_service.dart';
import '../services/shopping_list_service.dart';
import 'recipe_detail_screen.dart';
import 'widgets/app_loading.dart';
import 'add_meal_screen.dart';
import 'widgets/app_toast.dart';
import 'shopping_list_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _service = MealGenerationService.instance;
  final _caloriesController = TextEditingController();
  final _prefsController = TextEditingController();
  
  List<Recipe>? _currentDailyPlan;
  WeeklyMealPlan? _currentWeeklyPlan;
  Set<String> _savedRecipeIds = {};
  bool _isLoading = false;
  bool _isAddingToList = false;
  Set<String> _selectedDiets = {'Balanced'};
  String _timeframe = 'Day'; // 'Day' or 'Week'
  bool _isPreferencesExpanded = false;
  
  final Map<String, List<String>> _dietGroups = {
    '🌱 Diet': ['Balanced', 'Vegetarian', 'Vegan', 'Keto', 'Paleo'],
    '⚡ Fast': ['Quick Prep', 'Under 20m', '5 Ingredients'],
    '🎯 Goals': ['Low Carb', 'High Protein', 'Low Calorie'],
  };

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _loadSavedPlan();
  }

  Future<void> _loadSavedPlan() async {
    setState(() => _isLoading = true);
    final daily = await _service.loadLastDailyPlan();
    final weekly = await _service.loadLastWeeklyPlan();
    await _refreshSavedStatus();
    
    if (mounted) {
      setState(() {
        _currentDailyPlan = daily.isNotEmpty ? daily : null;
        _currentWeeklyPlan = weekly;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSavedStatus() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;
    final saved = await DatabaseHelper.instance.getSavedMeals(userId);
    if (mounted) {
      setState(() {
        _savedRecipeIds = saved.map((m) => m.apiMealId ?? '').toSet();
      });
    }
  }

  Future<void> _loadDefaults() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;
    
    final profile = await DatabaseHelper.instance.getUserProfile(userId);
    if (profile != null) {
      final targets = NutritionFeedbackService.buildTarget(profile);
      setState(() {
        _caloriesController.text = targets.energyKcal.round().toString();
      });
    }
  }

  Future<void> _generate() async {
    final kcal = int.tryParse(_caloriesController.text);
    if (kcal == null || kcal < 500) {
      AppToast.show(context, message: 'Please enter a valid calorie target (min 500)', type: ToastType.error);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentDailyPlan = null;
      _currentWeeklyPlan = null;
    });

    try {
      if (_timeframe == 'Day') {
        final userId = AuthService().currentUser?.uid;
        final profile = userId != null ? await DatabaseHelper.instance.getUserProfile(userId) : null;
        final targets = profile != null ? NutritionFeedbackService.buildTarget(profile) : null;

        final plan = await _service.generateSmartDailyPlan(
          targetKcal: kcal,
          targetProtein: targets?.proteinGrams.mid ?? (kcal * 0.25 / 4),
          targetCarbs: targets?.carbsGrams.mid ?? (kcal * 0.45 / 4),
          targetFat: targets?.fatGrams.mid ?? (kcal * 0.30 / 9),
          diets: _selectedDiets.toList(),
          preferences: _prefsController.text.trim().isNotEmpty ? _prefsController.text.trim() : null,
        );
        
        if (mounted) {
          setState(() {
            _currentDailyPlan = plan;
            _isLoading = false;
          });
        }
      } else {
        final plan = await _service.generateWeeklyPlan(
          targetCalories: kcal,
          diets: _selectedDiets.toList(),
          preferences: _prefsController.text.trim().isNotEmpty ? _prefsController.text.trim() : null,
        );
        if (mounted) {
          setState(() {
            _currentWeeklyPlan = plan;
            _isLoading = false;
          });
        }
      }

      if (mounted) {
        if ((_timeframe == 'Day' && (_currentDailyPlan?.isEmpty ?? true)) ||
            (_timeframe == 'Week' && _currentWeeklyPlan == null)) {
          AppToast.show(context, message: 'No plan found for these criteria. Try adjusting your calories.', type: ToastType.info);
        }
      }
    } on ApiQuotaExceededException {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, message: 'Daily limit reached. Try again tomorrow!', type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, message: 'Failed to generate plan. Please try again.', type: ToastType.error);
      }
    }
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;

    final alreadySaved = await DatabaseHelper.instance.isSaved(userId, recipe.apiMealId);

    if (alreadySaved) {
      await DatabaseHelper.instance.deleteSavedMeal(userId, recipe.apiMealId);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Removed from your recipes.',
          title: 'Removed',
          type: ToastType.info,
        );
      }
    } else {
      // For AI recipes or newly generated plans, ensure nutrition is cached locally
      // so it persists when viewed in the Saved tab.
      if (recipe.hasNutrition) {
        await DatabaseHelper.instance.cacheRecipe(recipe);
      }

      final savedMeal = SavedMeal(
        userId: userId,
        apiMealId: recipe.apiMealId,
        mealName: recipe.name,
        imageUrl: recipe.imageUrl,
      );

      await DatabaseHelper.instance.insertSavedMeal(savedMeal);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Added to your recipes.',
          title: 'Saved',
          type: ToastType.success,
        );
      }
    }
    _refreshSavedStatus();
  }

  void _logMeal(Recipe recipe) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AddMealScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputSection(isDark),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: AppLoading(),
                      )
                    else if (_timeframe == 'Day' && _currentDailyPlan != null && _currentDailyPlan!.isNotEmpty)
                      ..._buildPlanList(isDark)
                    else if (_timeframe == 'Week' && _currentWeeklyPlan != null)
                      ..._buildWeeklyPlanList(isDark)
                    else if (_currentDailyPlan == null && _currentWeeklyPlan == null)
                      _buildWelcomeState(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (_currentDailyPlan != null || _currentWeeklyPlan != null) 
          ? _buildShoppingListFAB(isDark) : null,
    );
  }

  Widget _buildShoppingListFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _isAddingToList ? null : () async {
        final List<Recipe> allRecipes = _timeframe == 'Day' 
          ? (_currentDailyPlan ?? []) 
          : (_currentWeeklyPlan?.days.values.expand((x) => x).toList() ?? []);
          
        if (allRecipes.isEmpty) return;

        setState(() => _isAddingToList = true);
        
        // Optimized bulk addition
        await ShoppingListService.instance.addIngredientsFromRecipesBulk(allRecipes);
        
        if (mounted) {
          setState(() => _isAddingToList = false);
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
          );
        }
      },
      backgroundColor: isDark ? Colors.white : Colors.black,
      foregroundColor: isDark ? Colors.black : Colors.white,
      icon: _isAddingToList 
        ? SizedBox(
            width: 18, height: 18, 
            child: CircularProgressIndicator(
              strokeWidth: 2, 
              color: isDark ? Colors.black : Colors.white
            )
          )
        : const Icon(Icons.shopping_cart_outlined),
      label: Text(
        _isAddingToList ? 'Adding...' : 'Add all to List', 
        style: const TextStyle(fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Meal Planner',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
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

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeframeToggle(isDark),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_timeframe == 'Day' ? 'Daily Calories' : 'Daily Average Calories', 
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
                    const SizedBox(height: 6),
                    _buildNumericField(_caloriesController, 'e.g. 2000'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _isPreferencesExpanded = !_isPreferencesExpanded),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isPreferencesExpanded 
                        ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPreferencesExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: _isPreferencesExpanded 
                        ? (isDark ? Colors.greenAccent : Colors.orangeAccent)
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Preferences', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
                    const Spacer(),
                    if (_selectedDiets.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selectedDiets.clear()),
                        child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                ..._dietGroups.entries.map((group) => _buildDietGroup(group.key, group.value, isDark)),
                const SizedBox(height: 20),
                Text('Special Requests (AI)', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
                const SizedBox(height: 10),
                _buildTextField(_prefsController, 'e.g. No seafood, high fiber, Italian mood...'),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: _isPreferencesExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(_isLoading ? 'Generating...' : 'Generate Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietGroup(String title, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((d) {
              final isSelected = _selectedDiets.contains(d);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (isSelected) {
                        _selectedDiets.remove(d);
                      } else {
                        _selectedDiets.add(d);
                      }
                    });
                  },
                  backgroundColor: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
                  selectedColor: Colors.orangeAccent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orangeAccent : (isDark ? Colors.white38 : Colors.black45),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(color: isSelected ? Colors.orangeAccent : Colors.transparent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Day', 'Week'].map((t) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _timeframe = t),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _timeframe == t ? (isDark ? const Color(0xFF333333) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _timeframe == t && !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
                ] : null,
              ),
              child: Center(
                child: Text(
                  t,
                  style: TextStyle(
                    color: _timeframe == t ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
                    fontWeight: _timeframe == t ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNumericField(TextEditingController controller, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
          border: InputBorder.none,
          suffixText: 'kcal',
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  List<Widget> _buildPlanList(bool isDark) {
    final labels = ['Breakfast', 'Lunch', 'Dinner'];
    
    return _currentDailyPlan!.asMap().entries.map((entry) {
      final index = entry.key;
      final recipe = entry.value;
      return _buildMealCard(labels[index % labels.length], recipe, isDark);
    }).toList();
  }

  List<Widget> _buildWeeklyPlanList(bool isDark) {
    return _currentWeeklyPlan!.dayNames.map((day) {
      final meals = _currentWeeklyPlan!.days[day] ?? [];
      if (meals.isEmpty) return const SizedBox();

      final totalDayKcal = meals.fold<double>(0, (sum, m) => sum + (m.calories ?? 0)).round();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today, color: Colors.orangeAccent, size: 20),
            ),
            title: Text(
              day.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              '$totalDayKcal kcal total',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    ...meals.asMap().entries.map((entry) {
                      final labels = ['Breakfast', 'Lunch', 'Dinner'];
                      final meal = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            if (meal.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(meal.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                              )
                            else
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), 
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: Icon(Icons.restaurant, color: isDark ? Colors.white12 : Colors.black12),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    labels[entry.key],
                                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    meal.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${meal.calories?.round()} kcal',
                                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: meal)),
                              ),
                              icon: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black12),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMealCard(String label, Recipe recipe, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(recipe.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(label, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Text('${recipe.calories?.round()} kcal', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(recipe.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  _buildMacroRow(recipe, isDark),
                  if (recipe.aiReasoning != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recipe.aiReasoning!,
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (recipe.ingredients != null)
                    Text(
                      recipe.ingredients!.take(3).join(', ') + (recipe.ingredients!.length > 3 ? '...' : ''),
                      style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: _savedRecipeIds.contains(recipe.apiMealId) ? Icons.bookmark : Icons.bookmark_outline,
                          label: _savedRecipeIds.contains(recipe.apiMealId) ? 'Saved' : 'Save',
                          onTap: () => _saveRecipe(recipe),
                          isPrimary: false,
                          isDark: isDark,
                          color: _savedRecipeIds.contains(recipe.apiMealId) ? Colors.orangeAccent : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Log Meal',
                          onTap: () => _logMeal(recipe),
                          isPrimary: true,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDark,
    Color? color,
  }) {
    final iconColor = color ?? (isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black54));
    final textColor = color ?? (isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87));

    return Material(
      color: isPrimary 
          ? (isDark ? const Color(0xFF333333) : Colors.black)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: iconColor, 
                size: 18
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow(Recipe r, bool isDark) {
    return Row(
      children: [
        _buildMacro('P', '${r.protein?.round()}g', Colors.redAccent, isDark),
        const SizedBox(width: 16),
        _buildMacro('C', '${r.carbs?.round()}g', Colors.blueAccent, isDark),
        const SizedBox(width: 16),
        _buildMacro('F', '${r.fat?.round()}g', Colors.greenAccent, isDark),
      ],
    );
  }

  Widget _buildMacro(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildWelcomeState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            const SizedBox(height: 24),
            Text(
              'Enter your targets above to\ngenerate a custom meal plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
