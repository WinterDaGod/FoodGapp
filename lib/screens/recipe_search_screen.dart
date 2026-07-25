import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/saved_meal.dart';
import '../services/api/api_exceptions.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/recipe_repository.dart';
import '../services/shopping_list_service.dart';
import 'recipe_detail_screen.dart';
import 'add_meal_screen.dart';
import 'widgets/app_loading.dart';
import 'widgets/recipe_widgets.dart';
import 'widgets/app_toast.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final _searchController = TextEditingController();
  final _repository = RecipeRepository();
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();

  List<Recipe> _communityResults = [];
  List<Recipe> _pantryResults = [];
  List<Recipe> _userRecipes = [];
  List<String> _pantryIngredients = [];
  final _pantryController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  int _activeTabIndex = 1; // 0: Saved, 1: Discover, 2: Pantry
  bool _isFallbackMode = false;
  bool _isQuotaExceeded = false;
  bool _isFiltersExpanded = true;
  bool _isShowingLocalLibrary = false;
  final Set<String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _loadUserRecipes();
    _loadInitialRecipes();
  }

  Future<void> _loadInitialRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isShowingLocalLibrary = false;
    });

    try {
      // Load some generic "healthy" recipes as featured content
      final results = await _repository.searchByName('healthy');
      if (mounted) {
        setState(() {
          _communityResults = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      // FALLBACK: If network/quota fails on start, show local cached recipes
      final localResults = await _repository.getFeaturedLocalRecipes();
      if (mounted) {
        setState(() {
          _communityResults = localResults;
          _isShowingLocalLibrary = localResults.isNotEmpty;
          _isLoading = false;
          if (localResults.isEmpty) {
             _error = 'Unable to load recipes. Please check your connection.';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadUserRecipes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final savedMeals = await _db.getSavedMeals(userId);
    final List<Recipe> recipes = [];

    for (final m in savedMeals) {
      // Try to get from cache to show macros if available
      final cached = m.apiMealId != null ? await _db.getCachedRecipe(m.apiMealId!) : null;
      if (cached != null) {
        recipes.add(cached);
      } else {
        // Precise source detection for fallback
        String source = 'themealdb';
        if (m.apiMealId?.startsWith('spoonacular') == true) source = 'spoonacular';
        if (m.apiMealId?.startsWith('gemini') == true) source = 'FoodGapp';

        recipes.add(Recipe(
          apiMealId: m.apiMealId ?? '',
          name: m.mealName ?? 'Untitled',
          source: source,
          imageUrl: m.imageUrl,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _userRecipes = recipes;
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _activeTabIndex = 1;
      _isFallbackMode = false;
      _isQuotaExceeded = false;
    });

    try {
      final results = await _repository.searchByName(
        query,
        diet: _selectedFilters.contains('Vegetarian') ? 'vegetarian' : null,
      );
      if (mounted) {
        setState(() {
          _communityResults = results;
          _isLoading = false;
          // In AI-First, "Fallback" means Gemini failed and we used a DB
          _isFallbackMode = results.isNotEmpty && results.first.source != 'FoodGapp';
        });
      }
    } on ApiQuotaExceededException {
      if (mounted) {
        setState(() {
          _isQuotaExceeded = true;
          _isLoading = false;
        });
        // Trigger a silent fallback search without diet if quota exceeded
        _searchFallbackSilent(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Recipe search failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchFallbackSilent(String query) async {
    // Attempt a search using the traditional DB only (TheMealDB)
    try {
      final results = await _repository.searchBackupOnly(query);
      if (mounted) {
        setState(() {
          _communityResults = results;
          _isFallbackMode = results.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _filterSearch(String filter) async {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      _isLoading = true;
      _activeTabIndex = 1;
      _isFallbackMode = false;
      _isQuotaExceeded = false;
    });

    if (_selectedFilters.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        _search();
      } else {
        await _loadInitialRecipes();
      }
      return;
    }

    try {
      final currentQuery = _searchController.text.trim();
      
      // Combine all filters into a descriptive prompt
      String semanticQuery = currentQuery;
      if (semanticQuery.isEmpty) {
        semanticQuery = _selectedFilters.join(', ');
      } else {
        semanticQuery += ' with filters: ${_selectedFilters.join(', ')}';
      }

      // Check for restrictive macro filters
      int? maxCal;
      int? minProt;
      int? maxCarb;

      if (_selectedFilters.contains('High Protein')) minProt = 25;
      if (_selectedFilters.contains('Low Carb')) maxCarb = 15;
      if (_selectedFilters.contains('Low Calorie') || _selectedFilters.contains('Weight Loss')) {
        maxCal = 350;
      }

      final results = await _repository.searchByNutrition(
        minCalories: 0,
        maxCalories: maxCal,
        minProtein: minProt,
        maxCarbs: maxCarb,
        number: 15,
      );

      // If nutrition search was too broad or didn't capture all intent, 
      // let searchByName (Gemini) handle the semantic combination.
      List<Recipe> finalResults = results;
      if (_selectedFilters.length > 1 || currentQuery.isNotEmpty) {
        finalResults = await _repository.searchByName(semanticQuery, 
          diet: _selectedFilters.firstWhere((f) => ['Vegetarian', 'Vegan', 'Keto', 'Paleo'].contains(f), orElse: () => '').toLowerCase()
        );
      }

      if (mounted) {
        setState(() {
          _communityResults = finalResults;
          _isLoading = false;
          _isFallbackMode = finalResults.isNotEmpty && finalResults.first.source != 'FoodGapp';
        });
      }
    } on ApiQuotaExceededException {
      if (mounted) {
        final currentQuery = _searchController.text.trim();
        final fallbackTerm = currentQuery.isNotEmpty ? currentQuery : _selectedFilters.join(' ');
        
        setState(() {
          _isQuotaExceeded = true;
          _isLoading = false;
          _searchFallbackSilent(fallbackTerm);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Filtering recipes failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _isLoading = true;
    });
    if (_searchController.text.isNotEmpty) {
      _search();
    } else {
      _loadInitialRecipes();
    }
  }

  Future<void> _searchPantry() async {
    if (_pantryIngredients.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _repository.searchByPantry(_pantryIngredients);
      if (mounted) {
        setState(() {
          _pantryResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Pantry search failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final alreadySaved = await _db.isSaved(userId, recipe.apiMealId);

    if (alreadySaved) {
      await _db.deleteSavedMeal(userId, recipe.apiMealId);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Removed from your recipes.',
          title: 'Removed',
          type: ToastType.info,
        );
      }
    } else {
      // Ensure nutrition is cached before saving the bookmark
      if (recipe.hasNutrition) {
        await _db.cacheRecipe(recipe);
      }

      final savedMeal = SavedMeal(
        userId: userId,
        apiMealId: recipe.apiMealId,
        mealName: recipe.name,
        imageUrl: recipe.imageUrl,
      );

      await _db.insertSavedMeal(savedMeal);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Saved to your recipes tab.',
          title: 'Recipe Saved',
          type: ToastType.success,
        );
      }
    }

    _loadUserRecipes();
  }

  Future<void> _addIngredientsToList(Recipe recipe) async {
    // We need ingredients, if they are missing (e.g. from Discover or Pantry search)
    // we fetch them using getNutrition which handles caching.
    Recipe? fullRecipe = recipe;
    if (recipe.ingredients == null || recipe.ingredients!.isEmpty) {
      setState(() => _isLoading = true);
      fullRecipe = await _repository.getNutrition(recipe.apiMealId);
      if (mounted) setState(() => _isLoading = false);
    }

    if (fullRecipe != null) {
      await ShoppingListService.instance.addIngredientsFromRecipe(fullRecipe);
      if (mounted) {
        AppToast.show(
          context,
          message: 'All ingredients added to your shopping list.',
          title: 'Added to List',
          type: ToastType.success,
        );
      }
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 24),
              if (_activeTabIndex == 1) ...[
                _buildSearchBar(),
                if (_isQuotaExceeded) _buildQuotaWarning(),
                if ((_isFallbackMode || _isShowingLocalLibrary) && !_isQuotaExceeded) _buildFallbackWarning(),
                const SizedBox(height: 16),
                AnimatedCrossFade(
                  firstChild: _buildFilterChips(),
                  secondChild: const SizedBox(width: double.infinity),
                  crossFadeState: _isFiltersExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 24),
              ],
              if (_activeTabIndex == 2) ...[
                _buildPantryInput(),
                const SizedBox(height: 24),
              ],
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.headlineMedium?.color ?? (isDark ? Colors.white : Colors.black87);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recipes',
          style: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: textColor,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
              boxShadow: !isDark ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Icon(Icons.close, color: isDark ? Colors.white : Colors.black, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SegmentedTab(
            label: 'Saved',
            isSelected: _activeTabIndex == 0,
            onTap: () => setState(() => _activeTabIndex = 0),
          ),
          SegmentedTab(
            label: 'Discover',
            isSelected: _activeTabIndex == 1,
            onTap: () => setState(() => _activeTabIndex = 1),
          ),
          SegmentedTab(
            label: 'Pantry',
            isSelected: _activeTabIndex == 2,
            onTap: () => setState(() => _activeTabIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _search,
            child: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search community recipes',
                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _communityResults = [];
                    _isFallbackMode = false;
                    _isQuotaExceeded = false;
                  });
                },
                child: Icon(Icons.close, color: isDark ? Colors.white38 : Colors.black38, size: 20),
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isFiltersExpanded 
                    ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isFiltersExpanded ? Icons.filter_list_off : Icons.filter_list,
                color: _isFiltersExpanded 
                    ? (isDark ? Colors.greenAccent : Colors.orangeAccent)
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaWarning() {
    final backupSource = 'Spoonacular';
    final fallbackSource = 'TheMealDB';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Daily $backupSource limit reached. Switching to $fallbackSource (Basic results without nutrition).',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackWarning() {
    final aiSource = 'FoodGapp';
    final backupSource = 'Spoonacular';
    final fallbackSource = 'TheMealDB';
    
    String message = 'Primary source unavailable. Some nutrition data may be missing.';
    if (_isShowingLocalLibrary) {
      message = 'Showing featured recipes from your local library (Cloud source offline).';
    } else if (_isFallbackMode) {
      if (_isQuotaExceeded) {
        message = 'Both $aiSource and $backupSource are offline. Using $fallbackSource (Basic data only).';
      } else {
        message = '$aiSource engine is busy. Using $backupSource verified database.';
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.blue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            if (_selectedFilters.isNotEmpty)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: Colors.orangeAccent,
                ),
              ),
          ],
        ),
        _buildCategoryGroup('🎯 Goals', ['High Protein', 'Weight Loss', 'Muscle Gain', 'Energy Boost'], isDark),
        const SizedBox(height: 16),
        _buildCategoryGroup('⚡ Speed', ['Under 15m', 'No-Cook', '5 Ingredients'], isDark),
        const SizedBox(height: 16),
        _buildCategoryGroup('🌱 Diet', ['Keto', 'Vegan', 'Paleo', 'Vegetarian'], isDark),
        const SizedBox(height: 16),
        _buildCategoryGroup('🍽️ Meal', ['Breakfast', 'Lunch', 'Dinner', 'Snacks'], isDark),
      ],
    );
  }

  Widget _buildCategoryGroup(String title, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((f) {
              final isSelected = _selectedFilters.contains(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) => _filterSearch(f),
                  backgroundColor: Theme.of(context).cardColor,
                  selectedColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? Colors.white38 : Colors.black38),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: isSelected 
                        ? (isDark ? Colors.white24 : Colors.greenAccent) 
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPantryInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              Text(
                'Add ingredients you have',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
              ),
              const Spacer(),
              if (_pantryIngredients.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _pantryIngredients.clear()),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _pantryController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. Chicken, Broccoli',
                hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orangeAccent),
                  onPressed: () {
                    if (_pantryController.text.isNotEmpty) {
                      setState(() {
                        _pantryIngredients.add(_pantryController.text.trim());
                        _pantryController.clear();
                      });
                    }
                  },
                ),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  setState(() {
                    _pantryIngredients.add(val.trim());
                    _pantryController.clear();
                  });
                }
              },
            ),
          ),
          if (_pantryIngredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pantryIngredients.map((ing) => Chip(
                label: Text(ing),
                onDeleted: () => setState(() => _pantryIngredients.remove(ing)),
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                deleteIconColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pantryIngredients.isEmpty ? null : _searchPantry,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Ask AI Pantry Chef', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const AppLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    List<Recipe> results;
    if (_activeTabIndex == 0) {
      results = _userRecipes;
    } else if (_activeTabIndex == 1) {
      results = _communityResults;
    } else {
      results = _pantryResults;
    }

    if (results.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      String emptyMsg = 'Search for your next meal!';
      if (_activeTabIndex == 0) emptyMsg = 'No saved recipes yet.';
      if (_activeTabIndex == 2) emptyMsg = 'Add ingredients to find recipes.';

      return Center(
        child: Text(
          emptyMsg,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black26),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        final bool isSaved = _userRecipes.any((r) => r.apiMealId == recipe.apiMealId);
        
        return RecipeDiscoveryCard(
          recipe: recipe,
          isSaved: isSaved,
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            ).then((_) => _loadUserRecipes()); // Refresh if returned from detail
          },
          onSave: () => _saveRecipe(recipe),
          onLog: () => _logMeal(recipe),
          onAddToCart: () => _addIngredientsToList(recipe),
        );
      },
    );
  }
}
