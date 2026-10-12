import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import '../../services/accessibility_service.dart';
import 'device_info_service.dart';
import 'free_rides_service.dart';

/// Enterprise Telemetry & Remote VPS Service for AutoRide
/// Handles:
/// 1. 60-second Rider Heartbeats (Accessibility state, battery, online status)
/// 2. Ride Event Ingestion (Porter, Rapido, Ola, Uber accepted/missed counts)
/// 3. App Crashlytics Reports (Stack traces, screen names, device specs)
/// 4. Remote Dynamic Free Rides & App Settings synchronization
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  static const String keyVpsBaseUrl = 'vps_base_url';
  // Live VPS Server IP (Bangalore)
  static const String defaultVpsUrl = 'http://139.84.158.149:5000';

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Initialize heartbeat scheduler and telemetry engine
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Send immediate initial heartbeat
    await sendHeartbeat();

    // Schedule background periodic heartbeat every 60 seconds
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      sendHeartbeat();
    });

    Logger.log('🚀 TelemetryService initialized (60s heartbeat active)');
  }

  /// Get current configured VPS Base URL
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyVpsBaseUrl) ?? defaultVpsUrl;
  }

  /// Update VPS Base URL
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(keyVpsBaseUrl, cleanUrl);
    Logger.log('🌐 Updated VPS Base URL to: $cleanUrl');
  }

  /// Get current authenticated Rider UID or guest identifier
  String get currentUid {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest_unregistered';
  }

  /// Send 60s Rider Telemetry Heartbeat
  Future<bool> sendHeartbeat() async {
    try {
      final baseUrl = await getBaseUrl();
      final isAccessibilityActive = await _accessibilityService.isAccessibilityEnabled();
      final device = await _deviceInfoService.getDeviceDetails();
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      double minFare = 40.0;
      double maxFare = 25000.0;
      double pickupDistance = 5.0;
      double tripDistance = 3000.0;
      bool autoAccept = true;
      int clickDelayMs = 80;

      final configJson = prefs.getString('universal_config');
      if (configJson != null) {
        try {
          final map = jsonDecode(configJson);
          if (map is Map<String, dynamic>) {
            minFare = (map['minFare'] as num?)?.toDouble() ?? minFare;
            maxFare = (map['maxFare'] as num?)?.toDouble() ?? maxFare;
            pickupDistance = (map['pickupDistance'] as num?)?.toDouble() ?? pickupDistance;
            tripDistance = (map['tripDistance'] as num?)?.toDouble() ?? tripDistance;
            autoAccept = (map['autoAccept'] as bool?) ?? autoAccept;
            clickDelayMs = (map['clickDelayMs'] as num?)?.toInt() ?? clickDelayMs;
          }
        } catch (_) {}
      }

      final freeLimit = prefs.getInt('remote_free_rides_limit') ?? 10;
      final freeUsed = prefs.getInt('free_rides_used_count') ?? 0;

      final uid = currentUid;
      final phone = (user?.phoneNumber != null && user!.phoneNumber!.trim().isNotEmpty)
          ? user.phoneNumber!.trim()
          : (prefs.getString('user_phone_$uid') ?? prefs.getString('user_phone') ?? '');
      final name = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (prefs.getString('user_display_name') ?? 'Driver Partner');
      final email = (user?.email != null && user!.email!.trim().isNotEmpty)
          ? user.email!.trim()
          : (prefs.getString('user_email') ?? '');

      final body = {
        'uid': uid,
        'email': email,
        'displayName': name,
        'phoneNumber': phone,
        'isAccessibilityActive': isAccessibilityActive,
        'isOnline': true,
        'appVersion': '1.0.0',
        'deviceBrand': device.brand,
        'deviceModel': device.model,
        'androidVersion': device.androidVersion,
        'batteryLevel': 90, // Normal operational range
        'networkType': '4G/5G/WiFi',
        'minFare': minFare,
        'maxFare': maxFare,
        'pickupDistance': pickupDistance,
        'tripDistance': tripDistance,
        'autoAccept': autoAccept,
        'clickSpeed': '${clickDelayMs}ms',
        'freeRidesUsed': freeUsed,
        'freeRidesLimit': freeLimit,
      };

      final response = await _postJson('$baseUrl/api/telemetry/heartbeat', body);
      if (response != null && response['success'] == true) {
        if (response['free_rides_limit'] != null) {
          final remoteLimit = (response['free_rides_limit'] as num).toInt();
          await FreeRidesService().updateLimit(remoteLimit);
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to dispatch telemetry heartbeat: $e');
      return false;
    }
  }

  /// Record Ride Telemetry Event (Porter, Rapido, Ola, Uber)
  Future<bool> recordRideEvent({
    required String platform,
    required String status, // 'incoming', 'accepted', 'missed', 'rejected'
    double fare = 0.0,
    double distanceKm = 0.0,
    int responseTimeMs = 0,
    String? pickupAddress,
    String? dropAddress,
    String? orderId,
    String? failureReason,
    double? userMinFare,
    double? userMaxFare,
    double? userMaxPickup,
    double? userMaxTrip,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final device = await _deviceInfoService.getDeviceDetails();
      final prefs = await SharedPreferences.getInstance();

      double minF = userMinFare ?? 40.0;
      double maxF = userMaxFare ?? 25000.0;
      double maxP = userMaxPickup ?? 5.0;
      double maxT = userMaxTrip ?? 3000.0;

      if (userMinFare == null) {
        final configJson = prefs.getString('universal_config');
        if (configJson != null) {
          try {
            final map = jsonDecode(configJson);
            if (map is Map<String, dynamic>) {
              minF = (map['minFare'] as num?)?.toDouble() ?? minF;
              maxF = (map['maxFare'] as num?)?.toDouble() ?? maxF;
              maxP = (map['pickupDistance'] as num?)?.toDouble() ?? maxP;
              maxT = (map['tripDistance'] as num?)?.toDouble() ?? maxT;
            }
          } catch (_) {}
        }
      }

      final body = {
        'uid': currentUid,
        'platform': platform.toLowerCase().trim(),
        'status': status.toLowerCase().trim(),
        'fare': fare,
        'distanceKm': distanceKm,
        'responseTimeMs': responseTimeMs,
        'pickupAddress': pickupAddress,
        'dropAddress': dropAddress,
        'orderId': orderId,
        'failureReason': failureReason,
        'userMinFare': minF,
        'userMaxFare': maxF,
        'userMaxPickup': maxP,
        'userMaxTrip': maxT,
        'deviceBrand': device.brand,
        'deviceModel': device.model,
      };

      final response = await _postJson('$baseUrl/api/rides/event', body);
      final ok = response != null && response['success'] == true;
      Logger.log('📍 Ride event recorded: [$platform] $status - ₹$fare (${ok ? "Sent to VPS" : "VPS offline"})');
      return ok;
    } catch (e) {
      Logger.error('Failed to dispatch ride event: $e');
      return false;
    }
  }

  /// Dispatch unhandled Crashlytics exception to VPS Control Engine
  Future<bool> reportCrash({
    required String errorMessage,
    required String stackTrace,
    String? screenName,
    bool isFatal = false,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final device = await _deviceInfoService.getDeviceDetails();

      final body = {
        'uid': currentUid,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'screenName': screenName ?? 'AppRoot',
        'appVersion': '1.0.0',
        'deviceBrand': device.brand,
        'deviceModel': device.model,
        'androidVersion': device.androidVersion,
        'isFatal': isFatal,
      };

      final response = await _postJson('$baseUrl/api/crashes/report', body);
      return response != null && response['success'] == true;
    } catch (e) {
      Logger.error('Crash dispatch failed: $e');
      return false;
    }
  }

  /// Fetch remote application settings (Free rides limit, announcements)
  Future<Map<String, dynamic>?> fetchRemoteConfig() async {
    try {
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/config');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final raw = await response.transform(utf8.decoder).join();
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic> && json['success'] == true) {
          final remoteLimit = (json['free_rides'] ??
              json['freeRidesLimit'] ??
              json['free_rides_limit']) as int?;
          if (remoteLimit != null) {
            await FreeRidesService().updateLimit(remoteLimit);
          }
          return json;
        }
      }
    } catch (e) {
      Logger.error('Failed to fetch remote config from VPS: $e');
    }
    return null;
  }

  /// Helper to send POST request using dart:io HttpClient
  Future<Map<String, dynamic>?> _postJson(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = await response.transform(utf8.decoder).join();
        return jsonDecode(raw) as Map<String, dynamic>?;
      }
    } catch (_) {
      // Offline or network error handled gracefully
    }
    return null;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
