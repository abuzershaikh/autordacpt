import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_type.dart';

/// Service model for JSON serialization
class ServiceModel {
  final String type;
  final String name;
  final String packageId;
  final String category;
  final bool isEnabled;
  final ServiceSettingsModel settings;

  const ServiceModel({
    required this.type,
    required this.name,
    required this.packageId,
    required this.category,
    required this.isEnabled,
    required this.settings,
  });

  // Convert to Entity
  ServiceEntity? toEntity() {
    final matchingType = ServiceType.values.where((e) => e.name == type).firstOrNull;
    if (matchingType == null) return null;
    return ServiceEntity(
      type: matchingType,
      name: name,
      packageId: packageId,
      category: category,
      isEnabled: isEnabled,
      settings: settings.toEntity(),
    );
  }

  // Create from Entity
  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      type: entity.type.name,
      name: entity.name,
      packageId: entity.packageId,
      category: entity.category,
      isEnabled: entity.isEnabled,
      settings: ServiceSettingsModel.fromEntity(entity.settings),
    );
  }

  // From JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      type: json['type'] as String,
      name: json['name'] as String,
      packageId: json['packageId'] as String,
      category: json['category'] as String,
      isEnabled: json['isEnabled'] as bool,
      settings: ServiceSettingsModel.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'packageId': packageId,
      'category': category,
      'isEnabled': isEnabled,
      'settings': settings.toJson(),
    };
  }

  ServiceModel copyWith({
    String? type,
    String? name,
    String? packageId,
    String? category,
    bool? isEnabled,
    ServiceSettingsModel? settings,
  }) {
    return ServiceModel(
      type: type ?? this.type,
      name: name ?? this.name,
      packageId: packageId ?? this.packageId,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      settings: settings ?? this.settings,
    );
  }
}

/// Service settings model
class ServiceSettingsModel {
  final bool autoAccept;
  final RideFiltersModel rideFilters;
  final String paymentMethod;
  final List<String> vehicleTypes;

  const ServiceSettingsModel({
    required this.autoAccept,
    required this.rideFilters,
    required this.paymentMethod,
    required this.vehicleTypes,
  });

  ServiceSettings toEntity() {
    return ServiceSettings(
      autoAccept: autoAccept,
      rideFilters: rideFilters.toEntity(),
      paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == paymentMethod),
      vehicleTypes: vehicleTypes.map((v) => VehicleType.values.firstWhere((e) => e.name == v)).toList(),
    );
  }

  factory ServiceSettingsModel.fromEntity(ServiceSettings entity) {
    return ServiceSettingsModel(
      autoAccept: entity.autoAccept,
      rideFilters: RideFiltersModel.fromEntity(entity.rideFilters),
      paymentMethod: entity.paymentMethod.name,
      vehicleTypes: entity.vehicleTypes.map((v) => v.name).toList(),
    );
  }

  factory ServiceSettingsModel.fromJson(Map<String, dynamic> json) {
    return ServiceSettingsModel(
      autoAccept: json['autoAccept'] as bool,
      rideFilters: RideFiltersModel.fromJson(json['rideFilters'] as Map<String, dynamic>),
      paymentMethod: json['paymentMethod'] as String,
      vehicleTypes: (json['vehicleTypes'] as List<dynamic>).map((v) => v as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoAccept': autoAccept,
      'rideFilters': rideFilters.toJson(),
      'paymentMethod': paymentMethod,
      'vehicleTypes': vehicleTypes,
    };
  }
}

/// Ride filters model
class RideFiltersModel {
  final int minFare;
  final int maxFare;
  final double pickupDistance;
  final double tripDistance;

  const RideFiltersModel({
    required this.minFare,
    required this.maxFare,
    required this.pickupDistance,
    required this.tripDistance,
  });

  RideFilters toEntity() {
    return RideFilters(
      minFare: minFare,
      maxFare: maxFare,
      pickupDistance: pickupDistance,
      tripDistance: tripDistance,
    );
  }

  factory RideFiltersModel.fromEntity(RideFilters entity) {
    return RideFiltersModel(
      minFare: entity.minFare,
      maxFare: entity.maxFare,
      pickupDistance: entity.pickupDistance,
      tripDistance: entity.tripDistance,
    );
  }

  factory RideFiltersModel.fromJson(Map<String, dynamic> json) {
    return RideFiltersModel(
      minFare: json['minFare'] as int,
      maxFare: json['maxFare'] as int,
      pickupDistance: (json['pickupDistance'] as num).toDouble(),
      tripDistance: (json['tripDistance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minFare': minFare,
      'maxFare': maxFare,
      'pickupDistance': pickupDistance,
      'tripDistance': tripDistance,
    };
  }
}
