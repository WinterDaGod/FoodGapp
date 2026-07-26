import 'dart:convert';
import '../models/recipe.dart';
import '../models/weekly_plan.dart';
import '../services/auth_service.dart';
import '../services/nutrition_feedback_service.dart';
import '../services/recipe_repository.dart';
import '../services/database_helper.dart';
import '../services/api/gemini_service.dart';
import '../services/api/api_exceptions.dart';

class MealGenerationService {
  MealGenerationService._internal();
  static final MealGenerationService instance = MealGenerationService._internal();

  final _feedbackService = NutritionFeedbackService();
  final _recipeRepo = RecipeRepository();
  final _auth = AuthService();
  final _db = DatabaseHelper.instance;
  final _gemini = GeminiService();

  /// Suggests recipes that fit into the user's remaining calorie and macro
  /// budget for today.
  Future<List<Recipe>> generateSuggestions() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // 1. Get today's feedback to see what's remaining
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final feedback = await _feedbackService.loadDailyFeedback(userId, dateStr);

    // 2. Calculate "Remaining" budget
    final remainingKcal = feedback.target.energyKcal - feedback.intake.calories;
    final remainingProtein = feedback.target.proteinGrams.high - feedback.intake.protein;
    final remainingCarbs = feedback.target.carbsGrams.high - feedback.intake.carbs;
    final remainingFat = feedback.target.fatGrams.high - feedback.intake.fat;

    if (remainingKcal < 100) return [];

