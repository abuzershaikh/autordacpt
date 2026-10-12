import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/ride_activity.dart';
import '../../domain/entities/universal_config.dart';
import '../../domain/repositories/service_repository.dart';
import '../../data/datasources/service_settings_bridge.dart';
import '../../data/datasources/free_rides_service.dart';

/// Service provider for state management
class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;
  final ServiceSettingsBridge _settingsBridge = ServiceSettingsBridge();
  final FreeRidesService _freeRidesService = FreeRidesService();

  List<ServiceEntity> _services = [];
  List<RideActivity> _recentActivities = [];
  UniversalConfig _universalConfig = const UniversalConfig();
  bool _isLoading = false;
  String? _error;

  ServiceProvider(this._repository) {
    loadServices();
  }

  // Getters
  List<ServiceEntity> get services => _services;
  List<ServiceEntity> get enabledServices => _services.where((s) => s.isEnabled).toList();
  List<RideActivity> get recentActivities => _recentActivities;
  UniversalConfig get universalConfig => _universalConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEnabledServices => _services.any((s) => s.isEnabled);

  /// Load all services
  Future<void> loadServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _repository.getAllServices();
      await _loadUniversalConfig();
      await loadRecentActivities();
      await _syncSettingsToAndroid();
      await _settingsBridge.syncUniversalSettings(_universalConfig.toMap());
      await _freeRidesService.getStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load universal configuration from SharedPreferences
  Future<void> _loadUniversalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('universal_config');
      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        _universalConfig = UniversalConfig.fromMap(map);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading universal config: $e');
      }
    }
  }

  /// Save and apply universal config across all apps
  Future<void> updateUniversalConfig(UniversalConfig config) async {
    try {
      _universalConfig = config;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('universal_config', jsonEncode(config.toMap()));
      await _settingsBridge.syncUniversalSettings(config.toMap());
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle master monitoring / auto-accept
  Future<void> toggleUniversalAutoAccept(bool autoAccept) async {
    final newConfig = _universalConfig.copyWith(autoAccept: autoAccept);
    await updateUniversalConfig(newConfig);
  }

  /// Toggle master enabled
  Future<void> toggleUniversalEnabled(bool isEnabled) async {
    final newConfig = _universalConfig.copyWith(isEnabled: isEnabled);
    await updateUniversalConfig(newConfig);
  }

  /// Toggle service enabled/disabled
  Future<void> toggleService(ServiceType type, bool enabled) async {
    try {
      await _repository.toggleService(type, enabled);
      final index = _services.indexWhere((s) => s.type == type);
      if (index != -1) {
        _services[index] = _services[index].copyWith(isEnabled: enabled);
        await _syncSettingsToAndroid();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update service settings
  Future<void> updateServiceSettings(ServiceType type, ServiceSettings settings) async {
    try {
      await _repository.updateServiceSettings(type, settings);
      final index = _services.indexWhere((s) => s.type == type);
      if (index != -1) {
        _services[index] = _services[index].copyWith(settings: settings);
        await _syncServiceSettingsToAndroid(type, settings);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sync all settings to Android accessibility service
  Future<void> _syncSettingsToAndroid() async {
    try {
      final settingsMap = <String, dynamic>{};
      
      for (final service in _services) {
        final key = service.type.name;
        settingsMap[key] = {
          'isEnabled': service.isEnabled,
          'autoAccept': service.settings.autoAccept,
          'rideFilters': {
            'minFare': service.settings.rideFilters.minFare,
            'maxFare': service.settings.rideFilters.maxFare,
            'pickupDistance': service.settings.rideFilters.pickupDistance,
            'tripDistance': service.settings.rideFilters.tripDistance,
          },
          'paymentMethod': service.settings.paymentMethod.name,
          'vehicleTypes': service.settings.vehicleTypes.map((v) => v.name).toList(),
        };
      }
      await _settingsBridge.syncSettings(settingsMap);
      for (final service in _services) {
        if (settingsMap.containsKey(service.type.name)) {
          await _settingsBridge.updateServiceSettings(service.type.name, settingsMap[service.type.name]!);
        }
      }
    } catch (e) {
      print('Error syncing settings to Android: $e');
    }
  }

  /// Enable all supported services
  Future<void> enableAllServices() async {
    for (final service in _services) {
      await toggleService(service.type, true);
    }
  }

  /// Sync single service settings to Android
  Future<void> _syncServiceSettingsToAndroid(ServiceType type, ServiceSettings settings) async {
    try {
      final settingsMap = {
        'isEnabled': _services.firstWhere((s) => s.type == type).isEnabled,
        'autoAccept': settings.autoAccept,
        'rideFilters': {
          'minFare': settings.rideFilters.minFare,
          'maxFare': settings.rideFilters.maxFare,
          'pickupDistance': settings.rideFilters.pickupDistance,
          'tripDistance': settings.rideFilters.tripDistance,
        },
        'paymentMethod': settings.paymentMethod.name,
        'vehicleTypes': settings.vehicleTypes.map((v) => v.name).toList(),
      };
      
      await _settingsBridge.updateServiceSettings(type.name, settingsMap);
    } catch (e) {
      print('Error syncing ${type.name} settings to Android: $e');
    }
  }

  /// Get a specific service
  ServiceEntity? getService(ServiceType type) {
    try {
      return _services.firstWhere((s) => s.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Save ride activity
  Future<void> saveRideActivity(RideActivity activity) async {
    try {
      await _repository.saveRideActivity(activity);
      _recentActivities.insert(0, activity);
      if (_recentActivities.length > 50) {
        _recentActivities = _recentActivities.sublist(0, 50);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load recent activities
  Future<void> loadRecentActivities() async {
    try {
      _recentActivities = await _repository.getRideActivities(limit: 50);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get ride count for a service
  Future<int> getRideCount(ServiceType type) async {
    try {
      return await _repository.getRideCount(type);
    } catch (e) {
      return 0;
    }
  }

  /// Clear history
  void clearHistory() {
    _recentActivities.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
