/// A user's profile, stored locally in the `user_profile` SQLite table.
///
/// [userId] is the Firebase Authentication user id (the primary key), which is
/// how meal logs and saved meals are linked back to a person.
class UserProfile {
  final String userId;
  final String? name;
  final String? email;
  final String? contactNumber;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? birthday;
  final String unitSystem;
  final String? activityLevel;
  final String? dietaryPreferences;
  final String? healthGoal;
  final String? goalPace;
  final double? customCalories;
  final double? customProtein;
  final double? customCarbs;
  final double? customFat;
  final bool autoAdjust;

  // Customizations
  final String themeMode; // System, Light, Dark
  final bool showSurplus;
  final String macroPreset; // Default, High-Protein, Keto, Low Carb, Custom
  final String mealLoggingStyle; // Default, Manual
  final bool mealLogSoundsEnabled;
  final String dayResetTime; // e.g. "00:00"
  final String weekStartDay; // Monday, Sunday
  final String timezone; // e.g. "Manila"

  // Custom Macros (percentages)
  final double customMacroProtein;
  final double customMacroCarbs;
  final double customMacroFat;

  final String? createdAt; // yyyy-MM-dd

  const UserProfile({
    required this.userId,
    this.name,
    this.email,
    this.contactNumber,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.birthday,
    this.unitSystem = 'Metric',
    this.activityLevel,
    this.dietaryPreferences,
    this.healthGoal,
    this.goalPace,
    this.customCalories,
    this.customProtein,
    this.customCarbs,
    this.customFat,
    this.autoAdjust = true,
    this.themeMode = 'System',
    this.showSurplus = true,
    this.macroPreset = 'Default',
    this.mealLoggingStyle = 'Default',
    this.mealLogSoundsEnabled = true,
    this.dayResetTime = '00:00',
    this.weekStartDay = 'Monday',
    this.timezone = 'Manila',
    this.customMacroProtein = 33.3,
    this.customMacroCarbs = 33.3,
    this.customMacroFat = 33.4,
    this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'contact_number': contactNumber,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'target_weight_kg': targetWeightKg,
        'birthday': birthday,
        'unit_system': unitSystem,
        'activity_level': activityLevel,
        'dietary_preferences': dietaryPreferences,
        'health_goal': healthGoal,
        'goal_pace': goalPace,
        'custom_calories': customCalories,
        'custom_protein': customProtein,
        'custom_carbs': customCarbs,
        'custom_fat': customFat,
        'auto_adjust': autoAdjust ? 1 : 0,
        'theme_mode': themeMode,
        'show_surplus': showSurplus ? 1 : 0,
        'macro_preset': macroPreset,
        'meal_logging_style': mealLoggingStyle,
        'meal_log_sounds_enabled': mealLogSoundsEnabled ? 1 : 0,
        'day_reset_time': dayResetTime,
        'week_start_day': weekStartDay,
        'timezone': timezone,
        'custom_macro_protein': customMacroProtein,
        'custom_macro_carbs': customMacroCarbs,
        'custom_macro_fat': customMacroFat,
        'created_at': createdAt,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        userId: map['user_id'] as String,
        name: map['name'] as String?,
        email: map['email'] as String?,
        contactNumber: map['contact_number'] as String?,
        age: (map['age'] as num?)?.toInt(),
        gender: map['gender'] as String?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
        birthday: map['birthday'] as String?,
        unitSystem: map['unit_system'] as String? ?? 'Metric',
        activityLevel: map['activity_level'] as String?,
        dietaryPreferences: map['dietary_preferences'] as String?,
        healthGoal: map['health_goal'] as String?,
        goalPace: map['goal_pace'] as String?,
        customCalories: (map['custom_calories'] as num?)?.toDouble(),
        customProtein: (map['custom_protein'] as num?)?.toDouble(),
        customCarbs: (map['custom_carbs'] as num?)?.toDouble(),
        customFat: (map['custom_fat'] as num?)?.toDouble(),
        autoAdjust: (map['auto_adjust'] as int?) != 0,
        themeMode: map['theme_mode'] as String? ?? 'System',
        showSurplus: (map['show_surplus'] as int? ?? 1) != 0,
        macroPreset: map['macro_preset'] as String? ?? 'Default',
        mealLoggingStyle: map['meal_logging_style'] as String? ?? 'Default',
        mealLogSoundsEnabled: (map['meal_log_sounds_enabled'] as int? ?? 1) != 0,
        dayResetTime: map['day_reset_time'] as String? ?? '00:00',
        weekStartDay: map['week_start_day'] as String? ?? 'Monday',
        timezone: map['timezone'] as String? ?? 'Manila',
        customMacroProtein: (map['custom_macro_protein'] as num? ?? 33.3).toDouble(),
        customMacroCarbs: (map['custom_macro_carbs'] as num? ?? 33.3).toDouble(),
        customMacroFat: (map['custom_macro_fat'] as num? ?? 33.4).toDouble(),
        createdAt: map['created_at'] as String?,
      );

  UserProfile copyWith({
    String? name,
    String? email,
    String? contactNumber,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? birthday,
    String? unitSystem,
    String? activityLevel,
    String? dietaryPreferences,
    String? healthGoal,
    String? goalPace,
    double? customCalories,
    double? customProtein,
    double? customCarbs,
    double? customFat,
    bool? autoAdjust,
    String? themeMode,
    bool? showSurplus,
    String? macroPreset,
    String? mealLoggingStyle,
    bool? mealLogSoundsEnabled,
    String? dayResetTime,
    String? weekStartDay,
    String? timezone,
    double? customMacroProtein,
    double? customMacroCarbs,
    double? customMacroFat,
    String? createdAt,
  }) =>
      UserProfile(
        userId: userId,
        name: name ?? this.name,
        email: email ?? this.email,
        contactNumber: contactNumber ?? this.contactNumber,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        birthday: birthday ?? this.birthday,
        unitSystem: unitSystem ?? this.unitSystem,
        activityLevel: activityLevel ?? this.activityLevel,
        dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
        healthGoal: healthGoal ?? this.healthGoal,
        goalPace: goalPace ?? this.goalPace,
        customCalories: customCalories ?? this.customCalories,
        customProtein: customProtein ?? this.customProtein,
        customCarbs: customCarbs ?? this.customCarbs,
        customFat: customFat ?? this.customFat,
        autoAdjust: autoAdjust ?? this.autoAdjust,
        themeMode: themeMode ?? this.themeMode,
        showSurplus: showSurplus ?? this.showSurplus,
        macroPreset: macroPreset ?? this.macroPreset,
        mealLoggingStyle: mealLoggingStyle ?? this.mealLoggingStyle,
        mealLogSoundsEnabled: mealLogSoundsEnabled ?? this.mealLogSoundsEnabled,
        dayResetTime: dayResetTime ?? this.dayResetTime,
        weekStartDay: weekStartDay ?? this.weekStartDay,
        timezone: timezone ?? this.timezone,
        customMacroProtein: customMacroProtein ?? this.customMacroProtein,
        customMacroCarbs: customMacroCarbs ?? this.customMacroCarbs,
        customMacroFat: customMacroFat ?? this.customMacroFat,
        createdAt: createdAt ?? this.createdAt,
      );
}
