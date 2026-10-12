import '../entities/ride_activity.dart';
import '../repositories/service_repository.dart';

/// Use case to save ride activity
class SaveRideActivity {
  final ServiceRepository repository;

  SaveRideActivity(this.repository);

  Future<void> call(RideActivity activity) async {
    await repository.saveRideActivity(activity);
  }
}
