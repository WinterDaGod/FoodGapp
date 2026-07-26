import '../models/recipe.dart';
import '../models/shopping_item.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'api/gemini_service.dart';

class ShoppingListService {
  ShoppingListService._internal();
  static final ShoppingListService instance = ShoppingListService._internal();

  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  final _gemini = GeminiService();

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
    
    await _db.insertShoppingItem(ShoppingItem(
      userId: userId,
      name: trimmed,
      recipeName: null,
      category: categoryMap[trimmed] ?? 'Other',
      quantity: 1,
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
      final aiMap = await _gemini.categorizeIngredients(missingFromCache);
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
