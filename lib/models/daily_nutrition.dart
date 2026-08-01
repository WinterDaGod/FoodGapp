import 'meal_log.dart';

/// Aggregated nutrition totals for a single day, summed from that day's
/// [MealLog] entries. Meals with missing macro values contribute 0 for the
/// missing field, so partial logging still produces a usable total.
class DailyNutrition {
  final String mealDate;
  final int mealCount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double cholesterol;

  const DailyNutrition({
    required this.mealDate,
    required this.mealCount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
    this.cholesterol = 0.0,
  });

  bool get isEmpty => mealCount == 0;

  /// Sums a day's [logs] into a single total. Assumes all logs are for the
  /// same [mealDate]; when [logs] is empty the totals are all zero.
  factory DailyNutrition.fromLogs(String mealDate, List<MealLog> logs) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var sugar = 0.0;
    var sodium = 0.0;
    var cholesterol = 0.0;
    for (final log in logs) {
      calories += log.calories ?? 0;
      protein += log.protein ?? 0;
      carbs += log.carbs ?? 0;
      fat += log.fat ?? 0;
      fiber += log.fiber ?? 0;
      sugar += log.sugar ?? 0;
      sodium += log.sodium ?? 0;
      cholesterol += log.cholesterol ?? 0;
    }
    return DailyNutrition(
      mealDate: mealDate,
      mealCount: logs.length,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      cholesterol: cholesterol,
    );
  }
}
