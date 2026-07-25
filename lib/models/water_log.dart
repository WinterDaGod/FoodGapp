class WaterLog {
  final String userId;
  final String date; // yyyy-MM-dd
  final int amountMl;

  const WaterLog({
    required this.userId,
    required this.date,
    required this.amountMl,
  });

  Map<String, Object?> toMap() => {
        'user_id': userId,
        'date': date,
        'amount_ml': amountMl,
      };

  factory WaterLog.fromMap(Map<String, Object?> map) => WaterLog(
        userId: map['user_id'] as String,
        date: map['date'] as String,
        amountMl: (map['amount_ml'] as num).toInt(),
      );
}
