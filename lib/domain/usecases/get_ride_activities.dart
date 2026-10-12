import '../entities/ride_activity.dart';
import '../entities/service_type.dart';
import '../repositories/service_repository.dart';

/// Use case to get ride activities with optional filters
class GetRideActivities {
  final ServiceRepository repository;

  GetRideActivities(this.repository);

  Future<List<RideActivity>> call({
    ServiceType? serviceType,
    int? limit,
  }) async {
    return await repository.getRideActivities(
      serviceType: serviceType,
      limit: limit,
    );
  }
}
