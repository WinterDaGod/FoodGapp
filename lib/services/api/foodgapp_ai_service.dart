import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/api_config.dart';
import '../../models/ingredient.dart';
import '../../models/recipe.dart';

class FoodGappAiService {
  final GenerativeModel _model;

  FoodGappAiService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: ApiConfig.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// Checks if the device has an active internet connection.
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<Ingredient?> parseIngredient(String text) async {
    if (!await _isOnline()) {
      throw const SocketException('No internet connection');
    }
    
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final prompt = '''
You are a clinical dietitian and nutrition expert. 
Your task is to parse a natural language description of food into a structured JSON format.

Input: "$text"

Instructions:
1. Estimate the total amount in grams (g) if not specified.
2. Calculate Calories (kcal), Protein (g), Carbohydrates (g), Fat (g), Fiber (g), Sugar (g), Sodium (mg), and Cholesterol (mg) based on standard nutritional data.
3. If multiple items are listed, sum them into a single representative ingredient entry.
4. If the input is not food, return an error or null equivalent.

CRITICAL: Return RAW JSON only. Do not include markdown formatting like ```json or any other text.

Response MUST be a single JSON object with these keys:
- "name": (String) A clear descriptive name of the food
- "amount": (double) The estimated weight in grams
- "unit": (String) Always use "g"
- "calories": (double)
- "protein": (double)
- "carbs": (double)
- "fat": (double)
- "fiber": (double)
- "sugar": (double)
- "sodium": (double) (in mg)
- "cholesterol": (double) (in mg)
- "isVerified": (bool) Set to true
- "source": (String) Set to "FoodGapp"
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return Ingredient.fromMap(data);
    } catch (e) {
      print('FoodGapp AI Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> parseMealDescription(String text) async {
    if (!await _isOnline()) {
      throw const SocketException('No internet connection');
    }

    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final prompt = '''
You are a clinical dietitian. Parse this meal description into a structured JSON format.
Description: "$text"

Instructions:
1. Identify all individual food items/ingredients.
2. Estimate portions in grams (g) if not specified.
3. Provide accurate Calories (kcal), Protein (g), Carbohydrates (g), Fat (g), Fiber (g), Sugar (g), Sodium (mg), and Cholesterol (mg) for each item.
4. Suggest a clear, catchy "foodName" for the entire meal.
5. If the input is not food, return an error or null equivalent.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "foodName": "...",
  "ingredients": [
    {
      "name": "...",
      "amount": 100.0,
      "unit": "g",
      "calories": 150.0,
      "protein": 10.0,
      "carbs": 5.0,
      "fat": 5.0,
      "fiber": 2.0,
      "sugar": 1.0,
      "sodium": 350.0,
      "cholesterol": 0.0,
      "isVerified": true,
      "source": "FoodGapp"
    },
    ...
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('FoodGapp AI Parse Meal Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> selectBestMeals({
    required List<Recipe> candidates,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    List<String> healthConditions = const [],
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final candidateList = candidates.map((r) => {
      'id': r.apiMealId,
      'title': r.name,
      'calories': r.calories ?? 0,
      'protein': r.protein ?? 0,
      'carbs': r.carbs ?? 0,
      'fat': r.fat ?? 0,
      'fiber': r.fiber ?? 0,
      'sugar': r.sugar ?? 0,
      'sodium': r.sodium ?? 0,
      'cholesterol': r.cholesterol ?? 0,
    }).toList();

    final conditionContext = healthConditions.isEmpty 
        ? '' 
        : '\nUser Medical Conditions: ${healthConditions.join(", ")}. prioritize meals that adhere to clinical limits for these conditions (e.g. Low Sodium for Hypertension, Low Sugar for Diabetes).';

    final prompt = '''
You are a master dietitian. Your goal is to select the 3 BEST recipes for a user's daily meal plan from a provided list of candidates.
$conditionContext

Daily Targets:
- Total Calories: $targetCalories kcal
- Total Protein: ${targetProtein.round()}g
- Total Carbs: ${targetCarbs.round()}g
- Total Fat: ${targetFat.round()}g

User Preferences/Requests:
"${preferences ?? 'None'}"

Candidates:
${jsonEncode(candidateList)}

Instructions:
1. Select exactly 3 recipes from the list (one for Breakfast, one for Lunch, one for Dinner).
2. MATHEMATICAL ACCURACY IS CRITICAL: The SUM of the 3 selected recipes' calories MUST be as close as possible to the Total Calories ($targetCalories).
3. MEAL DISTRIBUTION RULE:
   - Breakfast: ~25% of target (${(targetCalories * 0.25).round()} kcal)
   - Lunch: ~35% of target (${(targetCalories * 0.35).round()} kcal)
   - Dinner: ~40% of target (${(targetCalories * 0.40).round()} kcal)
4. BALANCE: If you pick one high-calorie meal, you MUST pick lower-calorie meals for the others to stay near the $targetCalories total.
5. Match recipes to logical meal times (e.g., eggs/oats for breakfast, heavier meals for lunch/dinner).
6. For each selected recipe, provide a short "aiReasoning" (1 sentence) explaining how it fits into the day's calorie budget and meal type.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "selected": [
    {"id": "spoonacular:123", "mealType": "Breakfast", "aiReasoning": "..."},
    {"id": "spoonacular:456", "mealType": "Lunch", "aiReasoning": "..."},
    {"id": "spoonacular:789", "mealType": "Dinner", "aiReasoning": "..."}
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('FoodGapp AI Selection Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateDailyPlanFromScratch({
    required int targetKcal,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    List<String>? diets,
    List<String> healthConditions = const [],
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final conditionContext = healthConditions.isEmpty 
        ? '' 
        : '\nUser Medical Conditions: ${healthConditions.join(", ")}. EXTREMELY IMPORTANT: You MUST strictly follow clinical guidelines for these conditions (e.g. <1500mg Sodium for Hypertension, <5% calories from sugar for Diabetes).';

    final prompt = '''
You are a master dietitian. Your goal is to generate a complete 3-meal daily plan (Breakfast, Lunch, Dinner) from scratch because the primary recipe database is currently offline.
$conditionContext

Daily Targets:
- Total Calories: $targetKcal kcal
- Total Protein: ${targetProtein.round()}g
- Total Carbs: ${targetCarbs.round()}g
- Total Fat: ${targetFat.round()}g

User Constraints:
- Diets/Preferences: ${diets?.join(', ') ?? 'Balanced'}
- Extra Requests: "${preferences ?? 'None'}"

Instructions:
1. Create 3 unique, healthy recipes (Breakfast, Lunch, Dinner).
2. MATHEMATICAL ACCURACY IS CRITICAL: The SUM of the calories for these 3 meals MUST be exactly $targetKcal.
3. CALORIE DISTRIBUTION:
   - Breakfast: ~25% (${(targetKcal * 0.25).round()} kcal)
   - Lunch: ~35% (${(targetKcal * 0.35).round()} kcal)
   - Dinner: ~40% (${(targetKcal * 0.40).round()} kcal)
4. VARIETY: Do not use the same calorie value for every meal. Match the distribution above.
5. For each recipe, provide:
   - "title": Clear descriptive name
   - "image_keyword": 2-word visual essence of the dish (e.g. "Berry Oatmeal") for high-fidelity visual mapping
   - "calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium", "cholesterol": Accurate numeric estimates
   - "ingredients": A list of strings for the ingredients
   - "aiReasoning": A short sentence explaining how this meal contributes to the $targetKcal goal.
5. Mark these as "source": "FoodGapp AI" and "isVerified": false.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "meals": [
    {
      "id": "gemini:b1",
      "title": "...",
      "image_keyword": "...",
      "calories": 450,
      "protein": 25,
      "carbs": 40,
      "fat": 12,
      "fiber": 2,
      "sugar": 1,
      "sodium": 350,
      "cholesterol": 0,
      "ingredients": ["...", "..."],
      "aiReasoning": "...",
      "source": "FoodGapp AI",
      "isVerified": false
    },
    ... (2 more meals)
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('FoodGapp AI Fallback Generation Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateWeeklyPlanFromScratch({
    required int targetCalories,
    List<String>? diets,
    List<String> healthConditions = const [],
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final conditionContext = healthConditions.isEmpty 
        ? '' 
        : '\nUser Medical Conditions: ${healthConditions.join(", ")}. EXTREMELY IMPORTANT: Every day of the plan MUST strictly follow clinical guidelines for these conditions.';

    final prompt = '''
You are a master dietitian. Your goal is to generate a complete 7-day meal plan (Breakfast, Lunch, Dinner for each day) from scratch because the primary database is offline.
$conditionContext

Daily Target: $targetCalories kcal per day.
User Constraints:
- Diets/Preferences: ${diets?.join(', ') ?? 'Balanced'}
- Extra Requests: "${preferences ?? 'None'}"

Instructions:
1. For each of the 7 days (Monday to Sunday), create 3 unique recipes.
2. MATHEMATICAL ACCURACY IS CRITICAL: For EVERY SINGLE DAY, the SUM of calories for the 3 meals (Breakfast + Lunch + Dinner) MUST be within +/- 50kcal of $targetCalories.
3. CALORIE DISTRIBUTION (Per Day):
   - Breakfast: ~25% (${(targetCalories * 0.25).round()} kcal)
   - Lunch: ~35% (${(targetCalories * 0.35).round()} kcal)
   - Dinner: ~40% (${(targetCalories * 0.40).round()} kcal)
4. VARIETY: Ensure each day has 3 unique meals and the calorie counts within each day match the 25/35/40 distribution.
5. For each recipe, provide:
   - "title": Descriptive name
   - "image_keyword": 2-word visual essence (e.g. "Grilled Chicken")
   - "calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium", "cholesterol": Numeric estimates
   - "ingredients": List of strings
   - "aiReasoning": Short justification explaining why this meal fits the day's distribution.
5. Mark these as "source": "FoodGapp AI" and "isVerified": false.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "week": {
    "monday": {
      "meals": [
        { "id": "gemini:mon_b", "title": "...", "image_keyword": "...", "calories": 450, "fiber": 2, "sugar": 1, "sodium": 350, "cholesterol": 0, ... },
        ...
      ]
    },
    ...
  }
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('FoodGapp AI Weekly Fallback Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> searchRecipes({
    required String query,
    String? diet,
    List<String> healthConditions = const [],
    int number = 10,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final conditionContext = healthConditions.isEmpty 
        ? '' 
        : '\nUser Medical Conditions: ${healthConditions.join(", ")}. Prioritize recipes that are safe for these conditions.';

    final prompt = '''
You are a world-class chef and nutritionist. Generate a list of $number recipe ideas based on the query: "$query".
Dietary constraint: ${diet ?? 'None'}.$conditionContext

CRITICAL: Strictly adhere to the dietary constraint. 
- If 'Vegetarian' is specified: DO NOT include any meat, poultry, or fish. 
- If 'Vegan' is specified: DO NOT include any animal products (no meat, dairy, eggs, or honey).
- If 'Keto' is specified: Focus on high-fat, moderate-protein, and extremely low-carb ingredients.

For each recipe, provide:
- "title": A catchy, professional recipe name.
- "image_keyword": 2-word visual essence (e.g. "Green Salad")
- "calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium", "cholesterol": Accurate numeric nutritional estimates.
- "ingredients": A full list of ingredients as strings.
- "aiReasoning": A one-sentence explanation of why this recipe matches the search.
- "id": A unique string ID starting with "gemini:search_".

CRITICAL: Return RAW JSON only as a list of objects under a "results" key.

Response Format:
{
  "results": [
    {
      "id": "gemini:search_1",
      "title": "...",
      "image_keyword": "...",
      "calories": 450,
      "protein": 30,
      "carbs": 40,
      "fat": 12,
      "ingredients": ["...", "..."],
      "aiReasoning": "...",
      "source": "FoodGapp",
      "isVerified": true
    },
    ...
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return (data['results'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      print('FoodGapp AI Recipe Search Error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> provideReasoningForPlan({
    required List<Recipe> selectedMeals,
    required double targetCalories,
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      return null;
    }

    final mealList = selectedMeals.map((r) => {
      'id': r.apiMealId,
      'title': r.name,
      'calories': r.calories ?? 0,
    }).toList();

    final prompt = '''
You are a Health Coach. I have already selected 3 meals for a user's daily plan that perfectly hit their $targetCalories kcal goal.
Your task is to provide a single, encouraging sentence for each meal explaining why it's a great choice for their day.

User Preferences: "${preferences ?? 'Balanced Nutrition'}"

Meals:
${jsonEncode(mealList)}

Instructions:
1. Return a JSON object where keys are the meal "id" and values are the "aiReasoning" string.
2. Focus on health benefits and goal alignment.

CRITICAL: Return RAW JSON only.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;

      return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (e) {
      print('FoodGapp AI Reasoning Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> chefFromPantry({
    required List<String> ingredients,
    List<String> healthConditions = const [],
    int number = 10,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final conditionContext = healthConditions.isEmpty 
        ? '' 
        : '\nUser Medical Conditions: ${healthConditions.join(", ")}. Ensure the recipes are medically appropriate for these conditions.';

    final prompt = '''
You are the "Pantry Chef." Create $number delicious recipes using primarily these ingredients: ${ingredients.join(', ')}.
You can include basic pantry staples (oil, salt, pepper, etc.) but focus on the provided items.
$conditionContext

For each recipe, provide:
- "title": Creative name.
- "image_keyword": 2-word visual essence (e.g. "Pasta Primavera")
- "calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium", "cholesterol": Accurate numeric nutritional estimates.
- "ingredients": Full ingredient list.
- "aiReasoning": Why this is a great way to use your pantry items.
- "id": Unique ID starting with "gemini:pantry_".

CRITICAL: Return RAW JSON only as a list under "results".

Response Format:
{
  "results": [
    {
      "id": "gemini:pantry_1",
      "title": "...",
      "image_keyword": "...",
      "calories": 350,
      "protein": 20,
      "carbs": 30,
      "fat": 15,
      "ingredients": ["...", "..."],
      "aiReasoning": "...",
      "source": "FoodGapp",
      "isVerified": true
    },
    ...
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return (data['results'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      print('FoodGapp AI Pantry Chef Error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> categorizeIngredients(List<String> items) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      return null;
    }

    final prompt = '''
Categorize these ingredients into standard grocery aisles: 
Produce, Meat/Seafood, Dairy/Eggs, Bakery, Frozen, Pantry, Household, Snacks, Other.

Ingredients:
${items.join(', ')}

Instructions:
1. Return a single JSON object where keys are the ingredients and values are the aisle names.
2. Be precise but prioritize standard categories.

CRITICAL: Return RAW JSON only.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;

      return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (e) {
      print('FoodGapp AI Categorization Error: $e');
      return null;
    }
  }

  /// Strong sanitization to remove markdown and illegal AI list formatting.
  String? _sanitizeJson(String? input) {
    if (input == null) return null;
    String clean = input;
    // Remove markdown code blocks
    if (clean.contains('```')) {
      clean = clean.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    }
    // Remove illegal leading "=" from array elements (The specific crash culprit)
    clean = clean.replaceAll(RegExp(r'":\s*='), '": '); // Fixes "key": = "val"
    clean = clean.replaceAll(RegExp(r'\[\s*='), '[');   // Fixes [= "val"]
    clean = clean.replaceAll(RegExp(r',\s*='), ', ');  // Fixes [, = "val"]
    
    return clean.trim();
  }
}
