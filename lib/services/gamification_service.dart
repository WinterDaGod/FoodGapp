import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class GamificationService {
  GamificationService._internal();
  static final GamificationService instance = GamificationService._internal();

  final _db = DatabaseHelper.instance;
  final _auth = AuthService();

  static const int xpPerLevel = 1000;

  Future<void> updateStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final db = await _db.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    final res = await db.query('user_streaks', where: 'user_id = ?', whereArgs: [userId]);
    
    if (res.isEmpty) {
      await db.insert('user_streaks', {
        'user_id': userId,
        'current_streak': 1,
        'last_log_date': today,
        'best_streak': 1,
        'xp': 50, // Bonus for starting
        'level': 1,
      });
      return;
    }

    final data = res.first;
    final lastDate = data['last_log_date'] as String?;
    int current = (data['current_streak'] as num?)?.toInt() ?? 0;
    int best = (data['best_streak'] as num?)?.toInt() ?? 0;

    if (lastDate == today) return;

    if (lastDate == yesterday) {
      current++;
    } else {
      current = 1;
    }

    if (current > best) best = current;

    await db.update('user_streaks', {
      'current_streak': current,
      'last_log_date': today,
      'best_streak': best,
    }, where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> getCurrentStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final db = await _db.database;
    final res = await db.query('user_streaks', where: 'user_id = ?', whereArgs: [userId]);
    
    if (res.isEmpty) return 0;
    return (res.first['current_streak'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> getStreakInfo() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {'current': 0, 'best': 0};

    final db = await _db.database;
    final res = await db.query('user_streaks', where: 'user_id = ?', whereArgs: [userId]);
    
    if (res.isEmpty) return {'current': 0, 'best': 0};
    final data = res.first;
    return {
      'current': (data['current_streak'] as num?)?.toInt() ?? 0,
      'best': (data['best_streak'] as num?)?.toInt() ?? 0,
      'last_log_date': data['last_log_date'],
    };
  }

  Future<void> addXp(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final db = await _db.database;
    final res = await db.query('user_streaks', where: 'user_id = ?', whereArgs: [userId]);

    int currentXp = 0;
    int currentLevel = 1;

    if (res.isNotEmpty) {
      currentXp = (res.first['xp'] as num?)?.toInt() ?? 0;
      currentLevel = (res.first['level'] as num?)?.toInt() ?? 1;
    }

    currentXp += amount;
    
    // Check for level up
    int newLevel = (currentXp / xpPerLevel).floor() + 1;
    if (newLevel > currentLevel) {
      // Level Up!
      debugPrint("🚀 LEVEL UP: $newLevel");
    }

    if (res.isEmpty) {
      await db.insert('user_streaks', {
        'user_id': userId,
        'xp': currentXp,
        'level': newLevel,
        'current_streak': 0,
        'best_streak': 0,
      });
    } else {
      await db.update('user_streaks', {
        'xp': currentXp,
        'level': newLevel,
      }, where: 'user_id = ?', whereArgs: [userId]);
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final db = await _db.database;
    
    // Check if already unlocked
    final existing = await db.query(
      'user_achievements', 
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId]
    );

    if (existing.isEmpty) {
      await db.insert('user_achievements', {
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });
      // Award XP for achievement
      await addXp(100);
    }
  }

  Future<Map<String, dynamic>> getGamificationStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final db = await _db.database;
    final streakRes = await db.query('user_streaks', where: 'user_id = ?', whereArgs: [userId]);
    final achRes = await db.query('user_achievements', where: 'user_id = ?', whereArgs: [userId]);

    final Map<String, dynamic> stats = {};
    if (streakRes.isNotEmpty) {
      stats.addAll(streakRes.first);
    } else {
      stats['current_streak'] = 0;
      stats['best_streak'] = 0;
      stats['xp'] = 0;
      stats['level'] = 1;
    }

    stats['achievements'] = achRes.map((a) => a['achievement_id']).toList();
    return stats;
  }
}
