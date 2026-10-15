import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/ride_activity.dart';
import '../../domain/repositories/service_repository.dart';
import '../../config/services/service_config.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/local_storage_service.dart';
import '../models/service_model.dart';
import '../models/ride_activity_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Implementation of ServiceRepository
class ServiceRepositoryImpl implements ServiceRepository {
  final LocalStorageService _localStorage;

  ServiceRepositoryImpl(this._localStorage);

  @override
  Future<List<ServiceEntity>> getAllServices() async {
    final savedServices = _localStorage.getJsonList(AppConstants.keySelectedServices);
    final defaultServices = ServiceConfig.getAllServices();
    
    if (savedServices == null) {
      await _saveServices(defaultServices);
      return defaultServices;
    }

    final List<ServiceEntity> validServices = [];
    for (final json in savedServices) {
      try {
        final entity = ServiceModel.fromJson(json).toEntity();
        if (entity != null) {
          validServices.add(entity);
        }
      } catch (_) {}
    }

    // Ensure all default services exist
    for (final def in defaultServices) {
      if (!validServices.any((s) => s.type == def.type)) {
        validServices.add(def);
      }
    }

    await _saveServices(validServices);
    return validServices;
  }

  @override
  Future<ServiceEntity?> getService(ServiceType type) async {
    final services = await getAllServices();
    try {
      return services.firstWhere((s) => s.type == type);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateService(ServiceEntity service) async {
    final services = await getAllServices();
    final index = services.indexWhere((s) => s.type == service.type);
    
    if (index != -1) {
      services[index] = service;
      await _saveServices(services);
    }
  }

  @override
  Future<void> toggleService(ServiceType type, bool enabled) async {
    final service = await getService(type);
    if (service != null) {
      final updatedService = service.copyWith(isEnabled: enabled);
      await updateService(updatedService);
    }
  }

  @override
  Future<void> updateServiceSettings(ServiceType type, ServiceSettings settings) async {
    final service = await getService(type);
    if (service != null) {
      final updatedService = service.copyWith(settings: settings);
      await updateService(updatedService);
    }
  }

  @override
  Future<List<ServiceEntity>> getEnabledServices() async {
    final services = await getAllServices();
    return services.where((s) => s.isEnabled).toList();
  }

  String _getUserStorageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return '${AppConstants.keyAcceptedRides}_$uid';
    }
    return AppConstants.keyAcceptedRides;
  }

  @override
  Future<void> saveRideActivity(RideActivity activity) async {
    final activities = await getRideActivities();
    activities.insert(0, activity); // Add to beginning
    
    final models = activities.map((a) => RideActivityModel.fromEntity(a).toJson()).toList();
    await _localStorage.saveJsonList(_getUserStorageKey(), models);
  }

  @override
  Future<List<RideActivity>> getRideActivities({
    ServiceType? serviceType,
    int? limit,
  }) async {
    await _localStorage.reload();
    final userKey = _getUserStorageKey();
    var savedActivities = _localStorage.getJsonList(userKey);
    // Backward compatibility fallback for pre-migration data
    if ((savedActivities == null || savedActivities.isEmpty) && userKey != AppConstants.keyAcceptedRides) {
      savedActivities = _localStorage.getJsonList(AppConstants.keyAcceptedRides);
    }
    
    if (savedActivities == null) return [];

    var activities = savedActivities
        .map((json) => RideActivityModel.fromJson(json).toEntity())
        .toList();

    // Filter by service type if specified
    if (serviceType != null) {
      activities = activities.where((a) => a.serviceType == serviceType).toList();
    }

    // Limit results if specified
    if (limit != null && activities.length > limit) {
      activities = activities.sublist(0, limit);
    }

    return activities;
  }

  @override
  Future<int> getRideCount(ServiceType type) async {
    final activities = await getRideActivities(serviceType: type);
    return activities.where((a) => a.status == RideStatus.accepted).length;
  }

  @override
  Future<void> clearRideActivities() async {
    await _localStorage.remove(_getUserStorageKey());
    await _localStorage.remove(AppConstants.keyAcceptedRides);
  }

  /// Helper method to save services
  Future<void> _saveServices(List<ServiceEntity> services) async {
    final models = services.map((s) => ServiceModel.fromEntity(s).toJson()).toList();
    await _localStorage.saveJsonList(AppConstants.keySelectedServices, models);
  }
}
