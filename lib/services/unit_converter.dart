class UnitConverter {
  static const double kgToLbsFactor = 2.20462;
  static const double cmToInFactor = 0.393701;

  // --- Weight --------------------------------------------------------------

  static double kgToLbs(double kg) => kg * kgToLbsFactor;
  static double lbsToKg(double lbs) => lbs / kgToLbsFactor;

  static String formatWeight(double kg, String system) {
    if (system == 'Imperial') {
      return '${kgToLbs(kg).toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  // --- Height --------------------------------------------------------------

  static double cmToIn(double cm) => cm * cmToInFactor;
  static double inToCm(double inches) => inches / cmToInFactor;

  static double feetInchesToCm(int feet, double inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches / cmToInFactor;
  }

  static String formatHeight(double cm, String system) {
    if (system == 'Imperial') {
      final totalInches = cmToIn(cm);
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
    return '${cm.round()} cm';
  }

  // --- Helpers for inputs --------------------------------------------------

  /// Converts a value from the specified system to the canonical Metric value.
  static double toMetric(double value, String system, String unitType) {
    if (system == 'Metric') return value;
    if (unitType == 'weight') return lbsToKg(value);
    if (unitType == 'height') return inToCm(value);
    return value;
  }

  /// Converts a canonical Metric value to the user's preferred system value.
  static double fromMetric(double value, String system, String unitType) {
    if (system == 'Metric') return value;
    if (unitType == 'weight') return kgToLbs(value);
    if (unitType == 'height') return cmToIn(value);
    return value;
  }
}
