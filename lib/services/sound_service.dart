import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'database_helper.dart';

class SoundService {
  SoundService._internal();
  static final SoundService instance = SoundService._internal();

  final _auth = AuthService();
  final _db = DatabaseHelper.instance;

  /// Plays a subtle success click and triggers haptic feedback if enabled in Profile.
  Future<void> playSuccess() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final profile = await _db.getUserProfile(userId);
    final bool enabled = profile?.mealLogSoundsEnabled ?? true;

    if (enabled) {
      print('🔊 Playing success sound and haptic...');
      // Premium System "Click" sound
      await SystemSound.play(SystemSoundType.click);
      // Subtle tactile feedback
      await HapticFeedback.lightImpact();
    } else {
      print('🔇 Sounds disabled in profile.');
    }
  }

  /// Triggers a slightly heavier feedback for major milestones (like weight loss or fast completion).
  Future<void> playCelebration() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final profile = await _db.getUserProfile(userId);
    final bool enabled = profile?.mealLogSoundsEnabled ?? true;

    if (enabled) {
      print('🎉 Playing celebration sound and haptic...');
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    }
  }
}
