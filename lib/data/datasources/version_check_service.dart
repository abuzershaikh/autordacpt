import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionStatus {
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final bool isBlocked;
  final String currentVersionName;
  final int currentVersionCode;
  final String latestVersionName;
  final int latestVersionCode;
  final String downloadUrl;
  final String updateTitle;
  final String updateMessage;
  final String releaseNotes;

  const AppVersionStatus({
    required this.isUpdateAvailable,
    required this.isForceUpdate,
    required this.isBlocked,
    required this.currentVersionName,
    required this.currentVersionCode,
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.downloadUrl,
    required this.updateTitle,
    required this.updateMessage,
    required this.releaseNotes,
  });

  bool get shouldLockScreen => isBlocked || (isUpdateAvailable && isForceUpdate);

  factory AppVersionStatus.fallback({
    String currentVersionName = '1.0.0',
    int currentVersionCode = 1,
  }) {
    return AppVersionStatus(
      isUpdateAvailable: false,
      isForceUpdate: false,
      isBlocked: false,
      currentVersionName: currentVersionName,
      currentVersionCode: currentVersionCode,
      latestVersionName: currentVersionName,
      latestVersionCode: currentVersionCode,
      downloadUrl: 'http://139.84.158.149:5000/download/latest.apk',
      updateTitle: 'Ride AutoAccept Update',
      updateMessage: 'App is up to date.',
      releaseNotes: '',
    );
  }

  factory AppVersionStatus.fromJson(Map<String, dynamic> json, {
    String currentVersionName = '1.0.0',
    int currentVersionCode = 1,
  }) {
    return AppVersionStatus(
      isUpdateAvailable: json['update_available'] == true,
      isForceUpdate: json['is_force_update'] == true,
      isBlocked: json['is_blocked'] == true,
      currentVersionName: (json['current_version_name'] ?? currentVersionName).toString(),
      currentVersionCode: (json['current_version_code'] is num)
          ? (json['current_version_code'] as num).toInt()
          : currentVersionCode,
      latestVersionName: (json['latest_version_name'] ?? currentVersionName).toString(),
      latestVersionCode: (json['latest_version_code'] is num)
          ? (json['latest_version_code'] as num).toInt()
          : currentVersionCode,
      downloadUrl: (json['download_url'] ?? 'http://139.84.158.149:5000/download/latest.apk').toString(),
      updateTitle: (json['update_title'] ?? 'Naya Update Available').toString(),
      updateMessage: (json['update_message'] ?? 'Kripya naya version download karein.').toString(),
      releaseNotes: (json['release_notes'] ?? '').toString(),
    );
  }
}

class VersionCheckService {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  static const _channel = MethodChannel('com.ride.accept.autorideacceptor/accessibility');
  static const String _defaultVpsHost = 'http://139.84.158.149:5000';

  AppVersionStatus? _cachedStatus;
  AppVersionStatus? get cachedStatus => _cachedStatus;

  /// Check version with VPS control engine
  Future<AppVersionStatus> checkVersion({String? userId, String? deviceId}) async {
    String currentVersionName = '1.0.0';
    int currentVersionCode = 1;

    // 1. Query Android package manager for accurate runtime version info
    try {
      final Map<dynamic, dynamic>? versionMap = await _channel.invokeMethod('getAppVersion');
      if (versionMap != null) {
        currentVersionName = versionMap['versionName']?.toString() ?? '1.0.0';
        currentVersionCode = int.tryParse(versionMap['versionCode']?.toString() ?? '1') ?? 1;
      }
    } catch (e) {
      debugPrint('Error getting native app version: $e');
    }

    // 2. Fetch VPS Endpoint URL from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final vpsEndpoint = prefs.getString('vps_endpoint') ?? _defaultVpsHost;
    final cleanBase = vpsEndpoint.replaceAll(RegExp(r'/api.*$'), '');

    final Uri uri = Uri.parse('$cleanBase/api/version/check').replace(queryParameters: {
      'version_code': currentVersionCode.toString(),
      'version_name': currentVersionName,
      'user_id': userId ?? 'rider_$currentVersionCode',
      'device_id': deviceId ?? 'android_device',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final status = AppVersionStatus.fromJson(
          data,
          currentVersionName: currentVersionName,
          currentVersionCode: currentVersionCode,
        );

        _cachedStatus = status;

        // Sync version blocked state to Android Accessibility Service
        try {
          await _channel.invokeMethod('setVersionBlocked', {'isBlocked': status.shouldLockScreen});
        } catch (_) {}

        return status;
      }
    } catch (e) {
      debugPrint('Version check network warning: $e');
    }

    final fallback = AppVersionStatus.fallback(
      currentVersionName: currentVersionName,
      currentVersionCode: currentVersionCode,
    );
    _cachedStatus = fallback;
    return fallback;
  }

  /// Launch download URL in Chrome / Default Browser
  Future<bool> launchDownloadUrl(String url) async {
    try {
      final cleanUrl = url.trim();
      final bool success = await _channel.invokeMethod('openUrl', {'url': cleanUrl});
      return success;
    } catch (e) {
      debugPrint('Error launching download URL: $e');
      return false;
    }
  }

  /// Check if Battery Optimization is ignored
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool ignored = await _channel.invokeMethod('isBatteryOptimizationIgnored') ?? false;
      return ignored;
    } catch (_) {
      return true;
    }
  }

  /// Request user to disable battery restrictions for 24/7 background work
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final bool opened = await _channel.invokeMethod('requestIgnoreBatteryOptimizations') ?? false;
      return opened;
    } catch (_) {
      return false;
    }
  }
}
