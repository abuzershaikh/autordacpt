import 'app_strings.dart';

/// Tamil (தமிழ்) language strings implementation
class StringsTa extends AppStrings {
  @override
  String get languageCode => 'ta';
  @override
  String get languageName => 'Tamil';
  @override
  String get languageNativeName => 'தமிழ்';

  // Bottom Navigation Tabs
  @override
  String get dashboard => 'முகப்பு';
  @override
  String get history => 'வரலாறு';
  @override
  String get tutorials => 'டுடோரியல்';
  @override
  String get activity => 'செயல்பாடு';
  @override
  String get profile => 'சுயவிவரம்';

  // Common UI
  @override
  String get cancel => 'ரத்துசெய்';
  @override
  String get save => 'சேமிக்க';
  @override
  String get viewAll => 'அனைத்தும் >';
  @override
  String get fixed => 'நிலையானது';
  @override
  String get linked => 'இணைக்கப்பட்டது';
  @override
  String get verified => 'சரிபார்க்கப்பட்டது';
  @override
  String get active => 'செயலில்';
  @override
  String get inactive => 'செயலற்றது';
  @override
  String get enabled => 'இயக்கப்பட்டது';
  @override
  String get disabled => 'முடக்கப்பட்டது';

  // Dashboard Screen
  @override
  String get autoAccept => 'தானியங்கி ஏற்பு';
  @override
  String get enableAccessibilityTitle => 'அணுகல் சேவையை இயக்குக';
  @override
  String get enableAccessibilitySubtitle => 'சவாரிகளைத் தானாக ஏற்கத் தேவைப்படுகிறது';
  @override
  String get openSettings => 'அமைப்புகளைத் திறக்க >';
  @override
  String get accessibilitySteps => 'படிகள்: அமைப்புகள் → அணுகல்தன்மை → 🛺 SnapRider → இயக்கு';
  @override
  String get fareFilter => 'கட்டண வடிகட்டி';
  @override
  String get fareFilterSubtitle => 'இந்தக் கட்டண வரம்பிற்குள் மட்டுமே சவாரிகளை ஏற்கவும்';
  @override
  String get minFare => 'குறைந்தபட்சக் கட்டணம்';
  @override
  String get maxFare => 'அதிகபட்சக் கட்டணம்';
  @override
  String get distanceLimit => 'தூர வரம்பு';
  @override
  String get distanceLimitSubtitle => 'இந்தத் தூர வரம்பை மீறும் ஆர்டர்களைத் தவிர்க்கவும்';
  @override
  String get maxPickupDistance => 'அதிகபட்ச பிக்கப் தூரம்';
  @override
  String get maxTripDistance => 'அதிகபட்ச பயணத் தூரம்';
  @override
  String get clickerResponseAlerts => 'கிளிக்கர் வேகம் & விழிப்பூட்டல்';
  @override
  String get clickerResponseSubtitle => 'தானியங்கி ஏற்பு வேகம் மற்றும் ஒலிகளை அமைக்கவும்';
  @override
  String get autoClickSpeed => 'தானியங்கி கிளிக் வேகம்:';
  @override
  String get instant => 'உடனடி (0ms)';
  @override
  String get fast => 'வேகமானது (80ms)';
  @override
  String get safe => 'பாதுகாப்பானது (200ms)';
  @override
  String get soundAlert => 'ஏற்கும்போது ஒலி விழிப்பூட்டல்';
  @override
  String get vibrationFeedback => 'அதிர்வு கருத்து';
  @override
  String get applySaveChanges => 'மாற்றங்களைச் சேமிக்கவும்';
  @override
  String get testAutoAccept => 'சோதனை நிகழ்வு';
  @override
  String get recentAutoAccepts => 'சமீபத்திய தானியங்கி சவாரிகள்';
  @override
  String get autoRide => 'ஆட்டோ சவாரி';
  @override
  String get autoAccepted => 'தானாக ஏற்கப்பட்டது';
  @override
  String get pickup => 'பிக்கப்';
  @override
  String get trip => 'பயணம்';

  // History Screen
  @override
  String get rideHistory => 'சவாரி வரலாறு';
  @override
  String get totalAcceptedRides => 'மொத்த சவாரிகள்';
  @override
  String get faresFiltered => 'வடிகட்டிய கட்டணம்';
  @override
  String get avgSpeed => 'சராசரி வேகம்';
  @override
  String get filterAll => 'அனைத்து சவாரிகள்';
  @override
  String get filterToday => 'இன்று';
  @override
  String get filterThisWeek => 'இந்த வாரம்';
  @override
  String get filterAutoAccepted => 'தானாக ஏற்கப்பட்டது';
  @override
  String get noRidesFound => 'சவாரிகள் எதுவும் இல்லை';

  // Activity Screen
  @override
  String get liveActivityTitle => 'நேரலை செயல்பாடு மற்றும் கண்டறிதல்';
  @override
  String get accessibilityEngine => 'அணுகல்தன்மை இயந்திரம்';
  @override
  String get systemMonitor => 'கணினி கண்காணிப்பு';
  @override
  String get diagnosticEvents => 'கண்டறிதல் நிகழ்வுகள்';
  @override
  String get simulateRideEvent => 'சவாரி நிகழ்வை உருவகப்படுத்து';

  // Profile Screen
  @override
  String get myProfile => 'எனது சுயவிவரம்';
  @override
  String get signOut => 'வெளியேறு';
  @override
  String get signOutConfirmTitle => 'வெளியேறு';
  @override
  String get signOutConfirmMessage => 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?';
  @override
  String get driverPartner => 'ஓட்டுநர் கூட்டாளர்';
  @override
  String get activePlan => 'செயலில் உள்ள திட்டம்';
  @override
  String get upgradePlan => 'திட்டத்தை மேம்படுத்து';
  @override
  String get freeTrial => 'இலவச சோதனை';
  @override
  String get daysLeft => 'நாட்கள் மீதம்';
  @override
  String get viewPlans => 'திட்டங்களைக் காண்க';
  @override
  String get driverDetails => 'ஓட்டுநர் விவரங்கள்';
  @override
  String get driverDetailsSubtitle => 'கணக்குடன் இணைக்கப்பட்ட பதிவு விவரங்கள்';
  @override
  String get fullName => 'முழுப் பெயர்';
  @override
  String get googleAccountName => 'Google கணக்கு பெயர்';
  @override
  String get mobileNumber => 'மொபைல் எண்';
  @override
  String get registeredPhone => 'பதிவு செய்யப்பட்ட எண்';
  @override
  String get appLanguage => 'பயன்பாட்டு மொழி';
  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';
  @override
  String get choosePreferredLanguage => 'உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்';
  @override
  String get languageChangedSuccess => 'மொழி வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

  // Auth & Setup Screen
  @override
  String get signInWithGoogle => 'Google உடன் உள்நுழைக';
  @override
  String get continueAsGuest => 'விருந்தினராக தொடரவும் >';
  @override
  String get driverSetup => 'ஓட்டுநர் அமைப்பு';
  @override
  String get completeProfile => 'சுயவிவரத்தை முடிக்கவும்';
  @override
  String get saveAndStart => 'சேமித்து சவாரிகளைத் தொடங்கவும்';
}
