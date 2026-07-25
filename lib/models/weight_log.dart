class WeightLog {
  final int? id;
  final String userId;
  final String date; // yyyy-MM-dd
  final double weightKg;

  const WeightLog({
    this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'weight_kg': weightKg,
      };

  factory WeightLog.fromMap(Map<String, Object?> map) => WeightLog(
        id: (map['id'] as num?)?.toInt(),
        userId: map['user_id'] as String,
        date: map['date'] as String,
        weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      );
}
