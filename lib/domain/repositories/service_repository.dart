import '../entities/service_entity.dart';
import '../entities/service_type.dart';
import '../entities/ride_activity.dart';

/// Abstract repository for service management
abstract class ServiceRepository {
  /// Get all available services
  Future<List<ServiceEntity>> getAllServices();

  /// Get a specific service by type
  Future<ServiceEntity?> getService(ServiceType type);

  /// Update service configuration
  Future<void> updateService(ServiceEntity service);

  /// Toggle service enabled/disabled
  Future<void> toggleService(ServiceType type, bool enabled);

  /// Update service settings
  Future<void> updateServiceSettings(ServiceType type, ServiceSettings settings);

  /// Get enabled services
  Future<List<ServiceEntity>> getEnabledServices();

  /// Save ride activity
  Future<void> saveRideActivity(RideActivity activity);

  /// Get ride activities
  Future<List<RideActivity>> getRideActivities({
    ServiceType? serviceType,
    int? limit,
  });

  /// Get ride count for a service
  Future<int> getRideCount(ServiceType type);

  /// Clear all ride activities
  Future<void> clearRideActivities();
}
