import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/service_entity.dart';

/// Service configuration for supported services (Service 1 & Service 2)
class ServiceConfig {
  /// Get default service entity for a service type
  static ServiceEntity getDefaultService(ServiceType type) {
    return ServiceEntity(
      type: type,
      name: type.displayName,
      packageId: type.packageId,
      category: type.category,
      isEnabled: true, // Enabled by default for auto-detection
      settings: _getDefaultSettings(type),
    );
  }

  /// Get brand color for service
  static Color getBrandColor(ServiceType type) {
    switch (type) {
      case ServiceType.service1:
        return AppColors.service1Color;
      case ServiceType.service2:
        return AppColors.service2Color;
    }
  }

  /// Get icon for service
  static IconData getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.service1:
        return Icons.two_wheeler;
      case ServiceType.service2:
        return Icons.local_shipping;
    }
  }

  /// Get supported vehicle types for service
  static List<VehicleType> getSupportedVehicles(ServiceType type) {
    switch (type) {
      case ServiceType.service1:
        return [VehicleType.bike, VehicleType.auto];
      case ServiceType.service2:
        return [VehicleType.bike, VehicleType.truck, VehicleType.tempo];
    }
  }

  /// Get default settings for service
  static ServiceSettings _getDefaultSettings(ServiceType type) {
    final supportedVehicles = getSupportedVehicles(type);
    
    switch (type) {
      case ServiceType.service1:
        return ServiceSettings(
          autoAccept: true,
          rideFilters: const RideFilters(
            minFare: 50,
            maxFare: 25000,
            pickupDistance: 3.0,
            tripDistance: 3000.0,
          ),
          paymentMethod: PaymentMethod.any,
          vehicleTypes: supportedVehicles,
        );
      
      case ServiceType.service2:
        return ServiceSettings(
          autoAccept: true,
          rideFilters: const RideFilters(
            minFare: 80,
            maxFare: 25000,
            pickupDistance: 4.0,
            tripDistance: 3000.0,
          ),
          paymentMethod: PaymentMethod.any,
          vehicleTypes: supportedVehicles,
        );
    }
  }

  /// Get all available services
  static List<ServiceEntity> getAllServices() {
    return ServiceType.values.map((type) => getDefaultService(type)).toList();
  }
}

