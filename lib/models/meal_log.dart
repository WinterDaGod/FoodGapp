import 'dart:convert';
import 'ingredient.dart';

/// A single logged food item, stored in the `meal_log` table.
///
/// Linked to a [UserProfile] via [userId] (the Firebase user id).
class MealLog {
  final int? id;
  final String userId;

  /// Date the meal was eaten, formatted as `yyyy-MM-dd`.
  final String mealDate;

  /// One of: `breakfast`, `lunch`, `dinner`, `snack`.
  final String mealType;

  final String foodName;
  final String? servingSize;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  /// Time the meal was logged, e.g. "12:04 AM".
  final String? mealTime;

  /// Optional image associated with the meal.
  final String? imageUrl;

  /// Whether this meal is pinned for quick access.
  final bool isPinned;

  /// Optional id of the source recipe from the nutrition API (Spoonacular/TheMealDB).
  final String? apiMealId;

  // History and editing fields
  final List<Ingredient>? ingredients;
  final double? baseCalories;
  final double? baseProtein;
  final double? baseCarbs;
  final double? baseFat;

  const MealLog({
    this.id,
    required this.userId,
    required this.mealDate,
    required this.mealType,
    required this.foodName,
    this.servingSize,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.mealTime,
    this.imageUrl,
    this.isPinned = false,
    this.apiMealId,
    this.ingredients,
    this.baseCalories,
    this.baseProtein,
    this.baseCarbs,
    this.baseFat,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'meal_date': mealDate,
        'meal_type': mealType,
        'food_name': foodName,
        'serving_size': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_time': mealTime,
        'image_url': imageUrl,
        'is_pinned': isPinned ? 1 : 0,
        'api_meal_id': apiMealId,
        'ingredients_json': ingredients != null ? jsonEncode(ingredients!.map((i) => i.toMap()).toList()) : null,
        'base_calories': baseCalories,
        'base_protein': baseProtein,
        'base_carbs': baseCarbs,
        'base_fat': baseFat,
  };

  /// Returns a high-fidelity image URL based on the meal name if [imageUrl] is missing.
  String? get dynamicImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;

    // Fallback logic consistent with Recipe model
    String query = foodName;
    final words = query.split(' ');
    if (words.length > 3) {
      query = words.take(3).join(' ');
    }
    query = query.replaceAll(' ', ',');
    return 'https://loremflickr.com/480/360/food,$query';
  }

  factory MealLog.fromMap(Map<String, Object?> map) {
    final ingJson = map['ingredients_json'] as String?;
    List<Ingredient>? ings;
    if (ingJson != null) {
      final List decoded = jsonDecode(ingJson);
      ings = decoded.map((i) => Ingredient.fromMap(i as Map<String, dynamic>)).toList();
    }

    return MealLog(
      id: (map['id'] as num?)?.toInt(),
      userId: map['user_id'] as String,
      mealDate: map['meal_date'] as String,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      servingSize: map['serving_size'] as String?,
      calories: (map['calories'] as num?)?.toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      mealTime: map['meal_time'] as String?,
      imageUrl: map['image_url'] as String?,
      isPinned: (map['is_pinned'] as int?) == 1,
      apiMealId: map['api_meal_id'] as String?,
      ingredients: ings,
      baseCalories: (map['base_calories'] as num?)?.toDouble(),
      baseProtein: (map['base_protein'] as num?)?.toDouble(),
      baseCarbs: (map['base_carbs'] as num?)?.toDouble(),
      baseFat: (map['base_fat'] as num?)?.toDouble(),
    );
  }
}
