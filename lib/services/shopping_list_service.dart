import '../models/recipe.dart';
import '../models/shopping_item.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'api/foodgapp_ai_service.dart';
import 'ph_price_watch_service.dart';

class ShoppingListService {
  ShoppingListService._internal();
  static final ShoppingListService instance = ShoppingListService._internal();

  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  final _ai = FoodGappAiService();

  /// Efficiently extracts and adds all ingredients from multiple recipes in a 
  /// single batch operation using database transactions.
  Future<void> addIngredientsFromRecipesBulk(List<Recipe> recipes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || recipes.isEmpty) return;

    // 1. Extract and unify all ingredients
    final List<String> allIngredientNames = [];
    final List<Map<String, dynamic>> rawPairs = []; // {ing, recipeName}

    for (var recipe in recipes) {
      if (recipe.ingredients == null) continue;
      for (var ing in recipe.ingredients!) {
        final name = ing.trim();
        if (name.isNotEmpty) {
          allIngredientNames.add(name);
          rawPairs.add({'name': name, 'recipe': recipe.name});
        }
      }
    }

    if (rawPairs.isEmpty) return;

    // 2. Batch Categorization & Pricing
    final uniqueNames = allIngredientNames.toSet().toList();
    final categoryMap = await _categorizeItems(uniqueNames);
    
    final Map<String, double?> priceMap = {};
    for (var name in uniqueNames) {
      priceMap[name] = await PhPriceWatchService.instance.getEstimatedPrice(name);
    }

    // 3. Pre-merge in memory to reduce database operations
    // Key: "Name|RecipeName"
    final Map<String, ShoppingItem> merged = {};

    for (var pair in rawPairs) {
      final name = pair['name'];
      final recipeName = pair['recipe'];
      final key = "$name|$recipeName";

      if (merged.containsKey(key)) {
        final existing = merged[key]!;
        merged[key] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        merged[key] = ShoppingItem(
          userId: userId,
          name: name,
          recipeName: recipeName,
          category: categoryMap[name] ?? 'Pantry',
          quantity: 1,
          pricePhp: priceMap[name],
        );
      }
    }

    // 4. Save to database in a single high-speed transaction
    await _db.saveShoppingItemsBulk(userId, merged.values.toList());
  }

  /// Extracts all ingredients from a recipe and adds them to the persistent 
  /// shopping list, intelligently grouped by store aisles.
  Future<void> addIngredientsFromRecipe(Recipe recipe) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (recipe.ingredients == null || recipe.ingredients!.isEmpty) return;

    // 1. Prepare ingredients for categorization
    final newIngredients = recipe.ingredients!
        .where((ing) => ing.trim().isNotEmpty)
        .toList();

    if (newIngredients.isEmpty) return;

    // 2. Efficiently categorize in bulk (handles AI and Caching)
    final categoryMap = await _categorizeItems(newIngredients);
    final Map<String, double?> priceMap = {};
    for (var name in newIngredients) {
      priceMap[name] = await PhPriceWatchService.instance.getEstimatedPrice(name);
    }

    // 3. Save to database with intelligent merging (Quantity Support)
    for (var ing in newIngredients) {
      final name = ing.trim();
      // Check if this exact ingredient for this recipe already exists
      final existing = await _db.findShoppingItem(userId, name, recipe.name);
      
      if (existing != null) {
        // Increment quantity for multiple servings or repeated clicks
        await _db.updateShoppingItem(existing.copyWith(quantity: existing.quantity + 1));
      } else {
        // Insert as a new entry with the AI-determined category
        await _db.insertShoppingItem(ShoppingItem(
          userId: userId,
          name: name,
          recipeName: recipe.name,
          category: categoryMap[name] ?? 'Pantry',
          quantity: 1,
          pricePhp: priceMap[name],
        ));
      }
    }
  }

  /// Adds a manual ingredient with smart categorization and merging.
  Future<void> addManualItem(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = await _db.findShoppingItem(userId, trimmed, null);
    if (existing != null) {
      await _db.updateShoppingItem(existing.copyWith(quantity: existing.quantity + 1));
      return;
    }

    final categoryMap = await _categorizeItems([trimmed]);
    final price = await PhPriceWatchService.instance.getEstimatedPrice(trimmed);
    
    await _db.insertShoppingItem(ShoppingItem(
      userId: userId,
      name: trimmed,
      recipeName: null,
      category: categoryMap[trimmed] ?? 'Other',
      quantity: 1,
      pricePhp: price,
    ));
  }

  /// Hybrid categorization: Local Cache -> AI Batch -> Local Default
  Future<Map<String, String>> _categorizeItems(List<String> items) async {
    final Map<String, String> results = {};
    final List<String> missingFromCache = [];

    // 1. Check Local Cache (Fast, 0 Cost)
    for (var item in items) {
      final cached = await _db.getCachedAisle(item);
      if (cached != null) {
        results[item] = cached;
      } else {
        missingFromCache.add(item);
      }
    }

    if (missingFromCache.isEmpty) return results;

    // 2. Batch AI Request (Smart, Low Frequency)
    try {
      final aiMap = await _ai.categorizeIngredients(missingFromCache);
      if (aiMap != null) {
        for (var entry in aiMap.entries) {
          results[entry.key] = entry.value;
          // Save to cache for next time
          await _db.putCachedAisle(entry.key, entry.value);
        }
      }
    } catch (_) {
      // Fallback: If AI is busy/offline, use a basic local list or 'Other'
    }

    return results;
  }
}
