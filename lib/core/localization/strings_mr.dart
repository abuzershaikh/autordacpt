import 'app_strings.dart';

/// Marathi (मराठी) language strings implementation
class StringsMr extends AppStrings {
  @override
  String get languageCode => 'mr';
  @override
  String get languageName => 'Marathi';
  @override
  String get languageNativeName => 'मराठी';

  // Bottom Navigation Tabs
  @override
  String get dashboard => 'डॅशबोर्ड';
  @override
  String get history => 'इतिहास';
  @override
  String get tutorials => 'शिकवणी';
  @override
  String get activity => 'कार्यकलाप';
  @override
  String get profile => 'प्रोफाइल';

  // Common UI
  @override
  String get cancel => 'रद्द करा';
  @override
  String get save => 'सेव्ह करा';
  @override
  String get viewAll => 'सर्व पहा >';
  @override
  String get fixed => 'निश्चित';
  @override
  String get linked => 'जोडलेले';
  @override
  String get verified => 'सत्यापित';
  @override
  String get active => 'सक्रिय';
  @override
  String get inactive => 'निष्क्रिय';
  @override
  String get enabled => 'सुरू';
  @override
  String get disabled => 'बंद';

  // Dashboard Screen
  @override
  String get autoAccept => 'ऑटो-स्वीकार';
  @override
  String get enableAccessibilityTitle => 'अ‍ॅक्सेसिबिलिटी सेवा सुरू करा';
  @override
  String get enableAccessibilitySubtitle => 'राईड्स ऑटो-स्वीकारण्यासाठी आवश्यक आहे';
  @override
  String get openSettings => 'सेटिंग्ज उघडा >';
  @override
  String get accessibilitySteps => 'पायऱ्या: सेटिंग्ज → अ‍ॅक्सेसिबिलिटी → AutoRide Accept 🛺 → सुरू करा';
  @override
  String get fareFilter => 'भाडे फिल्टर';
  @override
  String get fareFilterSubtitle => 'फक्त या भाडे मर्यादेत राईड्स स्वीकारा';
  @override
  String get minFare => 'किमान भाडे';
  @override
  String get maxFare => 'कमाल भाडे';
  @override
  String get distanceLimit => 'अंतर मर्यादा';
  @override
  String get distanceLimitSubtitle => 'या अंतर मर्यादेपेक्षा जास्त ऑर्डर वगळा';
  @override
  String get maxPickupDistance => 'कमाल पिकअप अंतर';
  @override
  String get maxTripDistance => 'कमाल ट्रिप अंतर';
  @override
  String get clickerResponseAlerts => 'क्लिकर प्रतिसाद आणि सूचना';
  @override
  String get clickerResponseSubtitle => 'ऑटो-स्वीकार गती आणि आवाज सेट करा';
  @override
  String get autoClickSpeed => 'ऑटो-क्लिक गती:';
  @override
  String get instant => 'त्वरित (0ms)';
  @override
  String get fast => 'जलद (80ms)';
  @override
  String get safe => 'सुरक्षित (200ms)';
  @override
  String get soundAlert => 'स्वीकारताना आवाज अलर्ट';
  @override
  String get vibrationFeedback => 'व्हायब्रेशन अभिप्राय';
  @override
  String get applySaveChanges => 'बदल लागू आणि सेव्ह करा';
  @override
  String get testAutoAccept => 'ऑटो-स्वीकार चाचणी करा';
  @override
  String get recentAutoAccepts => 'अलीकडील ऑटो-स्वीकृत राईड्स';
  @override
  String get autoRide => 'ऑटो राइड';
  @override
  String get autoAccepted => 'ऑटो स्वीकृत';
  @override
  String get pickup => 'पिकअप';
  @override
  String get trip => 'ट्रिप';

  // History Screen
  @override
  String get rideHistory => 'राईड इतिहास';
  @override
  String get totalAcceptedRides => 'एकूण स्वीकृत राईड्स';
  @override
  String get faresFiltered => 'फिल्टर केलेले भाडे';
  @override
  String get avgSpeed => 'सरासरी गती';
  @override
  String get filterAll => 'सर्व राईड्स';
  @override
  String get filterToday => 'आज';
  @override
  String get filterThisWeek => 'या आठवड्यात';
  @override
  String get filterAutoAccepted => 'ऑटो-स्वीकृत';
  @override
  String get noRidesFound => 'कोणतीही राईड सापडली नाही';

  // Activity Screen
  @override
  String get liveActivityTitle => 'थेट कार्यकलाप आणि निदान';
  @override
  String get accessibilityEngine => 'अ‍ॅक्सेसिबिलिटी इंजिन';
  @override
  String get systemMonitor => 'सिस्टम मॉनिटर';
  @override
  String get diagnosticEvents => 'निदान कार्यक्रम';
  @override
  String get simulateRideEvent => 'सिम्युलेट राईड इव्हेंट';

  // Profile Screen
  @override
  String get myProfile => 'माझे प्रोफाइल';
  @override
  String get signOut => 'साइन आउट';
  @override
  String get signOutConfirmTitle => 'साइन आउट';
  @override
  String get signOutConfirmMessage => 'तुम्हाला नक्की साइन आउट करायचे आहे का?';
  @override
  String get driverPartner => 'चालक भागीदार';
  @override
  String get activePlan => 'सक्रिय प्लॅन';
  @override
  String get upgradePlan => 'प्लॅन अपग्रेड करा';
  @override
  String get freeTrial => 'मोफत चाचणी';
  @override
  String get daysLeft => 'दिवस शिल्लक';
  @override
  String get viewPlans => 'प्लॅन्स पहा';
  @override
  String get driverDetails => 'चालक तपशील';
  @override
  String get driverDetailsSubtitle => 'खात्याशी लिंक केलेले नोंदणीकृत तपशील';
  @override
  String get fullName => 'पूर्ण नाव';
  @override
  String get googleAccountName => 'Google खाते नाव';
  @override
  String get mobileNumber => 'मोबाईल नंबर';
  @override
  String get registeredPhone => 'नोंदणीकृत फोन';
  @override
  String get appLanguage => 'अ‍ॅपची भाषा';
  @override
  String get selectLanguage => 'भाषा निवडा';
  @override
  String get choosePreferredLanguage => 'तुमची आवडती भाषा निवडा';
  @override
  String get languageChangedSuccess => 'भाषा यशस्वीरित्या बदलली!';

  // Auth & Setup Screen
  @override
  String get signInWithGoogle => 'Google द्वारे साइन इन करा';
  @override
  String get continueAsGuest => 'अतिथी चालक म्हणून पुढे जा >';
  @override
  String get driverSetup => 'चालक सेटअप';
  @override
  String get completeProfile => 'तुमचे चालक प्रोफाइल पूर्ण करा';
  @override
  String get saveAndStart => 'सेव्ह करा आणि राईड्स स्वीकारणे सुरू करा';
}
