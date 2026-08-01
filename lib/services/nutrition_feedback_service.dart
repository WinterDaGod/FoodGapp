import '../constants/dost_fnri_guidelines.dart';
import '../models/daily_nutrition.dart';
import '../models/nutrition_feedback.dart';
import '../models/nutrition_target.dart';
import '../models/user_profile.dart';
import 'database_helper.dart';

/// Turns a day's logged meals into DOST-FNRI–based nutrition feedback.
///
/// The comparison logic is split into pure, dependency-free functions
/// ([buildTarget], [buildFeedback]) so it can be unit-tested without Firebase
/// or SQLite. [loadDailyFeedback] wires those to the local database.
class NutritionFeedbackService {
  NutritionFeedbackService({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  /// Loads the given day's intake and profile from the local database and
  /// returns the feedback comparing them to DOST-FNRI guidelines.
  Future<NutritionFeedback> loadDailyFeedback(
    String userId,
    String mealDate,
  ) async {
    final profile = await _db.getUserProfile(userId);
    final intake = await _db.getDailyNutrition(userId, mealDate);
    return buildFeedback(profile: profile, intake: intake);
  }

  // --- Pure computation ----------------------------------------------------

  /// Builds a recommended daily [NutritionTarget] for [profile] by applying
  /// DOST-FNRI guidelines. Falls back to DOST-FNRI defaults when the profile
  /// lacks the height/weight/age needed to estimate a personal requirement.
  static NutritionTarget buildTarget(UserProfile? profile) {
    if (profile != null && !profile.autoAdjust) {
      final kcal = profile.customCalories ?? DostFnriGuidelines.defaultEnergyKcal;
      
      // When manual mode is on, we treat the custom values as the exact targets
      // (midpoint of a small range for the UI indicators).
      NutrientRange rangeFor(double? customValue) {
        final val = customValue ?? 0.0;
        return NutrientRange(val, val); // Exact target
      }

      return NutritionTarget(
        energyKcal: kcal,
        carbsGrams: rangeFor(profile.customCarbs),
        proteinGrams: rangeFor(profile.customProtein),
        fatGrams: rangeFor(profile.customFat),
        fromDefaults: false,
      );
    }

    return calculateRecommendedTarget(profile);
  }

  /// Calculates the latest recommended targets based on the user's current
  /// profile data and selected Macro Preset, ignoring the auto-adjust flag.
  static NutritionTarget calculateRecommendedTarget(UserProfile? profile) {
    final energy = _estimateEnergyKcal(profile);
    final fromDefaults = energy.fromDefaults;
    final kcal = energy.kcal;

    // Use selected macro preset percentages
    double proteinPct = DostFnriGuidelines.proteinMidPercent;
    double carbPct = DostFnriGuidelines.carbohydrateMidPercent;
    double fatPct = DostFnriGuidelines.fatMidPercent;

    if (profile != null) {
      switch (profile.macroPreset) {
        case 'High-Protein':
          proteinPct = 40.0;
          carbPct = 30.0;
          fatPct = 30.0;
          break;
        case 'Keto':
          proteinPct = 30.0;
          carbPct = 5.0;
          fatPct = 65.0;
          break;
        case 'Low Carb':
          proteinPct = 40.0;
          carbPct = 20.0;
          fatPct = 40.0;
          break;
        case 'Custom':
          proteinPct = profile.customMacroProtein;
          carbPct = profile.customMacroCarbs;
          fatPct = profile.customMacroFat;
          break;
        case 'Default':
        default:
          // "Default" rule: 2g protein per kg of target weight, 25% fat, rest carbs.
          // Fallback to DOST-FNRI midpoints if target weight is missing.
          if (profile.targetWeightKg != null && profile.targetWeightKg! > 0) {
            final targetProteinGrams = profile.targetWeightKg! * 2.0; 
            proteinPct = (targetProteinGrams * DostFnriGuidelines.kcalPerGramProtein) / kcal * 100;
            fatPct = 25.0;
            carbPct = 100 - proteinPct - fatPct;

            // Ensure percentages stay within healthy bounds (min 15% carbs)
            if (carbPct < 15.0) {
              carbPct = 15.0;
              proteinPct = 100.0 - carbPct - fatPct;
            }
          }
          break;
      }
    }

    NutrientRange gramsFor(double percent, double kcalPerGram) {
      final targetGrams = (percent / 100 * kcal) / kcalPerGram;
      return NutrientRange(targetGrams * 0.9, targetGrams * 1.1);
    }

    return NutritionTarget(
      energyKcal: kcal,
      carbsGrams: gramsFor(carbPct, DostFnriGuidelines.kcalPerGramCarb),
      proteinGrams: gramsFor(proteinPct, DostFnriGuidelines.kcalPerGramProtein),
      fatGrams: gramsFor(fatPct, DostFnriGuidelines.kcalPerGramFat),
      fromDefaults: fromDefaults,
    );
  }

  /// Compares a day's [intake] to the DOST-FNRI target for [profile] and
  /// returns per-nutrient feedback plus an overall headline.
  static NutritionFeedback buildFeedback({
    required UserProfile? profile,
    required DailyNutrition intake,
  }) {
    final target = buildTarget(profile);
    final energyBand =
        target.energyBand(DostFnriGuidelines.energyOnTrackTolerance);

    final energy = NutrientFeedback(
      label: 'Energy',
      unit: 'kcal',
      consumed: intake.calories,
      recommended: energyBand,
      status: _classify(intake.calories, energyBand),
      insight: _energyInsight(intake, target, energyBand),
    );

    NutrientFeedback macro(
      String label,
      double consumed,
      NutrientRange range,
    ) {
      final status = _classify(consumed, range);
      return NutrientFeedback(
        label: label,
        unit: 'g',
        consumed: consumed,
        recommended: range,
        status: status,
        insight: _macroInsight(label, status, range),
      );
    }

    final carbs = macro('Carbohydrates', intake.carbs, target.carbsGrams);
    final protein = macro('Protein', intake.protein, target.proteinGrams);
    final fat = macro('Fat', intake.fat, target.fatGrams);

    // Clinical Micronutrients
    final fiber = NutrientFeedback(
      label: 'Fiber',
      unit: 'g',
      consumed: intake.fiber,
      recommended: const NutrientRange(DostFnriGuidelines.fiberMinGrams, 100),
      status: intake.fiber >= DostFnriGuidelines.fiberMinGrams ? NutrientStatus.onTrack : NutrientStatus.below,
      insight: intake.fiber >= DostFnriGuidelines.fiberMinGrams ? 'Great fiber intake!' : 'Aim for more fiber from veggies and grains.',
    );

    final sugarLimit = (target.energyKcal * (DostFnriGuidelines.sugarMaxPercent / 100)) / DostFnriGuidelines.kcalPerGramCarb;
    final sugar = NutrientFeedback(
      label: 'Sugar',
      unit: 'g',
      consumed: intake.sugar,
      recommended: NutrientRange(0, sugarLimit),
      status: intake.sugar <= sugarLimit ? NutrientStatus.onTrack : NutrientStatus.above,
      insight: intake.sugar <= sugarLimit ? 'Sugar intake is within limits.' : 'Try to reduce added sugars.',
    );

    final sodium = NutrientFeedback(
      label: 'Sodium',
      unit: 'mg',
      consumed: intake.sodium,
      recommended: const NutrientRange(0, DostFnriGuidelines.sodiumMaxMg),
      status: intake.sodium <= DostFnriGuidelines.sodiumMaxMg ? NutrientStatus.onTrack : NutrientStatus.above,
      insight: intake.sodium <= DostFnriGuidelines.sodiumMaxMg ? 'Sodium intake is healthy.' : 'Try to use less salt in your meals.',
    );

    final cholesterol = NutrientFeedback(
      label: 'Cholesterol',
      unit: 'mg',
      consumed: intake.cholesterol,
      recommended: const NutrientRange(0, DostFnriGuidelines.cholesterolMaxMg),
      status: intake.cholesterol <= DostFnriGuidelines.cholesterolMaxMg ? NutrientStatus.onTrack : NutrientStatus.above,
      insight: intake.cholesterol <= DostFnriGuidelines.cholesterolMaxMg ? 'Cholesterol levels are looking good.' : 'Consider leaner protein sources.',
    );

    return NutritionFeedback(
      intake: intake,
      target: target,
      energy: energy,
      carbs: carbs,
      protein: protein,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      cholesterol: cholesterol,
      headline: _headline(intake, [energy, carbs, protein, fat, fiber, sugar, sodium, cholesterol]),
    );
  }

  // --- Helpers -------------------------------------------------------------

  static NutrientStatus _classify(double value, NutrientRange range) {
    if (value < range.low) return NutrientStatus.below;
    if (value > range.high) return NutrientStatus.above;
    return NutrientStatus.onTrack;
  }

  /// Estimates daily energy from the profile using the PDRI's
  /// Basal Metabolic Rate × Physical Activity Level model. BMR uses the
  /// Mifflin–St Jeor equation.
  static ({double kcal, bool fromDefaults}) _estimateEnergyKcal(
    UserProfile? profile,
  ) {
    final weight = profile?.weightKg;
    final height = profile?.heightCm;
    int? age = profile?.age;

    // Use birthday if available to calculate accurate age
    if (profile?.birthday != null) {
      try {
        final birthDate = DateTime.parse(profile!.birthday!);
        final now = DateTime.now();
        age = now.year - birthDate.year;
        if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
      } catch (_) {}
    }

    if (profile == null ||
        weight == null ||
        weight <= 0 ||
        height == null ||
        height <= 0 ||
        age == null ||
        age <= 0) {
      return (kcal: DostFnriGuidelines.defaultEnergyKcal, fromDefaults: true);
    }

    final bmr = 10 * weight +
        6.25 * height -
        5 * age +
        _sexConstant(profile.gender);
    final pal = DostFnriGuidelines.palForActivityLevel(profile.activityLevel);
    var energy = bmr * pal + _goalDelta(profile);
    if (energy < DostFnriGuidelines.minSafeEnergyKcal) {
      energy = DostFnriGuidelines.minSafeEnergyKcal;
    }
    return (kcal: energy, fromDefaults: false);
  }

  /// Sex constant in the Mifflin–St Jeor equation (+5 male, −161 female).
  /// When sex is unknown we use their average, a neutral middle value.
  static double _sexConstant(String? gender) {
    final value = gender?.toLowerCase().trim() ?? '';
    if (value.startsWith('m')) return 5;
    if (value.startsWith('f') || value.startsWith('w')) return -161;
    return -78;
  }

  /// Energy adjustment based on goal and pace.
  static double _goalDelta(UserProfile? profile) {
    final goal = profile?.healthGoal?.toLowerCase() ?? '';
    final paceStr = profile?.goalPace?.toLowerCase() ?? '';
    
    // Extract numerical pace (e.g. 0.75 from "Lose 0.75 kg/week")
    final match = RegExp(r'[\d.]+').firstMatch(paceStr);
    final pace = match != null ? double.tryParse(match.group(0)!) ?? 0.0 : 0.0;
    
    // 1kg body fat ≈ 7700 kcal. 
    // Daily delta = (pace * 7700) / 7.
    final delta = (pace * 7700) / 7;

    if (goal.contains('lose') || goal.contains('loss')) {
      return -delta;
    }
    if (goal.contains('gain') || goal.contains('build')) {
      return delta;
    }
    return 0;
  }

  static String _energyInsight(
    DailyNutrition intake,
    NutritionTarget target,
    NutrientRange band,
  ) {
    final targetKcal = target.energyKcal.round();
    switch (_classify(intake.calories, band)) {
      case NutrientStatus.below:
        final short = (target.energyKcal - intake.calories).round();
        return 'About $short kcal under your estimated need of '
            '$targetKcal kcal. Add a balanced meal or snack to fuel your day.';
      case NutrientStatus.above:
        final over = (intake.calories - target.energyKcal).round();
        return 'About $over kcal over your estimated need of '
            '$targetKcal kcal. Lighter portions can bring it back in line.';
      case NutrientStatus.onTrack:
        return 'Right around your estimated need of $targetKcal kcal — '
            'nicely balanced.';
    }
  }

  static String _macroInsight(
    String label,
    NutrientStatus status,
    NutrientRange range,
  ) {
    final low = range.low.round();
    final high = range.high.round();
    switch (status) {
      case NutrientStatus.below:
        return 'Below the DOST-FNRI range of $low–$high g. '
            '${_lowTip(label)}';
      case NutrientStatus.above:
        return 'Above the DOST-FNRI range of $low–$high g. '
            '${_highTip(label)}';
      case NutrientStatus.onTrack:
        return 'Within the DOST-FNRI range of $low–$high g. Keep it up!';
    }
  }

  static String _lowTip(String label) {
    switch (label) {
      case 'Carbohydrates':
        return 'Add rice, root crops or whole grains for steady energy.';
      case 'Protein':
        return 'Include fish, lean meat, eggs or beans to reach it.';
      case 'Fat':
        return 'A little healthy fat (nuts, fish, oil) helps absorb vitamins.';
      default:
        return 'Aim for a more balanced plate.';
    }
  }

  static String _highTip(String label) {
    switch (label) {
      case 'Carbohydrates':
        return 'Trim sugary drinks and refined carbs; favour vegetables.';
      case 'Protein':
        return 'Slightly smaller protein portions are fine.';
      case 'Fat':
        return 'Go easy on fried and fatty foods.';
      default:
        return 'Aim for a more balanced plate.';
    }
  }

  static String _headline(
    DailyNutrition intake,
    List<NutrientFeedback> nutrients,
  ) {
    if (intake.isEmpty) {
      return 'No meals logged yet today — log a meal to see how it compares '
          'to DOST-FNRI guidelines.';
    }
    final onTrack =
        nutrients.where((n) => n.status == NutrientStatus.onTrack).length;
    final total = nutrients.length;
    if (onTrack == total) {
      return 'Great balance today — every nutrient is within DOST-FNRI '
          'recommendations.';
    }
    if (onTrack >= total - 1) {
      return 'Well balanced — $onTrack of $total nutrients are on track with '
          'DOST-FNRI guidelines.';
    }
    if (onTrack == 0) {
      return 'Today\'s intake is off balance. Aim for a "Pinggang Pinoy" '
          'plate — go, grow and glow foods in the right proportions.';
    }
    return '$onTrack of $total nutrients are on track. A few tweaks will get '
        'you closer to DOST-FNRI guidelines.';
  }
}
