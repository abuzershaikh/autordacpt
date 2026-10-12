import '../entities/service_type.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case to update service settings
class UpdateServiceSettings {
  final ServiceRepository repository;

  UpdateServiceSettings(this.repository);

  Future<void> call(ServiceType type, ServiceSettings settings) async {
    await repository.updateServiceSettings(type, settings);
  }
}
