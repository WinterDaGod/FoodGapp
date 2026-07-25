import 'package:flutter/foundation.dart';

/// A simple singleton to notify screens about data changes across different
/// navigation stacks.
class AppEvents {
  AppEvents._internal();
  static final AppEvents instance = AppEvents._internal();

  /// Notifier that increments whenever a meal is added, edited, or deleted.
  final ValueNotifier<int> mealChanged = ValueNotifier<int>(0);

  /// Notifier that increments whenever the user profile is updated.
  final ValueNotifier<int> profileChanged = ValueNotifier<int>(0);

  /// Notifier that increments whenever a fasting session starts or ends.
  final ValueNotifier<int> fastingChanged = ValueNotifier<int>(0);

  /// Notifier that increments whenever a weight log is added.
  final ValueNotifier<int> weightChanged = ValueNotifier<int>(0);

  void notifyMealChanged() {
    mealChanged.value++;
  }

  void notifyProfileChanged() {
    profileChanged.value++;
  }

  void notifyFastingChanged() {
    fastingChanged.value++;
  }

  void notifyWeightChanged() {
    weightChanged.value++;
  }
}