    // 3. Search for recipes within these bounds
    return _recipeRepo.searchByNutrition(
      minCalories: 100,
      maxCalories: remainingKcal.round(),
      minProtein: (remainingProtein > 5) ? 5 : 0,
      maxProtein: (remainingProtein > 0) ? remainingProtein.round() : 100,
      minCarbs: (remainingCarbs > 10) ? 10 : 0,
      maxCarbs: (remainingCarbs > 0) ? remainingCarbs.round() : 200,
      minFat: (remainingFat > 2) ? 2 : 0,
      maxFat: (remainingFat > 0) ? remainingFat.round() : 50,
      number: 5,
    );
  }

  /// Generates a full 3-meal plan based on specific user input.
  Future<List<Recipe>> generateDailyPlan({int? targetCalories, List<String>? diets}) async {
    final dietStr = diets?.join(',');
    final plan = await _recipeRepo.getDailyMealPlan(targetCalories: targetCalories, diet: dietStr);
    if (plan.isNotEmpty) {
      _savePlan(plan);
    }
    return plan;
  }

  /// Generates an AI-optimized 3-meal plan using Gemini to balance macros and variety.
  Future<List<Recipe>> generateSmartDailyPlan({
    required int targetKcal,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    List<String>? diets,
    String? preferences,
  }) async {
    try {
      // 1. PRIMARY: Generate from FoodGapp AI (Scratch) for bespoke creative plans
      final aiPlanData = await _gemini.generateDailyPlanFromScratch(
        targetKcal: targetKcal,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
        diets: diets,
        preferences: preferences,
      );

      if (aiPlanData != null && aiPlanData['meals'] != null) {
        final List<dynamic> meals = aiPlanData['meals'];
        final List<Recipe> plan = meals.map((m) {
          final ings = (m['ingredients'] as List?)?.cast<String>();
          return Recipe(
            apiMealId: m['id'] ?? 'gemini:${DateTime.now().millisecondsSinceEpoch}',
            name: m['title'] ?? 'AI Generated Meal',
            source: 'FoodGapp AI',
            calories: (m['calories'] as num?)?.toDouble(),
            protein: (m['protein'] as num?)?.toDouble(),
            carbs: (m['carbs'] as num?)?.toDouble(),
            fat: (m['fat'] as num?)?.toDouble(),
            ingredients: ings,
            ingredientCount: ings?.length,
            aiReasoning: m['aiReasoning'],
            isVerified: false,
          );
        }).toList();

        _savePlan(plan);
        return plan;
      }

      // 2. SECONDARY: AI generation failed, use Database Engine as reliable backup
      return await generateDailyPlan(targetCalories: targetKcal, diets: diets);

    } catch (e) {
      // 3. LAST RESORT: Try database one last time or rethrow
      print('AI-First generation failed ($e). Attempting database fallback.');
      try {
        return await generateDailyPlan(targetCalories: targetKcal, diets: diets);
      } catch (inner) {
        throw const ApiQuotaExceededException('All planning sources are currently busy.');
      }
    }
  }

  Future<void> _savePlan(List<Recipe> plan) async {
    final jsonStr = jsonEncode(plan.map((r) => {
      'id': r.apiMealId,
      'aiReasoning': r.aiReasoning,
      // If it's a bespoke AI meal, we need to save more info since it's not in the cache/API
      if (r.source == 'FoodGapp AI') 'fallback_data': {
        'name': r.name,
        'calories': r.calories,
        'protein': r.protein,
        'carbs': r.carbs,
        'fat': r.fat,
        'ingredients': r.ingredients,
      }
    }).toList());
    await _db.saveActiveMealPlan('day', jsonStr);
  }

  /// Generates a full 7-day, 3-meals-per-day plan.
  Future<WeeklyMealPlan?> generateWeeklyPlan({int? targetCalories, List<String>? diets, String? preferences}) async {
    try {
      // 1. PRIMARY: Generate from FoodGapp AI (Scratch) for bespoke creative weeks
      final aiPlanData = await _gemini.generateWeeklyPlanFromScratch(
        targetCalories: targetCalories ?? 2000,
        diets: diets,
        preferences: preferences,
      );

      if (aiPlanData != null && aiPlanData['week'] != null) {
        final Map<String, dynamic> weekJson = aiPlanData['week'];
        final Map<String, List<Recipe>> dayMap = {};

        weekJson.forEach((dayName, dayData) {
          final List<dynamic> meals = (dayData['meals'] as List?) ?? [];
          dayMap[dayName] = meals.map((m) {
            final ings = (m['ingredients'] as List?)?.cast<String>();
            return Recipe(
              apiMealId: m['id'] ?? 'gemini:week_${dayName}_${DateTime.now().millisecondsSinceEpoch}',
              name: m['title'] ?? 'AI Generated Meal',
              source: 'FoodGapp AI',
              calories: (m['calories'] as num?)?.toDouble(),
              protein: (m['protein'] as num?)?.toDouble(),
              carbs: (m['carbs'] as num?)?.toDouble(),
              fat: (m['fat'] as num?)?.toDouble(),
              ingredients: ings,
              ingredientCount: ings?.length,
              aiReasoning: m['aiReasoning'],
              isVerified: false,
            );
          }).toList();
        });

        final fullPlan = WeeklyMealPlan(days: dayMap);
        _saveWeeklyPlan(fullPlan);
        return fullPlan;
      }

      // 2. SECONDARY: AI failed, use Database Engine
      final dietStr = diets?.join(',');
      final plan = await _recipeRepo.getWeeklyMealPlan(targetCalories: targetCalories, diet: dietStr);
      if (plan != null) {
        _saveWeeklyPlan(plan);
      }
      return plan;

    } catch (e) {
      print('AI-First weekly generation failed ($e). Attempting database fallback.');
      final dietStr = diets?.join(',');
      return await _recipeRepo.getWeeklyMealPlan(targetCalories: targetCalories, diet: dietStr);
    }
  }

  Future<void> _saveWeeklyPlan(WeeklyMealPlan plan) async {
    final Map<String, dynamic> data = {
      'days': plan.days.map((key, value) => MapEntry(key, value.map((r) => {
        'id': r.apiMealId,
        'aiReasoning': r.aiReasoning,
        if (r.source == 'FoodGapp AI') 'fallback_data': {
          'name': r.name,
          'calories': r.calories,
          'protein': r.protein,
          'carbs': r.carbs,
          'fat': r.fat,
          'ingredients': r.ingredients,
        }
      }).toList())),
    };
    await _db.saveActiveMealPlan('week', jsonEncode(data));
  }

  /// Loads the last saved daily plan from the database.
  Future<List<Recipe>> loadLastDailyPlan() async {
    final jsonStr = await _db.getActiveMealPlan('day');
    if (jsonStr == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonStr);
    final List<Recipe> recipes = [];
    
    for (var item in decoded) {
      String id;
      String? reasoning;
      Map<String, dynamic>? fallbackData;
      
      if (item is String) {
        id = item;
      } else {
        id = item['id'];
        reasoning = item['aiReasoning'];
        fallbackData = item['fallback_data'];
      }

      if (fallbackData != null) {
        recipes.add(Recipe(
          apiMealId: id,
          name: fallbackData['name'] ?? 'AI Meal',
          source: 'FoodGapp AI',
          calories: (fallbackData['calories'] as num?)?.toDouble(),
          protein: (fallbackData['protein'] as num?)?.toDouble(),
          carbs: (fallbackData['carbs'] as num?)?.toDouble(),
          fat: (fallbackData['fat'] as num?)?.toDouble(),
          ingredients: (fallbackData['ingredients'] as List?)?.cast<String>(),
          aiReasoning: reasoning,
        ));
        continue;
      }

      final r = await _recipeRepo.getNutrition(id);
      if (r != null) {
        recipes.add(Recipe(
          apiMealId: r.apiMealId,
          name: r.name,
          source: r.source,
          imageUrl: r.imageUrl,
          calories: r.calories,
          protein: r.protein,
          carbs: r.carbs,
          fat: r.fat,
          ingredientCount: r.displayIngredientCount,
          author: r.author,
          isVerified: r.isVerified,
          ingredients: r.ingredients,
          aiReasoning: reasoning,
        ));
      }
    }
    return recipes;
  }

  /// Loads the last saved weekly plan from the database.
  Future<WeeklyMealPlan?> loadLastWeeklyPlan() async {
    final jsonStr = await _db.getActiveMealPlan('week');
    if (jsonStr == null) return null;

    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final Map<String, dynamic> daysData = data['days'] ?? {};
    
    final Map<String, List<Recipe>> dayMap = {};
    for (var entry in daysData.entries) {
      final List<dynamic> items = entry.value;
      final List<Recipe> recipes = [];
      for (var item in items) {
        String id;
        String? reasoning;
        Map<String, dynamic>? fallbackData;

        if (item is String) {
          id = item;
        } else {
          id = item['id'];
          reasoning = item['aiReasoning'];
          fallbackData = item['fallback_data'];
        }

        if (fallbackData != null) {
          recipes.add(Recipe(
            apiMealId: id,
            name: fallbackData['name'] ?? 'AI Meal',
            source: 'FoodGapp AI',
            calories: (fallbackData['calories'] as num?)?.toDouble(),
            protein: (fallbackData['protein'] as num?)?.toDouble(),
            carbs: (fallbackData['carbs'] as num?)?.toDouble(),
            fat: (fallbackData['fat'] as num?)?.toDouble(),
            ingredients: (fallbackData['ingredients'] as List?)?.cast<String>(),
            aiReasoning: reasoning,
          ));
          continue;
        }

        final r = await _recipeRepo.getNutrition(id);
        if (r != null) {
          recipes.add(Recipe(
            apiMealId: r.apiMealId,
            name: r.name,
            source: r.source,
            imageUrl: r.imageUrl,
            calories: r.calories,
            protein: r.protein,
            carbs: r.carbs,
            fat: r.fat,
            ingredientCount: r.displayIngredientCount,
            author: r.author,
            isVerified: r.isVerified,
            ingredients: r.ingredients,
            aiReasoning: reasoning,
          ));
        }
      }
      dayMap[entry.key] = recipes;
    }
    
    return WeeklyMealPlan(days: dayMap);
  }
}
