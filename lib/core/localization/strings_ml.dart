import 'app_strings.dart';

/// Malayalam (മലയാളം) language strings implementation
class StringsMl extends AppStrings {
  @override
  String get languageCode => 'ml';
  @override
  String get languageName => 'Malayalam';
  @override
  String get languageNativeName => 'മലയാളം';

  // Bottom Navigation Tabs
  @override
  String get dashboard => 'ഡാഷ്‌ബോർഡ്';
  @override
  String get history => 'ചരിത്രം';
  @override
  String get tutorials => 'ട്യൂട്ടോറിയൽ';
  @override
  String get activity => 'പ്രവർത്തനം';
  @override
  String get profile => 'പ്രൊഫൈൽ';

  // Common UI
  @override
  String get cancel => 'റദ്ദാക്കുക';
  @override
  String get save => 'സേവ് ചെയ്യുക';
  @override
  String get viewAll => 'എല്ലാം കാണുക >';
  @override
  String get fixed => 'സ്ഥിരം';
  @override
  String get linked => 'ലിങ്ക് ചെയ്‌തു';
  @override
  String get verified => 'സ്ഥിരീകരിച്ചു';
  @override
  String get active => 'സജീവം';
  @override
  String get inactive => 'നിഷ്‌ക്രിയം';
  @override
  String get enabled => 'പ്രവർത്തനക്ഷമം';
  @override
  String get disabled => 'പ്രവർത്തനരഹിതം';

  // Dashboard Screen
  @override
  String get autoAccept => 'ഓട്ടോ-സ്വീകരിക്കുക';
  @override
  String get enableAccessibilityTitle => 'ആക്സസിബിലിറ്റി സേവനം ഓണാക്കുക';
  @override
  String get enableAccessibilitySubtitle => 'റൈഡുകൾ സ്വയമേവ സ്വീകരിക്കാൻ ആവശ്യമാണ്';
  @override
  String get openSettings => 'ക്രമീകരണങ്ങൾ തുറക്കുക >';
  @override
  String get accessibilitySteps => 'ഘട്ടങ്ങൾ: ക്രമീകരണങ്ങൾ → ആക്‌സസിബിലിറ്റി → 🛺 SnapRider → ഓണാക്കുക';
  @override
  String get fareFilter => 'നിരക്ക് ഫിൽട്ടർ';
  @override
  String get fareFilterSubtitle => 'ഈ നിരക്ക് പരിധിക്കുള്ളിലെ റൈഡുകൾ മാത്രം സ്വീകരിക്കുക';
  @override
  String get minFare => 'കുറഞ്ഞ നിരക്ക്';
  @override
  String get maxFare => 'കൂടിയ നിരക്ക്';
  @override
  String get distanceLimit => 'ദൂര പരിധി';
  @override
  String get distanceLimitSubtitle => 'ഈ ദൂര പരിധി കവിയുന്ന ഓർഡറുകൾ ഒഴിവാക്കുക';
  @override
  String get maxPickupDistance => 'പരമാവധി പിക്കപ്പ് ദൂരം';
  @override
  String get maxTripDistance => 'പരമാവധി യാത്ര ദൂരം';
  @override
  String get clickerResponseAlerts => 'ക്ലിക്കർ വേഗതയും അലേർട്ടുകളും';
  @override
  String get clickerResponseSubtitle => 'ഓട്ടോ-സ്വീകരിക്കൽ വേഗതയും ശബ്ദവും സജ്ജമാക്കുക';
  @override
  String get autoClickSpeed => 'ഓട്ടോ-ക്ലിക്ക് വേഗത:';
  @override
  String get instant => 'തൽക്ഷണം (0ms)';
  @override
  String get fast => 'വേഗതയേറിയ (80ms)';
  @override
  String get safe => 'സുരക്ഷിതം (200ms)';
  @override
  String get soundAlert => 'സ്വീകരിക്കുമ്പോൾ ശബ്ദ മുന്നറിയിപ്പ്';
  @override
  String get vibrationFeedback => 'വൈബ്രേഷൻ ഫീഡ്‌ബാക്ക്';
  @override
  String get applySaveChanges => 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക';
  @override
  String get testAutoAccept => 'ടെസ്റ്റ് ഇവന്റ്';
  @override
  String get recentAutoAccepts => 'സമീപകാല ഓട്ടോ-റൈഡുകൾ';
  @override
  String get autoRide => 'ഓട്ടോ റൈഡ്';
  @override
  String get autoAccepted => 'ഓട്ടോ സ്വീകരിച്ചു';
  @override
  String get pickup => 'പിക്കപ്പ്';
  @override
  String get trip => 'യാത്ര';

