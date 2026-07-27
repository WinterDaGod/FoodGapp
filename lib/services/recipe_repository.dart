import '../models/recipe.dart';
import '../models/weekly_plan.dart';
import 'api/api_exceptions.dart';
import 'api/spoonacular_service.dart';
import 'api/the_meal_db_service.dart';
import 'api/foodgapp_ai_service.dart';
import 'database_helper.dart';
import 'nutrition_cache_store.dart';

/// Single entry point the app uses for recipes and nutrition. It hides the
/// data sources and the cache behind one API.
///
/// Policy:
///  * FoodGapp AI is primary for discovery and creativity.
///  * Spoonacular is the reliable backup for traditional recipes.
///  * TheMealDB is the emergency backup.
class RecipeRepository {
  RecipeRepository({
    SpoonacularService? spoonacular,
    TheMealDbService? theMealDb,
    FoodGappAiService? ai,
    NutritionCacheStore? cache,
  })  : _spoonacular = spoonacular ?? SpoonacularService(),
        _theMealDb = theMealDb ?? TheMealDbService(),
        _ai = ai ?? FoodGappAiService(),
        _cache = cache ?? DbNutritionCache();

  final SpoonacularService _spoonacular;
  final TheMealDbService _theMealDb;
  final FoodGappAiService _ai;
  final NutritionCacheStore _cache;

  /// Searches recipes by name. Tries FoodGapp AI first for creative results, 
  /// falls back to Spoonacular/TheMealDB if AI fails.
  Future<List<Recipe>> searchByName(String query, {String? diet}) async {
    final trimmed = query.trim();
    
    // If no query and no diet, return empty.
    if (trimmed.isEmpty && (diet == null || diet.isEmpty)) {
      return [];
    }

    // Use diet as the query if the search text is empty (AI semantic search)
    final effectiveQuery = trimmed.isNotEmpty ? trimmed : (diet ?? '');

    // 1. Try FoodGapp AI as primary
    try {
      final aiResults = await _ai.searchRecipes(query: effectiveQuery, diet: diet);
      if (aiResults != null && aiResults.isNotEmpty) {
        final recipes = aiResults.map((m) {
          final ings = (m['ingredients'] as List?)?.cast<String>();
          return Recipe(
            apiMealId: m['id'] ?? 'gemini:search_${DateTime.now().millisecondsSinceEpoch}',
            name: m['title'] ?? 'AI Recipe',
            source: 'FoodGapp',
            calories: (m['calories'] as num?)?.toDouble(),
            protein: (m['protein'] as num?)?.toDouble(),
            carbs: (m['carbs'] as num?)?.toDouble(),
            fat: (m['fat'] as num?)?.toDouble(),
            ingredients: ings,
            ingredientCount: ings?.length,
            aiReasoning: m['aiReasoning'],
            isVerified: true,
          );
        }).toList();
        
        await _cacheAll(recipes);
        return recipes;
      }
    } catch (e) {
      print('FoodGapp AI primary search failed: $e. Falling back...');
    }

    // 2. Fallback to Spoonacular
    List<Recipe> results;
    try {
      // Spoonacular searchByName might require a query. If empty, we use effectiveQuery.
      results = await _spoonacular.searchByName(effectiveQuery, diet: diet);
    } on ApiQuotaExceededException {
      rethrow;
    } on ApiException {
      results = const [];
    }

    if (results.isEmpty && trimmed.isNotEmpty) {
      results = await _searchBackup(trimmed);
    }

    await _cacheAll(results);
    return results;
  }

