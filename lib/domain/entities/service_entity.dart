import 'service_type.dart';

/// Service entity representing a ride/delivery service
class ServiceEntity {
  final ServiceType type;
  final String name;
  final String packageId;
  final String category;
  final bool isEnabled;
  final ServiceSettings settings;

  const ServiceEntity({
    required this.type,
    required this.name,
    required this.packageId,
    required this.category,
    required this.isEnabled,
    required this.settings,
  });

  ServiceEntity copyWith({
    ServiceType? type,
    String? name,
    String? packageId,
    String? category,
    bool? isEnabled,
    ServiceSettings? settings,
  }) {
    return ServiceEntity(
      type: type ?? this.type,
      name: name ?? this.name,
      packageId: packageId ?? this.packageId,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      settings: settings ?? this.settings,
    );
  }
}

/// Settings configuration for each service
class ServiceSettings {
  final bool autoAccept;
  final RideFilters rideFilters;
  final PaymentMethod paymentMethod;
  final List<VehicleType> vehicleTypes;

  const ServiceSettings({
    required this.autoAccept,
    required this.rideFilters,
    required this.paymentMethod,
    required this.vehicleTypes,
  });

  ServiceSettings copyWith({
    bool? autoAccept,
    RideFilters? rideFilters,
    PaymentMethod? paymentMethod,
    List<VehicleType>? vehicleTypes,
  }) {
    return ServiceSettings(
      autoAccept: autoAccept ?? this.autoAccept,
      rideFilters: rideFilters ?? this.rideFilters,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
    );
  }
}

/// Ride filter settings
class RideFilters {
  final int minFare;
  final int maxFare;
  final double pickupDistance;
  final double tripDistance;

  const RideFilters({
    required this.minFare,
    required this.maxFare,
    required this.pickupDistance,
    required this.tripDistance,
  });

  RideFilters copyWith({
    int? minFare,
    int? maxFare,
    double? pickupDistance,
    double? tripDistance,
  }) {
    return RideFilters(
      minFare: minFare ?? this.minFare,
      maxFare: maxFare ?? this.maxFare,
      pickupDistance: pickupDistance ?? this.pickupDistance,
      tripDistance: tripDistance ?? this.tripDistance,
    );
  }
}

/// Payment method enum
enum PaymentMethod {
  any,
  cash,
  upi,
  online;

  String get displayName {
    switch (this) {
      case PaymentMethod.any:
        return 'Any';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.online:
        return 'Online';
    }
  }
}

/// Vehicle type enum
enum VehicleType {
  bike,
  auto,
  cab,
  xl,
  truck,
  tempo;

  String get displayName {
    switch (this) {
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.auto:
        return 'Auto';
      case VehicleType.cab:
        return 'Cab';
      case VehicleType.xl:
        return 'XL';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.tempo:
        return 'Tempo';
    }
  }
}
