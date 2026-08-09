class VitalityLog {
  final int? id;
  final String userId;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm
  
  // Blood Pressure
  final int? systolic;
  final int? diastolic;
  
  // Blood Glucose (typically mg/dL)
  final double? glucose;
  
  // Context (e.g. "Before Breakfast", "After Exercise")
  final String? note;

  const VitalityLog({
    this.id,
    required this.userId,
    required this.date,
    required this.time,
    this.systolic,
    this.diastolic,
    this.glucose,
    this.note,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'date': date,
    'time': time,
    'systolic': systolic,
    'diastolic': diastolic,
    'glucose': glucose,
    'note': note,
  };

  factory VitalityLog.fromMap(Map<String, Object?> map) => VitalityLog(
    id: map['id'] as int?,
    userId: map['user_id'] as String,
    date: map['date'] as String,
    time: map['time'] as String,
    systolic: map['systolic'] as int?,
    diastolic: map['diastolic'] as int?,
    glucose: (map['glucose'] as num?)?.toDouble(),
    note: map['note'] as String?,
  );

  bool get hasBp => systolic != null && diastolic != null;
  bool get hasGlucose => glucose != null;
  
  String get bpDisplay => hasBp ? '$systolic/$diastolic' : '--/--';
  String get glucoseDisplay => hasGlucose ? '${glucose!.toStringAsFixed(1)} mg/dL' : '--';
}
