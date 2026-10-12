import 'package:flutter/services.dart';
import 'dart:convert';

/// Bridge to send service settings to Android Accessibility Service
class ServiceSettingsBridge {
  static const MethodChannel _channel = MethodChannel('com.ride.accept.autorideacceptor/settings');

  /// Send universal settings to Android Accessibility Service for all apps
  Future<void> syncUniversalSettings(Map<String, dynamic> settings) async {
    try {
      final String jsonSettings = jsonEncode(settings);
      await _channel.invokeMethod('syncUniversalSettings', {'settings': jsonSettings});
    } catch (e) {
      print('Error syncing universal settings: $e');
    }
  }

  /// Send enabled services and their settings to Android
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    try {
      final String jsonSettings = jsonEncode(settings);
      await _channel.invokeMethod('syncSettings', {'settings': jsonSettings});
    } catch (e) {
      print('Error syncing settings: $e');
    }
  }

  /// Update single service settings
  Future<void> updateServiceSettings(String serviceType, Map<String, dynamic> settings) async {
    try {
      final String jsonSettings = jsonEncode(settings);
      await _channel.invokeMethod('updateService', {
        'serviceType': serviceType,
        'settings': jsonSettings,
      });
    } catch (e) {
      print('Error updating service settings: $e');
    }
  }

  /// Sync free rides limit and plan status to Android
  Future<void> syncFreeRidesStatus({
    required bool hasActivePlan,
    required int freeRidesLimit,
    required int freeRidesUsed,
  }) async {
    try {
      await _channel.invokeMethod('syncFreeRidesStatus', {
        'hasActivePlan': hasActivePlan,
        'freeRidesLimit': freeRidesLimit,
        'freeRidesUsed': freeRidesUsed,
      });
    } catch (e) {
      print('Error syncing free rides status: $e');
    }
  }
}
