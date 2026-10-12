import 'package:flutter/foundation.dart';

/// Logger utility class
class Logger {
  static void log(String message, {String tag = 'AutoRide'}) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'AutoRide', Object? error}) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message');
      if (error != null) {
        print('[$tag] ${error.toString()}');
      }
    }
  }

  static void success(String message, {String tag = 'AutoRide'}) {
    if (kDebugMode) {
      print('[$tag] ✓ $message');
    }
  }

  static void warning(String message, {String tag = 'AutoRide'}) {
    if (kDebugMode) {
      print('[$tag] ⚠ $message');
    }
  }
}
