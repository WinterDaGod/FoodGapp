import 'dart:io';
import 'package:health/health.dart';

class HealthSyncService {
  HealthSyncService._internal();
  static final HealthSyncService instance = HealthSyncService._internal();

  final Health _health = Health();

  Future<Map<String, double>> fetchTodayActivity() async {
    // Demo Mode for iOS (Apple strictly blocks HealthKit for free developer accounts)
    if (Platform.isIOS) {
      return {
        'steps': 5420.0, 
        'burned': 215.0,
      };
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];

    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    bool hasPermissions = await _health.hasPermissions(types) ?? false;
    if (!hasPermissions) {
      hasPermissions = await _health.requestAuthorization(types, permissions: permissions);
    }

    if (!hasPermissions) return {'steps': 0.0, 'burned': 0.0};

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      double totalSteps = 0;
      double totalBurned = 0;

      for (var p in data) {
        if (p.type == HealthDataType.STEPS) {
          totalSteps += (p.value as num).toDouble();
        } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          totalBurned += (p.value as num).toDouble();
        }
      }

      return {
        'steps': totalSteps,
        'burned': totalBurned,
      };
    } catch (e) {
      print('Health Sync Error: $e');
      return {'steps': 0.0, 'burned': 0.0};
    }
  }
}
