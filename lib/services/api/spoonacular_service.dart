import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/recipe.dart';
import 'api_exceptions.dart';

/// Primary recipe/nutrition source: the Spoonacular REST API.
///
/// Every method throws an [ApiException] subclass on failure so the caller
/// ([RecipeRepository]) can decide whether to fall back to the backup source.
/// The HTTP client is injectable for testing.
class SpoonacularService {
  SpoonacularService({
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? ApiConfig.spoonacularApiKey;

  static const _host = 'api.spoonacular.com';

  final http.Client _client;
  final String _apiKey;
  final Duration timeout;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Searches recipes by free text, with nutrition and full info (ingredients) included.
  Future<List<Recipe>> searchByName(String query, {String? diet, int number = 10}) async {
    final params = {
      'query': query,
      'number': '$number',
      'addRecipeNutrition': 'true',
      'addRecipeInformation': 'true', // Includes extendedIngredients
      'fillIngredients': 'true',
    };
    if (diet != null) params['diet'] = diet;

    final json = await _get('/recipes/complexSearch', params);
    final results = (json['results'] as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromSpoonacular)
        .toList();
  }

  /// Searches recipes that fit a nutrition window (calories / macros).
  Future<List<Recipe>> searchByNutrition({
    int? minCalories,
    int? maxCalories,
    int? minProtein,
    int? maxProtein,
    int? minCarbs,
    int? maxCarbs,
    int? minFat,
    int? maxFat,
    int number = 10,
  }) async {
    final params = <String, String>{'number': '$number'};
    void add(String key, int? value) {
      if (value != null) params[key] = '$value';
    }

    add('minCalories', minCalories);
    add('maxCalories', maxCalories);
    add('minProtein', minProtein);
    add('maxProtein', maxProtein);
    add('minCarbs', minCarbs);
    add('maxCarbs', maxCarbs);
    add('minFat', minFat);
    add('maxFat', maxFat);

    // findByNutrients returns a bare JSON array, not an object.
    final json = await _getRaw('/recipes/findByNutrients', params);
    final results = (json as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromSpoonacularNutrients)
        .toList();
  }

  /// Finds recipes by ingredients you already have.
  Future<List<Recipe>> findByIngredients(List<String> ingredients, {int number = 10}) async {
    final params = {
      'ingredients': ingredients.join(','),
      'number': '$number',
      'ranking': '1', // Maximize used ingredients
      'ignorePantry': 'true',
    };

    // findByIngredients returns a bare JSON array
    final json = await _getRaw('/recipes/findByIngredients', params);
    final results = (json as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromSpoonacular) // Same structure for basic info
        .toList();
  }

  /// Fetches full nutrition for a single recipe by its numeric Spoonacular id.
  Future<Recipe> getInformation(String id) async {
    final json = await _get('/recipes/$id/information', {
      'includeNutrition': 'true',
    });
    return Recipe.fromSpoonacular(json);
  }

  /// Fetches full nutrition for multiple recipes in one call.
  Future<List<Recipe>> getInformationBulk(List<String> ids) async {
    if (ids.isEmpty) return [];
    final json = await _getRaw('/recipes/informationBulk', {
      'ids': ids.join(','),
      'includeNutrition': 'true',
    });
    final results = (json as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromSpoonacular)
        .toList();
  }

  /// Parses an ingredient string (e.g. "100g chicken breast") into nutrition data.
  Future<Map<String, dynamic>> parseIngredients(String text) async {
    final uri = Uri.https(_host, '/recipes/parseIngredients', {'apiKey': _apiKey});
    
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'ingredientList': text,
        'servings': '1',
        'includeNutrition': 'true',
      },
    ).timeout(timeout);

    if (response.statusCode == 402) {
      throw const ApiQuotaExceededException('Spoonacular daily quota reached.');
    }
    if (response.statusCode != 200) {
      throw ApiUnavailableException('Spoonacular returned HTTP ${response.statusCode}.');
    }

    final List decoded = jsonDecode(response.body);
    if (decoded.isEmpty) {
      throw const ApiUnavailableException('Could not parse ingredient.');
    }
    return decoded.first as Map<String, dynamic>;
  }

  /// Generates a meal plan (day or week) using the Spoonacular `mealplanner/generate` endpoint.
  Future<Map<String, dynamic>> generateMealPlan({int? targetCalories, String? diet, String timeFrame = 'day'}) async {
    final params = {
      'timeFrame': timeFrame,
    };
    if (targetCalories != null) params['targetCalories'] = '$targetCalories';
    if (diet != null && diet.toLowerCase() != 'balanced') params['diet'] = diet.toLowerCase();

    return await _get('/mealplanner/generate', params);
  }

  /// GETs an endpoint expected to return a JSON object.
  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final decoded = await _getRaw(path, params);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiUnavailableException('Unexpected Spoonacular response.');
    }
    return decoded;
  }

  /// GETs an endpoint and returns decoded JSON (object or array), translating
  /// every failure mode into a typed [ApiException].
  Future<dynamic> _getRaw(String path, Map<String, String> params) async {
    if (!isConfigured) {
      throw const ApiUnavailableException('Spoonacular API key is not set.');
    }

    final uri = Uri.https(_host, path, {...params, 'apiKey': _apiKey});
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiUnavailableException('Spoonacular timed out.');
    } catch (e) {
      throw ApiUnavailableException('Spoonacular request failed: $e');
    }

    if (response.statusCode == 402) {
      throw const ApiQuotaExceededException('Spoonacular daily quota reached.');
    }
    if (response.statusCode != 200) {
      throw ApiUnavailableException(
        'Spoonacular returned HTTP ${response.statusCode}.',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const ApiUnavailableException('Spoonacular returned invalid JSON.');
    }
  }

  void dispose() => _client.close();
}
