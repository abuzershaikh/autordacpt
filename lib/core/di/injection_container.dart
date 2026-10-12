import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_storage_service.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/usecases/get_all_services.dart';
import '../../domain/usecases/get_enabled_services.dart';
import '../../domain/usecases/get_ride_activities.dart';
import '../../domain/usecases/get_ride_count.dart';
import '../../domain/usecases/save_ride_activity.dart';
import '../../domain/usecases/toggle_service.dart';
import '../../domain/usecases/update_service_settings.dart';
import '../../presentation/providers/service_provider.dart';

/// Dependency Injection Container
class InjectionContainer {
  // Singleton instance
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  // Dependencies
  late SharedPreferences _sharedPreferences;
  late LocalStorageService _localStorageService;
  late ServiceRepository _serviceRepository;
  
  // Use Cases
  late GetAllServices _getAllServices;
  late GetEnabledServices _getEnabledServices;
  late GetRideActivities _getRideActivities;
  late GetRideCount _getRideCount;
  late SaveRideActivity _saveRideActivity;
  late ToggleService _toggleService;
  late UpdateServiceSettings _updateServiceSettings;
  
  // Providers
  late ServiceProvider _serviceProvider;

  /// Initialize all dependencies
  Future<void> init() async {
    // External Dependencies
    _sharedPreferences = await SharedPreferences.getInstance();

    // Data Sources
    _localStorageService = LocalStorageService(_sharedPreferences);

    // Repositories
    _serviceRepository = ServiceRepositoryImpl(_localStorageService);

    // Use Cases
    _getAllServices = GetAllServices(_serviceRepository);
    _getEnabledServices = GetEnabledServices(_serviceRepository);
    _getRideActivities = GetRideActivities(_serviceRepository);
    _getRideCount = GetRideCount(_serviceRepository);
    _saveRideActivity = SaveRideActivity(_serviceRepository);
    _toggleService = ToggleService(_serviceRepository);
    _updateServiceSettings = UpdateServiceSettings(_serviceRepository);

    // Providers
    _serviceProvider = ServiceProvider(_serviceRepository);
  }

  // Getters
  SharedPreferences get sharedPreferences => _sharedPreferences;
  LocalStorageService get localStorageService => _localStorageService;
  ServiceRepository get serviceRepository => _serviceRepository;
  
  GetAllServices get getAllServices => _getAllServices;
  GetEnabledServices get getEnabledServices => _getEnabledServices;
  GetRideActivities get getRideActivities => _getRideActivities;
  GetRideCount get getRideCount => _getRideCount;
  SaveRideActivity get saveRideActivity => _saveRideActivity;
  ToggleService get toggleService => _toggleService;
  UpdateServiceSettings get updateServiceSettings => _updateServiceSettings;
  
  ServiceProvider get serviceProvider => _serviceProvider;
}
