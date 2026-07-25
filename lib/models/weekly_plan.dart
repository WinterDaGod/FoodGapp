import 'recipe.dart';

class WeeklyMealPlan {
  final Map<String, List<Recipe>> days;

  WeeklyMealPlan({required this.days});

  /// Factory to handle the raw nested structure from Spoonacular's weekly response
  factory WeeklyMealPlan.fromSpoonacular(Map<String, dynamic> json, Map<String, Recipe> fullRecipes) {
    final Map<String, List<Recipe>> dayMap = {};
    final week = json['week'] as Map<String, dynamic>? ?? {};

    week.forEach((dayName, dayData) {
      final meals = (dayData['meals'] as List?) ?? [];
      final List<Recipe> recipesForDay = [];

      for (var m in meals) {
        final id = m['id'].toString();
        final full = fullRecipes['spoonacular:$id'];
        if (full != null) {
          recipesForDay.add(full);
        }
      }
      dayMap[dayName] = recipesForDay;
    });

    return WeeklyMealPlan(days: dayMap);
  }

  List<String> get dayNames => ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
}