  // History Screen
  @override
  String get rideHistory => 'റൈഡ് ചരിത്രം';
  @override
  String get totalAcceptedRides => 'ആകെ സ്വീകരിച്ച റൈഡുകൾ';
  @override
  String get faresFiltered => 'ഫിൽട്ടർ ചെയ്ത നിരക്ക്';
  @override
  String get avgSpeed => 'ശരാശരി വേഗത';
  @override
  String get filterAll => 'എല്ലാ റൈഡുകളും';
  @override
  String get filterToday => 'ഇന്ന്';
  @override
  String get filterThisWeek => 'ഈ ആഴ്ച';
  @override
  String get filterAutoAccepted => 'ഓട്ടോ-സ്വീകരിച്ചത്';
  @override
  String get noRidesFound => 'റൈഡുകളൊന്നും കണ്ടെത്തിയില്ല';

  // Activity Screen
  @override
  String get liveActivityTitle => 'തത്സമയ പ്രവർത്തനവും രോഗനിർണയവും';
  @override
  String get accessibilityEngine => 'ആക്സസിബിലിറ്റി എഞ്ചിൻ';
  @override
  String get systemMonitor => 'സിസ്റ്റം മോണിറ്റർ';
  @override
  String get diagnosticEvents => 'ഡയഗ്നോസ്റ്റിക് ഇവന്റുകൾ';
  @override
  String get simulateRideEvent => 'റൈഡ് ഇവന്റ് സിമുലേറ്റ് ചെയ്യുക';

  // Profile Screen
  @override
  String get myProfile => 'എന്റെ പ്രൊഫൈൽ';
  @override
  String get signOut => 'സൈൻ ഔട്ട്';
  @override
  String get signOutConfirmTitle => 'സൈൻ ഔട്ട്';
  @override
  String get signOutConfirmMessage => 'തീർച്ചയായും സൈൻ ഔട്ട് ചെയ്യണോ?';
  @override
  String get driverPartner => 'ഡ്രൈവർ പങ്കാളി';
  @override
  String get activePlan => 'സജീവ പ്ലാൻ';
  @override
  String get upgradePlan => 'പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക';
  @override
  String get freeTrial => 'സൗജന്യ ട്രയൽ';
  @override
  String get daysLeft => 'ദിവസങ്ങൾ ബാക്കി';
  @override
  String get viewPlans => 'പ്ലാനുകൾ കാണുക';
  @override
  String get driverDetails => 'ഡ്രൈവർ വിവരങ്ങൾ';
  @override
  String get driverDetailsSubtitle => 'അക്കൗണ്ടുമായി ബന്ധിപ്പിച്ച വിശദാംശങ്ങൾ';
  @override
  String get fullName => 'പൂർണ്ണ നാമം';
  @override
  String get googleAccountName => 'Google അക്കൗണ്ട് പേര്';
  @override
  String get mobileNumber => 'മൊബൈൽ നമ്പർ';
  @override
  String get registeredPhone => 'രജിസ്റ്റർ ചെയ്ത ഫോൺ';
  @override
  String get appLanguage => 'ആപ്പ് ഭാഷ';
  @override
  String get selectLanguage => 'ഭാഷ തിരഞ്ഞെടുക്കുക';
  @override
  String get choosePreferredLanguage => 'നിങ്ങളുടെ ഇഷ്ടപ്പെട്ട ഭാഷ തിരഞ്ഞെടുക്കുക';
  @override
  String get languageChangedSuccess => 'ഭാഷ വിജയകരമായി മാറ്റി!';

  // Auth & Setup Screen
  @override
  String get signInWithGoogle => 'Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക';
  @override
  String get continueAsGuest => 'അതിഥി ഡ്രൈവറായി തുടരുക >';
  @override
  String get driverSetup => 'ഡ്രൈവർ സജ്ജീകരണം';
  @override
  String get completeProfile => 'ഡ്രൈവർ പ്രൊഫൈൽ പൂർത്തിയാക്കുക';
  @override
  String get saveAndStart => 'സേവ് ചെയ്ത് റൈഡുകൾ ആരംഭിക്കുക';
}
