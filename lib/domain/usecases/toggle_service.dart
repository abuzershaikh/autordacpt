import '../entities/service_type.dart';
import '../repositories/service_repository.dart';

/// Use case to toggle service on/off
class ToggleService {
  final ServiceRepository repository;

  ToggleService(this.repository);

  Future<void> call(ServiceType type, bool enabled) async {
    await repository.toggleService(type, enabled);
  }
}
