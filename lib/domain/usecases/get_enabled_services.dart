import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case to get only enabled services
class GetEnabledServices {
  final ServiceRepository repository;

  GetEnabledServices(this.repository);

  Future<List<ServiceEntity>> call() async {
    return await repository.getEnabledServices();
  }
}
