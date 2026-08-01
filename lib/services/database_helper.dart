import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/daily_nutrition.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../models/saved_meal.dart';
import '../models/user_profile.dart';
import '../models/fasting_session.dart';
import '../models/weight_log.dart';
import '../models/shopping_item.dart';
import '../models/food_library_item.dart';
import 'gamification_service.dart';

/// Single point of access to the on-device SQLite database.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  @visibleForTesting
  DatabaseHelper.forTesting(Database database) : _database = database;

  static const _databaseName = 'foodgapp_v5.db';
  static const _databaseVersion = 25;

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final databasesDir = await getDatabasesPath();
    final path = p.join(databasesDir, _databaseName);

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      debugPrint("Creating new high-fidelity database copy (v5)...");
      try {
        await Directory(p.dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(p.join("assets", "data", "food_library_titan.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint("Asset copy failed: $e. Falling back to local init.");
      }
    }

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

    // CRITICAL: Self-Healing Logic - Ensure all tables exist regardless of source
    await _ensureAllTablesExist(db);

    // DEBUG: Verify library count
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM food_library');
    final count = countRes.first['count'];
    debugPrint("--------------------------------------------------");
    debugPrint("🚀 TITAN ENGINE INITIALIZED: $count clinical items loaded.");
    debugPrint("--------------------------------------------------");
    
    return db;
  }

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Self-Healing Engine: Restores any missing critical tables on startup.
  static Future<void> _ensureAllTablesExist(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((row) => row['name'] as String).toSet();

    final schema = {
      'user_profile': '''
        CREATE TABLE IF NOT EXISTS user_profile (
          user_id TEXT PRIMARY KEY,
          name TEXT,
          email TEXT,
          contact_number TEXT,
          age INTEGER,
          gender TEXT,
          height_cm REAL,
          weight_kg REAL,
          target_weight_kg REAL,
          activity_level TEXT,
          dietary_preferences TEXT,
          health_goal TEXT,
          goal_pace TEXT,
          custom_calories REAL,
          custom_protein REAL,
          custom_carbs REAL,
          custom_fat REAL,
          auto_adjust INTEGER DEFAULT 1,
          birthday TEXT,
          unit_system TEXT DEFAULT 'Metric',
          theme_mode TEXT DEFAULT 'System',
          show_surplus INTEGER DEFAULT 1,
          macro_preset TEXT DEFAULT 'Default',
          meal_logging_style TEXT DEFAULT 'Default',
          meal_log_sounds_enabled INTEGER DEFAULT 1,
          day_reset_time TEXT DEFAULT '00:00',
          week_start_day TEXT DEFAULT 'Monday',
          timezone TEXT DEFAULT 'Manila',
          custom_macro_protein REAL DEFAULT 33.3,
          custom_macro_carbs REAL DEFAULT 33.3,
          custom_macro_fat REAL DEFAULT 33.4,
          created_at TEXT
        )''',
      'meal_log': '''
        CREATE TABLE IF NOT EXISTS meal_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          meal_date TEXT NOT NULL,
          meal_type TEXT NOT NULL,
          food_name TEXT NOT NULL,
          serving_size TEXT,
          calories REAL,
          protein REAL,
          carbs REAL,
          fat REAL,
          meal_time TEXT,
          image_url TEXT,
          is_pinned INTEGER DEFAULT 0,
          api_meal_id TEXT,
          ingredients_json TEXT,
          base_calories REAL,
          base_protein REAL,
          base_carbs REAL,
          base_fat REAL,
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )''',
      'shopping_list': '''
        CREATE TABLE IF NOT EXISTS shopping_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          recipe_name TEXT,
          category TEXT,
          quantity INTEGER DEFAULT 1,
          is_checked INTEGER DEFAULT 0,
          price_php REAL,
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )''',
      'water_log': '''
        CREATE TABLE IF NOT EXISTS water_log (
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          amount_ml INTEGER NOT NULL,
          PRIMARY KEY (user_id, date),
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )''',
      'saved_meals': '''
        CREATE TABLE IF NOT EXISTS saved_meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          api_meal_id TEXT,
          meal_name TEXT,
          image_url TEXT,
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )''',
      'nutrition_cache': '''
        CREATE TABLE IF NOT EXISTS nutrition_cache (
          api_meal_id TEXT PRIMARY KEY,
          meal_name TEXT,
          calories REAL,
          protein REAL,
          carbs REAL,
          fat REAL,
          estimated_total_php REAL,
          raw_json TEXT,
          cached_at INTEGER
        )''',
      'aisle_cache': '''
        CREATE TABLE IF NOT EXISTS aisle_cache (
          ingredient_name TEXT PRIMARY KEY,
          category TEXT NOT NULL
        )''',
      'food_library': '''
        CREATE TABLE IF NOT EXISTS food_library (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          serving_size REAL NOT NULL,
          unit TEXT NOT NULL,
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          source TEXT NOT NULL
        )''',
      'price_cache': '''
        CREATE TABLE IF NOT EXISTS price_cache (
          ingredient_name TEXT PRIMARY KEY,
          price_php REAL NOT NULL,
          cached_at INTEGER NOT NULL
        )''',
      'market_prices': '''
        CREATE TABLE IF NOT EXISTS market_prices (
          name TEXT PRIMARY KEY,
          price REAL NOT NULL,
          unit TEXT NOT NULL,
          category TEXT NOT NULL
        )''',
      'user_streaks': '''
        CREATE TABLE IF NOT EXISTS user_streaks (
          user_id TEXT PRIMARY KEY,
          current_streak INTEGER DEFAULT 0,
          last_log_date TEXT,
          best_streak INTEGER DEFAULT 0
        )''',
    };

    for (var entry in schema.entries) {
      if (!tableNames.contains(entry.key)) {
        debugPrint("Self-Healing Engine: Restoring table: ${entry.key}");
        await db.execute(entry.value);

        // Special initialization for market_prices from assets
        if (entry.key == 'market_prices') {
          await _initMarketPrices(db);
        }
      }
    }

    // Add indexes if missing
    await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_meals_user ON saved_meals (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_log_user_date ON meal_log (user_id, meal_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_nutrition_cache_id ON nutrition_cache (api_meal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_food_library_name ON food_library (name)');

    // CRITICAL: Column-Level Self-Healing (v1.1.8 Pricing Update)
    await _ensureColumnExists(db, 'nutrition_cache', 'estimated_total_php', 'REAL');
    await _ensureColumnExists(db, 'shopping_list', 'price_php', 'REAL');

    // Special initialization for market_prices from assets
    // We force refresh if the count is low (indicating old basic dataset)
    final marketCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM market_prices');
    final marketCount = (marketCountRes.first['count'] as num?)?.toInt() ?? 0;
    if (marketCount < 50) {
      debugPrint("Self-Healing Engine: Refreshing market prices with advanced dataset...");
      await db.execute('DELETE FROM market_prices');
      await _initMarketPrices(db);
    }
  }

  static Future<void> _initMarketPrices(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/ph_market_prices.json');
      final List<dynamic> data = jsonDecode(jsonString);
      
      final batch = db.batch();
      for (var item in data) {
        batch.insert('market_prices', {
          'name': item['name'],
          'price': item['price'],
          'unit': item['unit'],
          'category': item['category'],
        });
      }
      await batch.commit(noResult: true);
      debugPrint("Self-Healing Engine: Loaded ${data.length} market prices from assets.");
    } catch (e) {
      debugPrint("Self-Healing Engine Error (Market Prices): $e");
    }
  }

  Future<List<Map<String, dynamic>>> getMarketPrices() async {
    final db = await database;
    return db.query('market_prices');
  }

  /// Verifies if a specific column exists in a table and adds it if missing.
  static Future<void> _ensureColumnExists(Database db, String table, String column, String type) async {
    try {
      final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info($table)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      if (!columnNames.contains(column)) {
        debugPrint("Self-Healing Engine: Repairing schema - Adding '$column' to $table");
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      }
    } catch (e) {
      debugPrint("Self-Healing Engine Error (Column Update): $e");
    }
  }

  static Future<void> onCreate(Database db, int version) async {
    await _ensureAllTablesExist(db);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic is now dynamically handled by _ensureAllTablesExist
    await _ensureAllTablesExist(db);
  }

  Future<void> clearAllMealLogs() async {
    final db = await database;
    await db.delete('meal_log');
  }

  // --- fasting_log --------------------------------------------------------

  Future<int> insertFastingSession(FastingSession session) async {
    final db = await database;
    return db.insert('fasting_log', session.toMap());
  }

  Future<FastingSession?> getActiveFastingSession(String userId) async {
    final db = await database;
    final rows = await db.query(
      'fasting_log',
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FastingSession.fromMap(rows.first);
  }

  Future<void> endActiveFastingSession(String userId) async {
    final db = await database;
    await db.update(
      'fasting_log',
      {
        'is_completed': 1,
        'end_time': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [userId],
    );
  }

  Future<List<FastingSession>> getFastingHistory(String userId) async {
    final db = await database;
    final rows = await db.query(
      'fasting_log',
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
    );
    return rows.map(FastingSession.fromMap).toList();
  }

  Future<void> deleteFastingSession(int id) async {
    final db = await database;
    await db.delete(
      'fasting_log',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    final db = await database;
    final map = profile.toMap();
    
    final count = await db.update(
      'user_profile',
      map,
      where: 'user_id = ?',
      whereArgs: [profile.userId],
    );

    if (count == 0) {
      await db.insert('user_profile', map);
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final rows = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  // --- meal_log -----------------------------------------------------------

  Future<int> insertMealLog(MealLog log) async {
    final db = await database;
    final id = await db.insert('meal_log', log.toMap());
    
    // Update streak on every new meal log
    try {
      await GamificationService.instance.updateStreak();
    } catch (e) {
      debugPrint("Gamification Error (Streak Update): $e");
    }
    
    return id;
  }

  Future<int> upsertMealLog(MealLog log) async {
    final db = await database;
    return db.insert(
      'meal_log',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MealLog>> getMealLogsForDate(String userId, String mealDate) async {
    final db = await database;
    final rows = await db.query(
      'meal_log',
      where: 'user_id = ? AND meal_date = ?',
      whereArgs: [userId, mealDate],
      orderBy: 'id ASC',
    );
    return rows.map(MealLog.fromMap).toList();
  }

  Future<List<MealLog>> getRecentMeals(String userId, {String? query}) async {
    final db = await database;
    String? where;
    List<Object?>? whereArgs;
    
    if (query != null && query.isNotEmpty) {
      where = 'user_id = ? AND food_name LIKE ?';
      whereArgs = [userId, '%$query%'];
    } else {
      where = 'user_id = ?';
      whereArgs = [userId];
    }

    final rows = await db.query(
      'meal_log',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_pinned DESC, meal_date DESC, id DESC',
    );
    return rows.map(MealLog.fromMap).toList();
  }

  Future<void> toggleMealPin(int logId, bool pinned) async {
    final db = await database;
    await db.update(
      'meal_log',
      {'is_pinned': pinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<void> deleteMealLog(int logId) async {
    final db = await database;
    await db.delete(
      'meal_log',
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<DailyNutrition> getDailyNutrition(String userId, String mealDate) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*)            AS meal_count,
        COALESCE(SUM(calories), 0) AS calories,
        COALESCE(SUM(protein), 0)  AS protein,
        COALESCE(SUM(carbs), 0)    AS carbs,
        COALESCE(SUM(fat), 0)      AS fat
      FROM meal_log
      WHERE user_id = ? AND meal_date = ?
      ''',
      [userId, mealDate],
    );
    final row = rows.first;
    return DailyNutrition(
      mealDate: mealDate,
      mealCount: (row['meal_count'] as num?)?.toInt() ?? 0,
      calories: (row['calories'] as num?)?.toDouble() ?? 0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
      fat: (row['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<Map<String, double>> getCalorieHistoryForRange(String userId, String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT meal_date, SUM(calories) as total_calories
      FROM meal_log
      WHERE user_id = ? AND meal_date BETWEEN ? AND ?
      GROUP BY meal_date
      ''',
      [userId, startDate, endDate],
    );

    return {
      for (var row in results)
        row['meal_date'] as String: (row['total_calories'] as num?)?.toDouble() ?? 0.0
    };
  }

  Future<List<DailyNutrition>> getNutritionHistory(String userId, int days) async {
    final List<DailyNutrition> history = [];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final nutrition = await getDailyNutrition(userId, dateStr);
      history.add(nutrition);
    }
    return history;
  }

  // --- weight_log ---------------------------------------------------------

  Future<int> insertWeightLog(WeightLog log) async {
    final db = await database;
    await db.update(
      'user_profile',
      {'weight_kg': log.weightKg},
      where: 'user_id = ?',
      whereArgs: [log.userId],
    );
    return db.insert('weight_log', log.toMap());
  }

  Future<List<WeightLog>> getWeightHistory(String userId, int days) async {
    final db = await database;
    final rows = await db.query(
      'weight_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: days,
    );
    return rows.map(WeightLog.fromMap).toList().reversed.toList();
  }

  // --- saved_meals --------------------------------------------------------

  Future<int> insertSavedMeal(SavedMeal meal) async {
    final db = await database;
    return db.insert(
      'saved_meals',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> isSaved(String userId, String apiMealId) async {
    final db = await database;
    final rows = await db.query(
      'saved_meals',
      where: 'user_id = ? AND api_meal_id = ?',
      whereArgs: [userId, apiMealId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> deleteSavedMeal(String userId, String apiMealId) async {
    final db = await database;
    await db.delete(
      'saved_meals',
      where: 'user_id = ? AND api_meal_id = ?',
      whereArgs: [userId, apiMealId],
    );
  }

  Future<List<SavedMeal>> getSavedMeals(String userId) async {
    final db = await database;
    final rows = await db.query(
      'saved_meals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(SavedMeal.fromMap).toList();
  }

  // --- nutrition_cache ----------------------------------------------------

  Future<Recipe?> getCachedRecipe(String apiMealId, {Duration? maxAge}) async {
    final db = await database;
    final rows = await db.query(
      'nutrition_cache',
      where: 'api_meal_id = ?',
      whereArgs: [apiMealId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    if (maxAge != null) {
      final cachedAt = (row['cached_at'] as num?)?.toInt() ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age > maxAge.inMilliseconds) return null;
    }
    return Recipe.fromCacheMap(row);
  }

  Future<Map<String, Recipe>> getCachedRecipesBulk(List<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await database;
    
    final Map<String, Recipe> results = {};
    
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'nutrition_cache',
      where: 'api_meal_id IN ($placeholders)',
      whereArgs: ids,
    );

    for (final row in rows) {
      final recipe = Recipe.fromCacheMap(row);
      results[recipe.apiMealId] = recipe;
    }
    return results;
  }

  Future<void> cacheRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert(
      'nutrition_cache',
      recipe.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recipe>> getRandomCachedRecipes({int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      'nutrition_cache',
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return rows.map(Recipe.fromCacheMap).toList();
  }

  // --- active_meal_plan ---------------------------------------------------

  Future<void> saveActiveMealPlan(String planType, String dataJson) async {
    final db = await database;
    final id = planType == 'day' ? 1 : 2;
    await db.insert(
      'active_meal_plan',
      {'id': id, 'plan_type': planType, 'data_json': dataJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getActiveMealPlan(String planType) async {
    final db = await database;
    final id = planType == 'day' ? 1 : 2;
    final rows = await db.query(
      'active_meal_plan',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['data_json'] as String?;
  }

  // --- water_log ----------------------------------------------------------

  Future<int> getWaterIntake(String userId, String date) async {
    final db = await database;
    final rows = await db.query(
      'water_log',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['amount_ml'] as num).toInt();
  }

  Future<void> updateWaterIntake(String userId, String date, int amountMl) async {
    final db = await database;
    await db.insert(
      'water_log',
      {'user_id': userId, 'date': date, 'amount_ml': amountMl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getStartingWeight(String userId) async {
    final db = await database;
    final rows = await db.query(
      'weight_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['weight_kg'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getWaterHistory(String userId, int days) async {
    final db = await database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> history = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final rows = await db.query(
        'water_log',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );

      history.add({
        'date': dateStr,
        'amount_ml': rows.isNotEmpty ? (rows.first['amount_ml'] as num).toInt() : 0,
      });
    }
    return history;
  }

  // --- shopping_list ------------------------------------------------------

  Future<List<ShoppingItem>> getShoppingItems(String userId) async {
    final db = await database;
    final rows = await db.query(
      'shopping_list',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'recipe_name ASC, name ASC',
    );
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<int> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    return db.insert('shopping_list', item.toMap());
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> saveShoppingItemsBulk(String userId, List<ShoppingItem> newItems) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in newItems) {
        final List<Map<String, dynamic>> existing = await txn.query(
          'shopping_list',
          where: 'user_id = ? AND name = ? AND (recipe_name = ? OR (recipe_name IS NULL AND ? IS NULL))',
          whereArgs: [userId, item.name, item.recipeName, item.recipeName],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          final currentQty = (existing.first['quantity'] as num).toInt();
          await txn.update(
            'shopping_list',
            {'quantity': currentQty + item.quantity},
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          await txn.insert('shopping_list', item.toMap());
        }
      }
    });
  }

  Future<void> deleteShoppingItem(int id) async {
    final db = await database;
    await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllShoppingItems(String userId) async {
    final db = await database;
    await db.delete(
      'shopping_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearCheckedShoppingItems(String userId) async {
    final db = await database;
    await db.delete(
      'shopping_list',
      where: 'user_id = ? AND is_checked = 1',
      whereArgs: [userId],
    );
  }

  Future<ShoppingItem?> findShoppingItem(String userId, String name, String? recipeName) async {
    final db = await database;
    final rows = await db.query(
      'shopping_list',
      where: 'user_id = ? AND name = ? AND (recipe_name = ? OR (recipe_name IS NULL AND ? IS NULL))',
      whereArgs: [userId, name, recipeName, recipeName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShoppingItem.fromMap(rows.first);
  }

  // --- aisle_cache --------------------------------------------------------

  Future<String?> getCachedAisle(String ingredientName) async {
    final db = await database;
    final rows = await db.query(
      'aisle_cache',
      where: 'ingredient_name = ?',
      whereArgs: [ingredientName.toLowerCase().trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['category'] as String?;
  }

  Future<void> putCachedAisle(String ingredientName, String category) async {
    final db = await database;
    await db.insert(
      'aisle_cache',
      {
        'ingredient_name': ingredientName.toLowerCase().trim(),
        'category': category,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- price_cache --------------------------------------------------------

  Future<double?> getCachedPrice(String ingredientName) async {
    final db = await database;
    final rows = await db.query(
      'price_cache',
      where: 'ingredient_name = ?',
      whereArgs: [ingredientName.toLowerCase().trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final cachedAt = rows.first['cached_at'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age > const Duration(days: 7).inMilliseconds) return null; // Expire after 7 days

    return (rows.first['price_php'] as num).toDouble();
  }

  Future<void> putCachedPrice(String ingredientName, double price) async {
    final db = await database;
    await db.insert(
      'price_cache',
      {
        'ingredient_name': ingredientName.toLowerCase().trim(),
        'price_php': price,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- food_library --------------------------------------------------------

  Future<List<FoodLibraryItem>> searchFoodLibrary(String query) async {
    final db = await database;
    
    final List<String> keywords = query.trim().split(RegExp(r'\s+'));
    if (keywords.isEmpty) return [];

    final String whereClause = keywords.map((_) => 'name LIKE ?').join(' AND ');
    final List<String> whereArgs = keywords.map((k) => '%$k%').toList();

    final rows = await db.query(
      'food_library',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 50,
    );
    
    return rows.map(FoodLibraryItem.fromMap).toList();
  }

  Future<int> getFoodLibraryCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM food_library');
    return (res.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<List<FoodLibraryItem>> getRandomTitanFoods({int limit = 20, String? category}) async {
    final db = await database;
    String? where;
    List<Object?>? whereArgs;
    
    if (category != null) {
      where = 'category = ?';
      whereArgs = [category];
    }

    final rows = await db.query(
      'food_library',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return rows.map(FoodLibraryItem.fromMap).toList();
  }
}
