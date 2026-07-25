import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/saved_meal.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/recipe_repository.dart';
import '../services/shopping_list_service.dart';
import 'add_meal_screen.dart';
import 'widgets/app_toast.dart';
import 'widgets/app_logo.dart';

import 'widgets/app_loading.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  bool _isLoadingNutrition = false;
  bool _isSaved = false;
  final _repository = RecipeRepository();
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _checkSavedStatus();
    if (!_recipe.hasNutrition && _recipe.source == 'spoonacular') {
      _loadFullNutrition();
    }
  }

  Future<void> _checkSavedStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final saved = await _db.isSaved(userId, _recipe.apiMealId);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _loadFullNutrition() async {
    setState(() => _isLoadingNutrition = true);
    final fullRecipe = await _repository.getNutrition(_recipe.apiMealId);
    if (mounted && fullRecipe != null) {
      setState(() {
        _recipe = fullRecipe;
        _isLoadingNutrition = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingNutrition = false);
    }
  }

  Future<void> _saveRecipe() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (_isSaved) {
      await _db.deleteSavedMeal(userId, _recipe.apiMealId);
      if (mounted) {
        setState(() => _isSaved = false);
        AppToast.show(
          context,
          message: 'Removed from your recipes.',
          title: 'Removed',
          type: ToastType.info,
        );
      }
    } else {
      final savedMeal = SavedMeal(
        userId: userId,
        apiMealId: _recipe.apiMealId,
        mealName: _recipe.name,
        imageUrl: _recipe.imageUrl,
      );

      await _db.insertSavedMeal(savedMeal);
      if (mounted) {
        setState(() => _isSaved = true);
        AppToast.show(
          context,
          message: 'Saved to your recipes tab.',
          title: 'Recipe Saved',
          type: ToastType.success,
        );
      }
    }
  }

  Future<void> _addIngredientsToList() async {
    await ShoppingListService.instance.addIngredientsFromRecipe(_recipe);
    if (mounted) {
      AppToast.show(
        context,
        message: 'All ingredients added to your shopping list.',
        title: 'Added to List',
        type: ToastType.success,
      );
    }
  }

  void _logMeal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMealScreen(recipe: _recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecipeHeader(isDark),
                  const SizedBox(height: 32),
                  Text(
                    'Nutrition Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingNutrition)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: AppLoading(),
                    )
                  else if (_recipe.hasNutrition) ...[
                    _buildNutritionGrid(isDark),
                    if (_recipe.ingredients != null && _recipe.ingredients!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildIngredientsList(isDark),
                    ],
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Nutrition data not available for this recipe.',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  const SizedBox(height: 32), // Reduced spacing
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: isDark ? Colors.black26 : Colors.white,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _recipe.imageUrl != null
            ? Image.network(
                _recipe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      child: Center(
        child: AppLogo(
          size: 120,
          iconColor: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
    );
  }

  Widget _buildRecipeHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _recipe.name,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.2,
                ),
              ),
            ),
            if (_recipe.source == 'FoodGapp' || _recipe.source == 'gemini')
              _buildSourceBadge('Verified', Colors.blueAccent),
            if (_recipe.source == 'spoonacular' && _recipe.isVerified)
              _buildSourceBadge('USDA Verified', Colors.greenAccent),
          ],
        ),
        if (_recipe.aiReasoning != null) ...[
          const SizedBox(height: 16),
          _buildAiReasoning(_recipe.aiReasoning!),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Source: ${_recipe.source}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '·  ${_recipe.displayIngredientCount} ingredients',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAiReasoning(String reasoning) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reasoning,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(bool isDark) {
    String format(double? val, String unit) => val != null ? '${val.round()} $unit' : '--';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildNutrientCard('Calories', format(_recipe.calories, 'kcal'), Icons.local_fire_department, Colors.orangeAccent, isDark),
        _buildNutrientCard('Protein', format(_recipe.protein, 'g'), Icons.restaurant, Colors.redAccent, isDark),
        _buildNutrientCard('Carbs', format(_recipe.carbs, 'g'), Icons.bakery_dining, Colors.blueAccent, isDark),
        _buildNutrientCard('Fat', format(_recipe.fat, 'g'), Icons.water_drop, Colors.greenAccent, isDark),
      ],
    );
  }

  Widget _buildNutrientCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
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
              Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
              Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        children: _recipe.ingredients!.map((ing) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ing,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // More bottom padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), 
            blurRadius: 20, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPillAction(
              icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
              label: _isSaved ? 'Saved' : 'Save',
              onTap: _saveRecipe,
              isDark: isDark,
              isPrimary: false,
              color: _isSaved ? Colors.orangeAccent : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPillAction(
              icon: Icons.shopping_cart_outlined,
              label: 'List',
              onTap: _addIngredientsToList,
              isDark: isDark,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPillAction(
              icon: Icons.add_circle_outline,
              label: 'Log',
              onTap: _logMeal,
              isDark: isDark,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required bool isPrimary,
    Color? color,
  }) {
    final iconColor = color ?? (isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black54));
    final textColor = color ?? (isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87));

    return Material(
      color: isPrimary 
          ? (isDark ? const Color(0xFF333333) : Colors.black)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
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
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
