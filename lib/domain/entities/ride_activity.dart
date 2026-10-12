import 'service_type.dart';

/// Ride activity entity for tracking accepted rides
class RideActivity {
  final String id;
  final ServiceType serviceType;
  final String serviceName;
  final String rideDetails;
  final double fare;
  final double distance;
  final DateTime timestamp;
  final RideStatus status;

  const RideActivity({
    required this.id,
    required this.serviceType,
    required this.serviceName,
    required this.rideDetails,
    required this.fare,
    required this.distance,
    required this.timestamp,
    required this.status,
  });

  RideActivity copyWith({
    String? id,
    ServiceType? serviceType,
    String? serviceName,
    String? rideDetails,
    double? fare,
    double? distance,
    DateTime? timestamp,
    RideStatus? status,
  }) {
    return RideActivity(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
      rideDetails: rideDetails ?? this.rideDetails,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

/// Ride status enum
enum RideStatus {
  accepted,
  rejected,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.rejected:
        return 'Rejected';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}
