import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/api_config.dart';
import '../../models/ingredient.dart';
import '../../models/recipe.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-3.6-flash',
          apiKey: ApiConfig.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  Future<Ingredient?> parseIngredient(String text) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key not set');
    }

    final prompt = '''
You are a clinical dietitian and nutrition expert. 
Your task is to parse a natural language description of food into a structured JSON format.

Input: "$text"

Instructions:
1. Estimate the total amount in grams (g) if not specified.
2. Calculate Calories (kcal), Protein (g), Carbohydrates (g), and Fat (g) based on standard nutritional data.
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
- "isVerified": (bool) Set to true
- "source": (String) Set to "FoodGapp"
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? jsonString = response.text;
      if (jsonString == null) return null;

      // Sanitization: Remove markdown code blocks if present
      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return Ingredient.fromMap(data);
    } catch (e) {
      print('Gemini Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> selectBestMeals({
    required List<Recipe> candidates,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key not set');
    }

    final candidateList = candidates.map((r) => {
      'id': r.apiMealId,
      'title': r.name,
      'calories': r.calories ?? 0,
      'protein': r.protein ?? 0,
      'carbs': r.carbs ?? 0,
      'fat': r.fat ?? 0,
    }).toList();

    final prompt = '''
You are a master dietitian. Your goal is to select the 3 BEST recipes for a user's daily meal plan from a provided list of candidates.

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
2. The SUM of their nutrition should be as close as possible to the Daily Targets.
3. Prioritize variety and user preferences (if any).
4. For each selected recipe, provide a short "aiReasoning" (1 sentence) explaining why it fits this user's day.

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
      
      String? jsonString = response.text;
      if (jsonString == null) return null;

      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      return jsonDecode(jsonString);
    } catch (e) {
      print('Gemini Selection Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateDailyPlanFromScratch({
    required int targetKcal,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    List<String>? diets,
    String? preferences,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key not set');
    }

    final prompt = '''
You are a master dietitian. Your goal is to generate a complete 3-meal daily plan (Breakfast, Lunch, Dinner) from scratch because the primary recipe database is currently offline.

Daily Targets:
- Total Calories: $targetKcal kcal
- Total Protein: ${targetProtein.round()}g
- Total Carbs: ${targetCarbs.round()}g
- Total Fat: ${targetFat.round()}g

User Constraints:
- Diets/Preferences: ${diets?.join(', ') ?? 'Balanced'}
- Extra Requests: "${preferences ?? 'None'}"

Instructions:
1. Create 3 unique, healthy recipes that together hit the Daily Targets as closely as possible.
2. For each recipe, provide:
   - "title": Clear descriptive name
   - "calories", "protein", "carbs", "fat": Accurate numeric estimates
   - "ingredients": A list of strings for the ingredients
   - "aiReasoning": A short sentence explaining why this meal was created for this plan.
3. Mark these as "source": "FoodGapp_Fallback" and "isVerified": false.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "meals": [
    {
      "id": "gemini:b1",
      "title": "...",
      "calories": 450,
      "protein": 25,
      "carbs": 40,
      "fat": 12,
      "ingredients": ["...", "..."],
      "aiReasoning": "...",
      "source": "FoodGapp_Fallback",
      "isVerified": false
    },
    ... (2 more meals)
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? jsonString = response.text;
      if (jsonString == null) return null;

      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      return jsonDecode(jsonString);
    } catch (e) {
      print('Gemini Fallback Generation Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> searchRecipes({
    required String query,
    String? diet,
    int number = 10,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key not set');
    }

    final prompt = '''
You are a world-class chef and nutritionist. Generate a list of $number recipe ideas based on the query: "$query".
Dietary constraint: ${diet ?? 'None'}.

For each recipe, provide:
- "title": A catchy, professional recipe name.
- "calories", "protein", "carbs", "fat": Accurate numeric nutritional estimates.
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
      String? jsonString = response.text;
      if (jsonString == null) return null;

      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return (data['results'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gemini Recipe Search Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> chefFromPantry({
    required List<String> ingredients,
    int number = 10,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key not set');
    }

    final prompt = '''
You are the "Pantry Chef." Create $number delicious recipes using primarily these ingredients: ${ingredients.join(', ')}.
You can include basic pantry staples (oil, salt, pepper, etc.) but focus on the provided items.

For each recipe, provide:
- "title": Creative name.
- "calories", "protein", "carbs", "fat": Accurate numeric nutritional estimates.
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
      String? jsonString = response.text;
      if (jsonString == null) return null;

      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return (data['results'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gemini Pantry Chef Error: $e');
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

Example:
Input: ["Milk", "Apple", "Chicken"]
Output: {"Milk": "Dairy/Eggs", "Apple": "Produce", "Chicken": "Meat/Seafood"}

CRITICAL: Return RAW JSON only.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String? jsonString = response.text;
      if (jsonString == null) return null;

      if (jsonString.contains('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'```(?:json)?'), '').trim();
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Gemini Categorization Error: $e');
      return null;
    }
  }
}