  /// Searches recipes by a nutrition window (calories / macros). Prioritizes AI
  /// for custom macro alignment.
  Future<List<Recipe>> searchByNutrition({
    int? minCalories,
    int? maxCalories,
    int? minProtein,
    int? maxProtein,
    int? minCarbs,
    int? maxCarbs,
    int? minFat,
    int? maxFat,
    String? diet,
    int number = 10,
  }) async {
    // 1. Try FoodGapp AI
    try {
      // Build a descriptive query for the AI to ensure a diverse range of results
      String query = 'Recipes';
      if (maxCalories != null) {
        query = 'Healthy recipes between ${minCalories ?? 0} and $maxCalories calories';
      } else if (minProtein != null) {
        query = 'High protein recipes with at least $minProtein g protein';
      }

      final aiResults = await _ai.searchRecipes(
        query: query, 
        diet: diet,
        number: number
      );
      if (aiResults != null && aiResults.isNotEmpty) {
        final recipes = aiResults.map((m) {
          final ings = (m['ingredients'] as List?)?.cast<String>();
          return Recipe(
            apiMealId: m['id'] ?? 'gemini:nutri_${DateTime.now().millisecondsSinceEpoch}',
            name: m['title'] ?? 'AI Recipe',
            source: 'FoodGapp',
            calories: (m['calories'] as num?)?.toDouble(),
            protein: (m['protein'] as num?)?.toDouble(),
            carbs: (m['carbs'] as num?)?.toDouble(),
            fat: (m['fat'] as num?)?.toDouble(),
            ingredients: ings,
            ingredientCount: ings?.length,
            aiReasoning: m['aiReasoning'],
            isVerified: true,
          );
        }).toList();
        
        await _cacheAll(recipes);
        return recipes;
      }
    } catch (_) {}

    // 2. Fallback to Spoonacular
    try {
      final results = await _spoonacular.searchByNutrition(
        minCalories: minCalories,
        maxCalories: maxCalories,
        minProtein: minProtein,
        maxProtein: maxProtein,
        minCarbs: minCarbs,
        maxCarbs: maxCarbs,
        minFat: minFat,
        maxFat: maxFat,
        number: number,
      );
      
      if (results.isEmpty) return [];

      final ids = results.map((r) => r.apiMealId.split(':').last).toList();
      
      // NOTE: Spoonacular's findByNutrients doesn't support diet filters directly.
      // We rely on getInformationBulk to get full details and could filter here if needed,
      // or warn that backup macro search is "Best Effort" for diets.
      final fullResults = await _spoonacular.getInformationBulk(ids);

      await _cacheAll(fullResults);
      return fullResults;
    } on ApiQuotaExceededException {
      rethrow;
    } on ApiException {
      return [];
    }
  }

  /// Searches recipes by ingredients in your pantry. Prioritizes AI for
  /// "Chef" style creative suggestions.
  Future<List<Recipe>> searchByPantry(List<String> ingredients) async {
    // 1. Try FoodGapp AI
    try {
      final aiResults = await _ai.chefFromPantry(ingredients: ingredients);
      if (aiResults != null && aiResults.isNotEmpty) {
        final recipes = aiResults.map((m) {
          final ings = (m['ingredients'] as List?)?.cast<String>();
          return Recipe(
            apiMealId: m['id'] ?? 'gemini:pantry_${DateTime.now().millisecondsSinceEpoch}',
            name: m['title'] ?? 'Pantry AI Recipe',
            source: 'FoodGapp',
            calories: (m['calories'] as num?)?.toDouble(),
            protein: (m['protein'] as num?)?.toDouble(),
            carbs: (m['carbs'] as num?)?.toDouble(),
            fat: (m['fat'] as num?)?.toDouble(),
            ingredients: ings,
            ingredientCount: ings?.length,
            aiReasoning: m['aiReasoning'],
            isVerified: true,
          );
        }).toList();
        
        await _cacheAll(recipes);
        return recipes;
      }
    } catch (_) {}

    // 2. Fallback to Spoonacular
    try {
      final results = await _spoonacular.findByIngredients(ingredients);
      if (results.isEmpty) return [];
      
      final ids = results.map((r) => r.apiMealId.split(':').last).toList();
      final fullResults = await _spoonacular.getInformationBulk(ids);
      
      await _cacheAll(fullResults);
      return fullResults;
    } on ApiQuotaExceededException {
      rethrow;
    } on ApiException {
      return [];
    }
  }

