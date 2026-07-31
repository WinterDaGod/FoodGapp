import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class GamificationService {
  GamificationService._internal();
  static final GamificationService instance = GamificationService._internal();

  final _db = DatabaseHelper.instance;
  final _auth = AuthService();

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
      });
      return;
    }

    final data = res.first;
    final lastDate = data['last_log_date'] as String;
    int current = data['current_streak'] as int;
    int best = data['best_streak'] as int;

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
    return res.first['current_streak'] as int;
  }
}
