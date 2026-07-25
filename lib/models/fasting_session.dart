import 'fasting_stage.dart';

class FastingSession {
  final int? id;
  final String userId;
  final DateTime startTime;
  final int targetHours; // e.g. 16 for 16:8
  final DateTime? endTime; // null if still active
  final String repeatMode; // 'No repeat', 'Every day', 'Custom'
  final bool isCompleted;

  const FastingSession({
    this.id,
    required this.userId,
    required this.startTime,
    required this.targetHours,
    this.endTime,
    required this.repeatMode,
    this.isCompleted = false,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'target_hours': targetHours,
        'end_time': endTime?.toIso8601String(),
        'repeat_mode': repeatMode,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory FastingSession.fromMap(Map<String, Object?> map) => FastingSession(
        id: (map['id'] as num?)?.toInt(),
        userId: map['user_id'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        targetHours: (map['target_hours'] as num?)?.toInt() ?? 0,
        endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
        repeatMode: map['repeat_mode'] as String? ?? 'No repeat',
        isCompleted: (map['is_completed'] as int?) == 1,
      );

  Duration get elapsedDuration {
    final end = isCompleted ? (endTime ?? DateTime.now()) : DateTime.now();
    return end.difference(startTime);
  }

  double get elapsedHours => elapsedDuration.inSeconds / 3600.0;

  double get progress {
    if (isCompleted || targetHours == 0) return 1.0;
    final targetSeconds = targetHours * 3600;
    return (elapsedDuration.inSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  String get timeRemaining {
    if (isCompleted) return 'Completed';
    final targetEnd = startTime.add(Duration(hours: targetHours));
    final remaining = targetEnd.difference(DateTime.now());
    if (remaining.isNegative) return 'Goal Reached';
    
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    return '${h}h ${m}m remaining';
  }

  FastingStage get currentStage => FastingStage.getStageForHours(elapsedHours);

  String get formattedElapsed {
    final d = elapsedDuration;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$ms';
  }
}
