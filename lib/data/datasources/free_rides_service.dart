import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import 'service_settings_bridge.dart';

class FreeRidesInfo {
  final int limit;
  final int used;
  final bool hasActivePlan;
  final String activePlanName;

  const FreeRidesInfo({
    required this.limit,
    required this.used,
    required this.hasActivePlan,
    required this.activePlanName,
  });

  int get remaining => (limit - used).clamp(0, limit);
  bool get isTrialExpired => !hasActivePlan && used >= limit;
  bool get canAcceptRide => hasActivePlan || used < limit;
}

/// Service to manage free trial rides and dynamic remote VPS configuration.
/// Default: 10 free rides for every user.
/// After free rides are consumed without an active plan, user is prompted to purchase a plan (starting at ₹15).
class FreeRidesService {
  static final FreeRidesService _instance = FreeRidesService._internal();
  factory FreeRidesService() => _instance;
  FreeRidesService._internal();

  static const String keyFreeRidesLimit = 'remote_free_rides_limit';
  static const String keyFreeRidesUsed = 'free_rides_used_count';
  static const String keyVpsEndpoint = 'vps_free_rides_url';
  static const String defaultVpsEndpoint = 'http://139.84.158.149:5000/api/config';
  static const int defaultFreeRidesLimit = 10; // Default 10 free rides
  final ServiceSettingsBridge _bridge = ServiceSettingsBridge();

  /// Get current free rides status
  Future<FreeRidesInfo> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt(keyFreeRidesLimit) ?? defaultFreeRidesLimit;
    final used = prefs.getInt(keyFreeRidesUsed) ?? 0;

    final planStatus = prefs.getString('user_plan_status') ?? 'inactive';
    final planName = prefs.getString('user_plan_name') ?? 'No Active Plan';
    final planId = prefs.getString('user_plan_id') ?? 'none';
    final expiresStr = prefs.getString('user_plan_expires');

    bool hasActivePlan = false;
    if (planStatus == 'active') {
      if (planId == 'lifetime') {
        hasActivePlan = true;
      } else if (expiresStr != null) {
        final expiresAt = DateTime.tryParse(expiresStr);
        if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
          hasActivePlan = true;
        }
      }
    }

    // Sync to Android native bridge
    _bridge.syncFreeRidesStatus(
      hasActivePlan: hasActivePlan,
      freeRidesLimit: limit,
      freeRidesUsed: used,
    );

    return FreeRidesInfo(
      limit: limit,
      used: used,
      hasActivePlan: hasActivePlan,
      activePlanName: hasActivePlan ? planName : 'Free Trial',
    );
  }

  /// Check if user is eligible to auto-accept rides
  Future<bool> canAcceptRide() async {
    final status = await getStatus();
    return status.canAcceptRide;
  }

  /// Increment used rides when a ride is accepted
  Future<void> recordRideAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await getStatus();
    if (!status.hasActivePlan) {
      final currentUsed = prefs.getInt(keyFreeRidesUsed) ?? 0;
      final newUsed = currentUsed + 1;
      await prefs.setInt(keyFreeRidesUsed, newUsed);
      Logger.log('Recorded free ride: $newUsed/${status.limit}');
      await _bridge.syncFreeRidesStatus(
        hasActivePlan: false,
        freeRidesLimit: status.limit,
        freeRidesUsed: newUsed,
      );
    }
  }

  /// Update remote limit (dynamic from VPS or server)
  Future<void> updateLimit(int newLimit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyFreeRidesLimit, newLimit);
    Logger.log('Updated remote free rides limit to: $newLimit');
    final status = await getStatus();
    await _bridge.syncFreeRidesStatus(
      hasActivePlan: status.hasActivePlan,
      freeRidesLimit: newLimit,
      freeRidesUsed: status.used,
    );
  }

  /// Set VPS endpoint URL for dynamic free ride config
  Future<void> setVpsEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyVpsEndpoint, url.trim());
  }

  /// Get current configured VPS endpoint URL
  Future<String?> getVpsEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyVpsEndpoint);
  }

  /// Sync limit dynamically from VPS or remote backend
  /// Supports JSON response: {"free_rides": 10} or {"limit": 10} or plain text number
  Future<int> syncFromVps([String? optionalUrl]) async {
    final prefs = await SharedPreferences.getInstance();
    final url = optionalUrl ?? prefs.getString(keyVpsEndpoint) ?? defaultVpsEndpoint;
    if (url.trim().isEmpty) {
      return prefs.getInt(keyFreeRidesLimit) ?? defaultFreeRidesLimit;
    }

    try {
      final uri = Uri.parse(url.trim());
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        int? remoteLimit;

        try {
          final data = jsonDecode(responseBody);
          if (data is Map<String, dynamic>) {
            remoteLimit = (data['free_rides'] ??
                data['freeRidesLimit'] ??
                data['free_rides_limit'] ??
                data['limit'] ??
                data['freeRides']) as int?;
          } else if (data is int) {
            remoteLimit = data;
          }
        } catch (_) {
          // If response is raw number string e.g. "10"
          remoteLimit = int.tryParse(responseBody.trim());
        }

        if (remoteLimit != null && remoteLimit >= 0) {
          await updateLimit(remoteLimit);
          return remoteLimit;
        }
      }
    } catch (e) {
      Logger.error('Failed to sync dynamic free rides from VPS ($url): $e');
    }

    return prefs.getInt(keyFreeRidesLimit) ?? defaultFreeRidesLimit;
  }
}
