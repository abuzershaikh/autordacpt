import '../entities/service_type.dart';
import '../repositories/service_repository.dart';

/// Use case to get ride count for a specific service
class GetRideCount {
  final ServiceRepository repository;

  GetRideCount(this.repository);

  Future<int> call(ServiceType type) async {
    return await repository.getRideCount(type);
  }
}
