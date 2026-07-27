import 'food_library_item.dart';

class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isVerified;
  final String? source;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isVerified = false,
    this.source,
  });

  factory Ingredient.fromSpoonacular(Map<String, dynamic> json, {bool isVerified = false, String? source}) {
    final nutrition = json['nutrition']?['nutrients'] as List?;
    
    double findNutrient(String name) {
      if (nutrition == null) return 0.0;
      final match = nutrition.firstWhere(
        (n) => (n['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => {'amount': 0.0},
      );
      return (match['amount'] as num).toDouble();
    }

    return Ingredient(
      name: json['originalName'] ?? json['name'] ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      calories: findNutrient('Calories'),
      protein: findNutrient('Protein'),
      carbs: findNutrient('Carbohydrates'),
      fat: findNutrient('Fat'),
      isVerified: isVerified,
      source: source,
    );
  }

  factory Ingredient.fromUsda(Map<String, dynamic> json, double amount) {
    final nutrients = json['foodNutrients'] as List?;
    
    double findNutrientValue(List<int> ids) {
      if (nutrients == null) return 0.0;
      
      // Try to find any match for the list of IDs (prioritize first match)
      for (final id in ids) {
        final match = nutrients.firstWhere(
          (n) => n['nutrientId'] == id || n['nutrient']?['id'] == id,
          orElse: () => null,
        );
        
        if (match != null) {
          final val = (match['amount'] ?? match['value'] ?? 0.0) as num;
          return (val.toDouble() / 100.0) * amount;
        }
      }
      return 0.0;
    }

    final name = json['description'] ?? json['lowercaseDescription'] ?? 'Unknown';
    final brand = json['brandOwner'] ?? json['brandName'];
    final fullName = brand != null ? '$name ($brand)' : name;

    return Ingredient(
      name: fullName,
      amount: amount,
      unit: 'g',
      // Energy IDs: 1008 (standard), 1062 (kcal), 2047, 2048 (Atwater)
      calories: findNutrientValue([1008, 1062, 2047, 2048]),
      protein: findNutrientValue([1003]),
      carbs: findNutrientValue([1005]),
      fat: findNutrientValue([1004]),
      isVerified: true,
      source: 'USDA',
    );
  }

  factory Ingredient.fromLibrary(FoodLibraryItem item, double amount) {
    final ratio = amount / item.servingSize;
    return Ingredient(
      name: item.name,
      amount: amount,
      unit: item.unit.split(' ').first, // e.g. "g" from "g (1 cup)"
      calories: item.calories * ratio,
      protein: item.protein * ratio,
      carbs: item.carbs * ratio,
      fat: item.fat * ratio,
      isVerified: true,
      source: item.source,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'isVerified': isVerified,
        'source': source,
      };

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        unit: map['unit'] as String,
        calories: (map['calories'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        carbs: (map['carbs'] as num).toDouble(),
        fat: (map['fat'] as num).toDouble(),
        isVerified: map['isVerified'] as bool? ?? false,
        source: map['source'] as String?,
      );
}
