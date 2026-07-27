class FoodLibraryItem {
  final int? id;
  final String name;
  final String category;
  final double servingSize;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String source; // PhilFCT, USDA, Branded

  FoodLibraryItem({
    this.id,
    required this.name,
    required this.category,
    required this.servingSize,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'serving_size': servingSize,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
    };
  }

  factory FoodLibraryItem.fromMap(Map<String, dynamic> map) {
    return FoodLibraryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      servingSize: (map['serving_size'] as num).toDouble(),
      unit: map['unit'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      source: map['source'] as String,
    );
  }

  factory FoodLibraryItem.fromJson(Map<String, dynamic> json) {
    return FoodLibraryItem(
      name: json['name'] as String,
      category: json['category'] as String,
      servingSize: (json['servingSize'] as num).toDouble(),
      unit: json['unit'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      source: json['source'] as String,
    );
  }
}
