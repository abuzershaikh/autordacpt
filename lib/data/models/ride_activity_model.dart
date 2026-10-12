import '../../domain/entities/ride_activity.dart';
import '../../domain/entities/service_type.dart';

/// Ride activity model for JSON serialization
class RideActivityModel {
  final String id;
  final String serviceType;
  final String serviceName;
  final String rideDetails;
  final double fare;
  final double distance;
  final String timestamp;
  final String status;

  const RideActivityModel({
    required this.id,
    required this.serviceType,
    required this.serviceName,
    required this.rideDetails,
    required this.fare,
    required this.distance,
    required this.timestamp,
    required this.status,
  });

  // Convert to Entity
  RideActivity toEntity() {
    return RideActivity(
      id: id,
      serviceType: ServiceType.values.where((e) => e.name == serviceType).firstOrNull ?? ServiceType.service1,
      serviceName: serviceName,
      rideDetails: rideDetails,
      fare: fare,
      distance: distance,
      timestamp: DateTime.parse(timestamp),
      status: RideStatus.values.firstWhere((e) => e.name == status),
    );
  }

  // Create from Entity
  factory RideActivityModel.fromEntity(RideActivity entity) {
    return RideActivityModel(
      id: entity.id,
      serviceType: entity.serviceType.name,
      serviceName: entity.serviceName,
      rideDetails: entity.rideDetails,
      fare: entity.fare,
      distance: entity.distance,
      timestamp: entity.timestamp.toIso8601String(),
      status: entity.status.name,
    );
  }

  // From JSON
  factory RideActivityModel.fromJson(Map<String, dynamic> json) {
    return RideActivityModel(
      id: json['id'] as String,
      serviceType: json['serviceType'] as String,
      serviceName: json['serviceName'] as String,
      rideDetails: json['rideDetails'] as String,
      fare: (json['fare'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      status: json['status'] as String,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'serviceName': serviceName,
      'rideDetails': rideDetails,
      'fare': fare,
      'distance': distance,
      'timestamp': timestamp,
      'status': status,
    };
  }
}
