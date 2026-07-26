import 'package:flutter/foundation.dart';
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

/// Single point of access to the on-device SQLite database.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  @visibleForTesting
  DatabaseHelper.forTesting(Database database) : _database = database;

  static const _databaseName = 'foodgapp.db';
  static const _databaseVersion = 19;

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final databasesDir = await getDatabasesPath();
    final path = p.join(databasesDir, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
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
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_log (
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
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        api_meal_id TEXT,
        meal_name TEXT,
        image_url TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_cache (
        api_meal_id TEXT PRIMARY KEY,
        meal_name TEXT,
        calories REAL,
        protein REAL,
        carbs REAL,
        fat REAL,
        raw_json TEXT,
        cached_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE fasting_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        target_hours INTEGER NOT NULL,
        end_time TEXT,
        repeat_mode TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE active_meal_plan (
        id INTEGER PRIMARY KEY,
        plan_type TEXT NOT NULL,
        data_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_log (
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        PRIMARY KEY (user_id, date),
        FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        recipe_name TEXT,
        category TEXT,
        quantity INTEGER DEFAULT 1,
        is_checked INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE aisle_cache (
        ingredient_name TEXT PRIMARY KEY,
        category TEXT NOT NULL
      )
    ''');

    // Add indexes for performance
    await db.execute('CREATE INDEX idx_saved_meals_user ON saved_meals (user_id)');
    await db.execute('CREATE INDEX idx_meal_log_user_date ON meal_log (user_id, meal_date)');
    await db.execute('CREATE INDEX idx_nutrition_cache_id ON nutrition_cache (api_meal_id)');
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      if (!columns.any((c) => c['name'] == 'target_weight_kg')) {
        await db.execute('ALTER TABLE user_profile ADD COLUMN target_weight_kg REAL');
      }
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='weight_log'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE weight_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            date TEXT NOT NULL,
            weight_kg REAL NOT NULL,
            FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
          )
        ''');
      }
    }
    if (oldVersion < 3) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      if (!columns.any((c) => c['name'] == 'goal_pace')) {
        await db.execute('ALTER TABLE user_profile ADD COLUMN goal_pace TEXT');
      }
    }
    if (oldVersion < 4) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('custom_calories')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_calories REAL');
      if (!names.contains('custom_protein')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_protein REAL');
      if (!names.contains('custom_carbs')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_carbs REAL');
      if (!names.contains('custom_fat')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_fat REAL');
      if (!names.contains('auto_adjust')) await db.execute('ALTER TABLE user_profile ADD COLUMN auto_adjust INTEGER DEFAULT 1');
    }
    if (oldVersion < 5) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('birthday')) await db.execute('ALTER TABLE user_profile ADD COLUMN birthday TEXT');
      if (!names.contains('unit_system')) await db.execute("ALTER TABLE user_profile ADD COLUMN unit_system TEXT DEFAULT 'Metric'");
    }
    if (oldVersion < 6) {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='fasting_log'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE fasting_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            start_time TEXT NOT NULL,
            target_hours INTEGER NOT NULL,
            end_time TEXT,
            repeat_mode TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
          )
        ''');
      }
    }
    if (oldVersion < 7) {
      final columns = await db.rawQuery('PRAGMA table_info(meal_log)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('image_url')) await db.execute('ALTER TABLE meal_log ADD COLUMN image_url TEXT');
      if (!names.contains('is_pinned')) await db.execute('ALTER TABLE meal_log ADD COLUMN is_pinned INTEGER DEFAULT 0');
    }
    if (oldVersion < 8) {
      final columns = await db.rawQuery('PRAGMA table_info(meal_log)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('meal_time')) await db.execute('ALTER TABLE meal_log ADD COLUMN meal_time TEXT');
    }
    if (oldVersion < 9) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('theme_mode')) await db.execute("ALTER TABLE user_profile ADD COLUMN theme_mode TEXT DEFAULT 'System'");
      if (!names.contains('show_surplus')) await db.execute('ALTER TABLE user_profile ADD COLUMN show_surplus INTEGER DEFAULT 1');
      if (!names.contains('macro_preset')) await db.execute("ALTER TABLE user_profile ADD COLUMN macro_preset TEXT DEFAULT 'Default'");
      if (!names.contains('meal_logging_style')) await db.execute("ALTER TABLE user_profile ADD COLUMN meal_logging_style TEXT DEFAULT 'Default'");
      if (!names.contains('meal_log_sounds_enabled')) await db.execute('ALTER TABLE user_profile ADD COLUMN meal_log_sounds_enabled INTEGER DEFAULT 1');
      if (!names.contains('day_reset_time')) await db.execute("ALTER TABLE user_profile ADD COLUMN day_reset_time TEXT DEFAULT '00:00'");
      if (!names.contains('week_start_day')) await db.execute("ALTER TABLE user_profile ADD COLUMN week_start_day TEXT DEFAULT 'Monday'");
      if (!names.contains('timezone')) await db.execute("ALTER TABLE user_profile ADD COLUMN timezone TEXT DEFAULT 'Manila'");
    }
    if (oldVersion < 10) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('custom_macro_protein')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_macro_protein REAL DEFAULT 33.3');
      if (!names.contains('custom_macro_carbs')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_macro_carbs REAL DEFAULT 33.3');
      if (!names.contains('custom_macro_fat')) await db.execute('ALTER TABLE user_profile ADD COLUMN custom_macro_fat REAL DEFAULT 33.4');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE active_meal_plan (
          id INTEGER PRIMARY KEY,
          plan_type TEXT NOT NULL,
          data_json TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE water_log (
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          amount_ml INTEGER NOT NULL,
          PRIMARY KEY (user_id, date),
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE shopping_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          recipe_name TEXT,
          is_checked INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES user_profile (user_id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 14) {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('created_at')) {
        await db.execute('ALTER TABLE user_profile ADD COLUMN created_at TEXT');
      }
    }
    if (oldVersion < 15) {
      final columns = await db.rawQuery('PRAGMA table_info(meal_log)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('ingredients_json')) await db.execute('ALTER TABLE meal_log ADD COLUMN ingredients_json TEXT');
      if (!names.contains('base_calories')) await db.execute('ALTER TABLE meal_log ADD COLUMN base_calories REAL');
      if (!names.contains('base_protein')) await db.execute('ALTER TABLE meal_log ADD COLUMN base_protein REAL');
      if (!names.contains('base_carbs')) await db.execute('ALTER TABLE meal_log ADD COLUMN base_carbs REAL');
      if (!names.contains('base_fat')) await db.execute('ALTER TABLE meal_log ADD COLUMN base_fat REAL');
    }
    if (oldVersion < 16) {
      // Add category to shopping_list
      final columns = await db.rawQuery('PRAGMA table_info(shopping_list)');
      if (!columns.any((c) => c['name'] == 'category')) {
        await db.execute('ALTER TABLE shopping_list ADD COLUMN category TEXT');
      }
      
      // Create aisle_cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS aisle_cache (
          ingredient_name TEXT PRIMARY KEY,
          category TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 17) {
      final columns = await db.rawQuery('PRAGMA table_info(shopping_list)');
      if (!columns.any((c) => c['name'] == 'quantity')) {
        await db.execute('ALTER TABLE shopping_list ADD COLUMN quantity INTEGER DEFAULT 1');
      }
    }
    if (oldVersion < 18) {
      // Ensure aisle_cache exists (Fix for missing table bug)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS aisle_cache (
          ingredient_name TEXT PRIMARY KEY,
          category TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 19) {
      // Add indexes for performance (Saved tab optimization)
      await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_meals_user ON saved_meals (user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_log_user_date ON meal_log (user_id, meal_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_nutrition_cache_id ON nutrition_cache (api_meal_id)');
    }
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
    
    // Attempt to update first to avoid ConflictAlgorithm.replace 
    // which triggers a DELETE (and thus cascaded deletes on logs)
    final count = await db.update(
      'user_profile',
      map,
      where: 'user_id = ?',
      whereArgs: [profile.userId],
    );

    if (count == 0) {
      // User doesn't exist, safe to insert
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
    return db.insert('meal_log', log.toMap());
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
    
    // Split into chunks if there are many IDs (SQLite limit is usually 999 parameters)
    final Map<String, Recipe> results = {};
    
    // Using simple IN clause with placeholders
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
    // We use id 1 for daily, 2 for weekly to keep them separate
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
}
