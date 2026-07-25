import '../models/fasting_session.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'app_events.dart';

class FastingService {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();

  Future<FastingSession?> getActiveSession() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _db.getActiveFastingSession(userId);
  }

  Future<void> startFast({required int hours, required DateTime startTime, required String repeatMode}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // End any existing active session first
    await _db.endActiveFastingSession(userId);

    final session = FastingSession(
      userId: userId,
      startTime: startTime,
      targetHours: hours,
      repeatMode: repeatMode,
    );

    await _db.insertFastingSession(session);
    AppEvents.instance.notifyFastingChanged();
  }

  Future<void> stopFast() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _db.endActiveFastingSession(userId);
    AppEvents.instance.notifyFastingChanged();
  }

  Future<List<FastingSession>> getHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    return _db.getFastingHistory(userId);
  }

  Future<void> deleteSession(int id) async {
    await _db.deleteFastingSession(id);
    AppEvents.instance.notifyFastingChanged();
  }
}