  /// Returns full nutrition for a recipe, cache-first. Only Spoonacular items
  /// can be fetched on a cache miss; TheMealDB items have no nutrition, so
  /// they resolve to null unless already cached.
  Future<Recipe?> getNutrition(String apiMealId) async {
    final cached = await _cache.get(apiMealId);
    if (cached != null) return cached;

    Recipe? fetched;
    try {
      const prefix = 'spoonacular:';
      if (apiMealId.startsWith(prefix)) {
        fetched = await _spoonacular.getInformation(
          apiMealId.substring(prefix.length),
        );
      }
    } on ApiException {
      return null;
    }

    if (fetched != null && fetched.hasNutrition) {
      await _cache.put(fetched);
    }
    return fetched;
  }

  /// Generates a full daily meal plan (3 meals) based on user input.
  Future<List<Recipe>> getDailyMealPlan({int? targetCalories, String? diet}) async {
    try {
      final plan = await _spoonacular.generateMealPlan(
        targetCalories: targetCalories,
        diet: diet,
        timeFrame: 'day',
      );

      final List mealsJson = plan['meals'] ?? [];
      if (mealsJson.isEmpty) return [];

      final List<String> ids = mealsJson.map((m) => m['id'].toString()).toList();
      
      // Try to fetch bulk info for better performance and point efficiency
      final fullMeals = await _spoonacular.getInformationBulk(ids);

      // Cache the results
      for (var meal in fullMeals) {
        if (meal.hasNutrition) {
          await _cache.put(meal);
        }
      }

      return fullMeals;
    } on ApiException catch (e) {
      print('Meal plan generation failed: $e');
      rethrow; // Rethrow to let UI handle it (e.g. quota exceeded)
    }
  }

  /// Generates a full weekly meal plan (7 days, 3 meals each) based on user input.
  Future<WeeklyMealPlan?> getWeeklyMealPlan({int? targetCalories, String? diet}) async {
    try {
      final plan = await _spoonacular.generateMealPlan(
        targetCalories: targetCalories,
        diet: diet,
        timeFrame: 'week',
      );

      final week = plan['week'] as Map<String, dynamic>? ?? {};
      final Set<String> allIds = {};
      
      week.forEach((_, dayData) {
        final meals = (dayData['meals'] as List?) ?? [];
        for (var m in meals) {
          allIds.add(m['id'].toString());
        }
      });

      if (allIds.isEmpty) return null;

      // Fetch all details in one bulk call
      final List<Recipe> fullRecipesList = await _spoonacular.getInformationBulk(allIds.toList());
      final Map<String, Recipe> fullRecipesMap = {
        for (var r in fullRecipesList) r.apiMealId: r
      };

      // Cache everything
      for (var meal in fullRecipesList) {
        if (meal.hasNutrition) await _cache.put(meal);
      }

      return WeeklyMealPlan.fromSpoonacular(plan, fullRecipesMap);
    } on ApiException catch (e) {
      print('Weekly meal plan generation failed: $e');
      rethrow;
    }
  }

  /// Forces a search using the backup source (TheMealDB). Used when primary
  /// quotas are exhausted.
  Future<List<Recipe>> searchBackupOnly(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    return await _searchBackup(trimmed);
  }

  Future<List<Recipe>> _searchBackup(String query) async {
    try {
      return await _theMealDb.searchByName(query);
    } on ApiQuotaExceededException {
      rethrow;
    } on ApiException {
      return [];
    }
  }

  /// Returns a random selection of previously discovered recipes from the
  /// local database.
  Future<List<Recipe>> getFeaturedLocalRecipes({int limit = 10}) async {
    try {
      final db = DatabaseHelper.instance;
      return await db.getRandomCachedRecipes(limit: limit);
    } catch (_) {
      return [];
    }
  }

  /// Caches only results that actually carry nutrition, so we never store
  /// null-macro (TheMealDB) rows as if they were complete.
  Future<void> _cacheAll(List<Recipe> recipes) async {
    for (final recipe in recipes) {
      if (recipe.hasNutrition) await _cache.put(recipe);
    }
  }

  void dispose() {
    _spoonacular.dispose();
    _theMealDb.dispose();
  }
}
