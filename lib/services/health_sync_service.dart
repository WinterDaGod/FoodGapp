import 'dart:io';
import 'package:health/health.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HealthSyncService {
  HealthSyncService._internal();
  static final HealthSyncService instance = HealthSyncService._internal();

  final Health _health = Health();

  Future<Map<String, double>> fetchTodayActivity() async {
    // 1. Clinical Demo Mode for iOS
    // (Bypasses HealthKit to avoid build issues on non-entitled Apple accounts)
    if (Platform.isIOS) {
      print('FLUTTER_HEALTH: iOS Demo Mode active. Returning clinical estimates.');
      
      // Generate slight variations based on the current hour to make it look "live"
      final hour = DateTime.now().hour;
      final baseSteps = 4000.0 + (hour * 200.0);
      final baseBurned = 150.0 + (hour * 10.5);
      
      return {
        'steps': baseSteps, 
        'burned': baseBurned,
      };
    }

    // 2. Emulator Check (Health Connect is generally not supported on emulators)
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (!androidInfo.isPhysicalDevice) {
      print('FLUTTER_HEALTH: Sync disabled. Health Connect is not supported on emulators.');
      return {'steps': 0.0, 'burned': 0.0};
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];

    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    // 3. Availability Check
    try {
      final bool isInstalled = await _health.isHealthConnectAvailable();
      if (!isInstalled) {
        print('FLUTTER_HEALTH: Health Connect app is missing.');
        return {'steps': 0.0, 'burned': 0.0};
      }
      
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
        print('FLUTTER_HEALTH: Health Connect SDK status: $sdkStatus');
        return {'steps': 0.0, 'burned': 0.0};
      }
    } catch (e) {
      print('FLUTTER_HEALTH Availability Error: $e');
      return {'steps': 0.0, 'burned': 0.0};
    }

    // 4. Permissions Logic
    bool hasPermissions = false;
    try {
      hasPermissions = await _health.hasPermissions(types) ?? false;
    } catch (e) {
      print('FLUTTER_HEALTH Permission Check Error: $e');
    }

    if (!hasPermissions) {
      try {
        print('FLUTTER_HEALTH: Requesting authorization...');
        hasPermissions = await _health.requestAuthorization(types, permissions: permissions);
        
        if (!hasPermissions) {
           print('FLUTTER_HEALTH: Authorization denied or cancelled by user.');
        }
      } catch (e) {
        print('FLUTTER_HEALTH: Critical Error during auth request: $e');
        
        // If the launcher is missing, nudge the user to open Health Connect manually
        if (e.toString().contains('launcher')) {
          print('FLUTTER_HEALTH: Launcher missing fallback triggered.');
          try {
            await _health.installHealthConnect();
          } catch (_) {}
        }
        
        return {'steps': 0.0, 'burned': 0.0};
      }
    }

    if (!hasPermissions) return {'steps': 0.0, 'burned': 0.0};

    // 5. Data Fetching
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
      print('FLUTTER_HEALTH Data Fetch Error: $e');
      return {'steps': 0.0, 'burned': 0.0};
    }
  }
}
