class ShoppingItem {
  final int? id;
  final String userId;
  final String name;
  final String? recipeName; // Used for context (e.g. "Healthy Quinoa Salad")
  final String? category;   // Aisle name (e.g. "Produce")
  final int quantity;       // Number of servings or items
  final bool isChecked;

  const ShoppingItem({
    this.id,
    required this.userId,
    required this.name,
    this.recipeName,
    this.category,
    this.quantity = 1,
    this.isChecked = false,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'recipe_name': recipeName,
        'category': category,
        'quantity': quantity,
        'is_checked': isChecked ? 1 : 0,
      };

  factory ShoppingItem.fromMap(Map<String, Object?> map) => ShoppingItem(
        id: map['id'] as int?,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        recipeName: map['recipe_name'] as String?,
        category: map['category'] as String?,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        isChecked: (map['is_checked'] as int?) == 1,
      );

  ShoppingItem copyWith({
    int? id,
    String? userId,
    String? name,
    String? recipeName,
    String? category,
    int? quantity,
    bool? isChecked,
  }) =>
      ShoppingItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        recipeName: recipeName ?? this.recipeName,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        isChecked: isChecked ?? this.isChecked,
      );
}
