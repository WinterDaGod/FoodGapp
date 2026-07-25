import 'dart:convert';

/// A recipe with its nutrition facts, normalised across the two data sources
/// (Spoonacular and TheMealDB) so the rest of the app doesn't care where it
/// came from.
///
/// [apiMealId] is source-prefixed (e.g. `spoonacular:715538`,
/// `themealdb:52772`) so ids from the two sources can never collide as
/// `nutrition_cache` keys.
class Recipe {
  final String apiMealId;
  final String name;
  final String? imageUrl;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? ingredientCount;
  final String? author;
  final bool isVerified;
  final List<String>? ingredients;

  /// Optional reasoning for AI-selected meals.
  final String? aiReasoning;

  /// Where this came from: `spoonacular` or `themealdb`.
  final String source;

  const Recipe({
    required this.apiMealId,
    required this.name,
    required this.source,
    this.imageUrl,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.ingredientCount,
    this.author,
    this.isVerified = false,
    this.ingredients,
    this.aiReasoning,
  });

  /// Robust ingredient count that falls back to the ingredients list length.
  int get displayIngredientCount => ingredientCount ?? ingredients?.length ?? 0;

  /// True when the four macro/energy figures are all present.
  bool get hasNutrition =>
      calories != null && protein != null && carbs != null && fat != null;

  // --- Spoonacular --------------------------------------------------------

  /// Parses one item from Spoonacular `complexSearch` (with
  /// `addRecipeNutrition=true`) or `recipes/{id}/information?includeNutrition`.
  ///
  /// Both shapes carry `nutrition.nutrients: [{name, amount, unit}, ...]`.
  factory Recipe.fromSpoonacular(Map<String, dynamic> json) {
    final nutrients =
        (json['nutrition']?['nutrients'] as List?)?.cast<Map<String, dynamic>>();

    final ingredientsList = (json['extendedIngredients'] as List?)
        ?.map((i) => i['original'] as String)
        .toList();

    double? nutrient(String name) {
      if (nutrients == null) return null;
      final target = name.toLowerCase();
      for (final n in nutrients) {
        final nName = (n['name'] as String?)?.toLowerCase() ?? '';
        if (nName == target) return (n['amount'] as num?)?.toDouble();
        
        // Handle common variations for Carbohydrates
        if (target == 'carbohydrates') {
          if (nName == 'carbs' || 
              nName == 'net carbohydrates' || 
              nName == 'net carbs' || 
              nName == 'total carbohydrates') {
            return (n['amount'] as num?)?.toDouble();
          }
        }
      }
      return null;
    }

    return Recipe(
      apiMealId: 'spoonacular:${json['id']}',
      name: (json['title'] as String?) ?? 'Untitled',
      source: 'spoonacular',
      imageUrl: json['image'] as String?,
      calories: nutrient('Calories'),
      protein: nutrient('Protein'),
      carbs: nutrient('Carbohydrates'),
      fat: nutrient('Fat'),
      ingredientCount: (json['extendedIngredients'] as List?)?.length,
      author: json['sourceName'] as String?,
      isVerified: true,
      ingredients: ingredientsList,
    );
  }

  /// Parses one item from Spoonacular `findByNutrients`, which returns the
  /// macro fields as flat top-level numbers instead of a nutrients list.
  factory Recipe.fromSpoonacularNutrients(Map<String, dynamic> json) => Recipe(
        apiMealId: 'spoonacular:${json['id']}',
        name: (json['title'] as String?) ?? 'Untitled',
        source: 'spoonacular',
        imageUrl: json['image'] as String?,
        calories: (json['calories'] as num?)?.toDouble(),
        protein: _stripGrams(json['protein']),
        carbs: _stripGrams(json['carbs'] ?? json['carbohydrates'] ?? json['netCarbohydrates'] ?? json['netCarbs']),
        fat: _stripGrams(json['fat']),
        isVerified: true,
      );

  // --- TheMealDB ----------------------------------------------------------

  /// Parses one `meals[]` item from TheMealDB. TheMealDB has no nutrition
  /// data, so the macro fields stay null (the app treats it as a name-only
  /// backup result).
  factory Recipe.fromTheMealDb(Map<String, dynamic> json) {
    final List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ing = json['strIngredient$i'] as String?;
      final measure = json['strMeasure$i'] as String?;
      if (ing != null && ing.trim().isNotEmpty) {
        if (measure != null && measure.trim().isNotEmpty) {
          ingredients.add('$measure $ing'.trim());
        } else {
          ingredients.add(ing.trim());
        }
      }
    }

    return Recipe(
      apiMealId: 'themealdb:${json['idMeal']}',
      name: (json['strMeal'] as String?) ?? 'Untitled',
      source: 'themealdb',
      imageUrl: json['strMealThumb'] as String?,
      ingredientCount: ingredients.length,
      ingredients: ingredients,
      isVerified: false,
    );
  }

  // --- nutrition_cache ----------------------------------------------------

  Map<String, Object?> toCacheMap() => {
        'api_meal_id': apiMealId,
        'meal_name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'raw_json': jsonEncode({
          'image_url': imageUrl,
          'source': source,
          'ingredient_count': ingredientCount,
          'author': author,
          'is_verified': isVerified,
          'ingredients': ingredients,
          'ai_reasoning': aiReasoning,
        }),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

  factory Recipe.fromCacheMap(Map<String, Object?> map) {
    final raw = map['raw_json'] as String?;
    final extra = raw == null
        ? const <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    return Recipe(
      apiMealId: map['api_meal_id'] as String,
      name: (map['meal_name'] as String?) ?? 'Untitled',
      source: (extra['source'] as String?) ?? 'cache',
      imageUrl: extra['image_url'] as String?,
      calories: (map['calories'] as num?)?.toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      ingredientCount: extra['ingredient_count'] as int?,
      author: extra['author'] as String?,
      isVerified: extra['is_verified'] as bool? ?? false,
      ingredients: (extra['ingredients'] as List?)?.cast<String>(),
      aiReasoning: extra['ai_reasoning'] as String?,
    );
  }

  /// Spoonacular's `findByNutrients` returns macros as strings like `"12g"`.
  static double? _stripGrams(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    
    // Extract digits and decimal point
    final match = RegExp(r'[\d.]+').firstMatch(value.toString());
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }
}
