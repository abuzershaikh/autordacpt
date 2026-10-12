import 'app_strings.dart';

/// English language strings implementation
class StringsEn extends AppStrings {
  @override
  String get languageCode => 'en';
  @override
  String get languageName => 'English';
  @override
  String get languageNativeName => 'English';

  // Bottom Navigation Tabs
  @override
  String get dashboard => 'Dashboard';
  @override
  String get history => 'History';
  @override
  String get tutorials => 'Tutorials';
  @override
  String get activity => 'Activity';
  @override
  String get profile => 'Profile';

  // Common UI
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get viewAll => 'View All >';
  @override
  String get fixed => 'Fixed';
  @override
  String get linked => 'Linked';
  @override
  String get verified => 'Verified';
  @override
  String get active => 'Active';
  @override
  String get inactive => 'Inactive';
  @override
  String get enabled => 'Enabled';
  @override
  String get disabled => 'Disabled';

  // Dashboard Screen
  @override
  String get autoAccept => 'Auto-Accept';
  @override
  String get enableAccessibilityTitle => 'Enable Accessibility Service';
  @override
  String get enableAccessibilitySubtitle => 'Required for auto-accepting rides';
  @override
  String get openSettings => 'Open Settings >';
  @override
  String get accessibilitySteps => 'Steps: Settings → Accessibility → 🛺 SnapRider → Turn ON';
  @override
  String get fareFilter => 'Fare Filter';
  @override
  String get fareFilterSubtitle => 'Accept rides only within this price range';
  @override
  String get minFare => 'Minimum Fare';
  @override
  String get maxFare => 'Maximum Fare';
  @override
  String get distanceLimit => 'Distance Limit';
  @override
  String get distanceLimitSubtitle => 'Skip orders exceeding these distance limits';
  @override
  String get maxPickupDistance => 'Max Pickup Distance';
  @override
  String get maxTripDistance => 'Max Trip Distance';
  @override
  String get clickerResponseAlerts => 'Clicker Response & Alerts';
  @override
  String get clickerResponseSubtitle => 'Fine-tune auto-accept speed and sounds';
  @override
  String get autoClickSpeed => 'Auto-Click Speed:';
  @override
  String get instant => 'Instant (0ms)';
  @override
  String get fast => 'Fast (80ms)';
  @override
  String get safe => 'Safe (200ms)';
  @override
  String get soundAlert => 'Sound Alert on Accept';
  @override
  String get vibrationFeedback => 'Vibration Feedback';
  @override
  String get applySaveChanges => 'Apply & Save Changes';
  @override
  String get testAutoAccept => 'Test Auto-Accept Event';
  @override
  String get recentAutoAccepts => 'Recent Auto-Accepts';
  @override
  String get autoRide => 'Auto Ride';
  @override
  String get autoAccepted => 'Auto Accepted';
  @override
  String get pickup => 'Pickup';
  @override
  String get trip => 'Trip';

  // History Screen
  @override
  String get rideHistory => 'Ride History';
  @override
  String get totalAcceptedRides => 'Total Accepted Rides';
  @override
  String get faresFiltered => 'Fares Filtered';
  @override
  String get avgSpeed => 'Avg Speed';
  @override
  String get filterAll => 'All Rides';
  @override
  String get filterToday => 'Today';
  @override
  String get filterThisWeek => 'This Week';
  @override
  String get filterAutoAccepted => 'Auto-Accepted';
  @override
  String get noRidesFound => 'No rides found';

  // Activity Screen
  @override
  String get liveActivityTitle => 'Live Activity & Diagnostics';
  @override
  String get accessibilityEngine => 'Accessibility Engine';
  @override
  String get systemMonitor => 'System Monitor';
  @override
  String get diagnosticEvents => 'Diagnostic Events';
  @override
  String get simulateRideEvent => 'Simulate Ride Event';

  // Profile Screen
  @override
  String get myProfile => 'My Profile';
  @override
  String get signOut => 'Sign Out';
  @override
  String get signOutConfirmTitle => 'Sign Out';
  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';
  @override
  String get driverPartner => 'Driver Partner';
  @override
  String get activePlan => 'Active Plan';
  @override
  String get upgradePlan => 'Upgrade Plan';
  @override
  String get freeTrial => 'Free Trial';
  @override
  String get daysLeft => 'days left';
  @override
  String get viewPlans => 'View Plans';
  @override
  String get driverDetails => 'Driver Details';
  @override
  String get driverDetailsSubtitle => 'Registered details linked to your account';
  @override
  String get fullName => 'Full Name';
  @override
  String get googleAccountName => 'Google Account Name';
  @override
  String get mobileNumber => 'Mobile Number';
  @override
  String get registeredPhone => 'Registered Phone';
  @override
  String get appLanguage => 'App Language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get choosePreferredLanguage => 'Choose your preferred language';
  @override
  String get languageChangedSuccess => 'Language updated successfully!';

  // Auth & Setup Screen
  @override
  String get signInWithGoogle => 'Sign in with Google';
  @override
  String get continueAsGuest => 'Continue as Guest Driver >';
  @override
  String get driverSetup => 'Driver Setup';
  @override
  String get completeProfile => 'Complete your driver profile';
  @override
  String get saveAndStart => 'Save & Start Accepting Rides';
}
