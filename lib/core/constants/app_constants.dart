/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'AutoRide Accept';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keySelectedServices = 'selected_services';
  static const String keyServiceSettings = 'service_settings';
  static const String keyAcceptedRides = 'accepted_rides';
  static const String keyGlobalRules = 'global_rules';
  
  // Default Values
  static const int defaultMinFare = 50;
  static const int defaultMaxFare = 500;
  static const double defaultPickupDistance = 3.0;
  static const double defaultTripDistance = 15.0;
  
  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}
