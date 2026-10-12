import 'package:flutter/services.dart';

/// Service to interact with Android Accessibility Service
class AccessibilityService {
  static const MethodChannel _channel = MethodChannel('com.ride.accept.autorideacceptor/accessibility');

  /// Check if accessibility service is enabled
  Future<bool> isAccessibilityEnabled() async {
    return checkAccessibilityEnabled();
  }

  static Future<bool> checkAccessibilityEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    return openSettings();
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  /// Check if service is running
  Future<bool> isServiceRunning() async {
    return checkServiceRunning();
  }

  static Future<bool> checkServiceRunning() async {
    try {
      final bool result = await _channel.invokeMethod('isServiceRunning');
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Test real hardware touch click at specific screen coordinates
  Future<bool> testRealClick({double x = 500.0, double y = 1000.0}) async {
    try {
      final bool? result = await _channel.invokeMethod('testRealClick', {
        'x': x,
        'y': y,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open web URL or YouTube deep link
  static Future<bool> openUrl(String url) async {
    try {
      final bool? result = await _channel.invokeMethod('openUrl', {'url': url});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
