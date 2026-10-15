import 'app_strings.dart';

/// Hindi (हिन्दी) language strings implementation
class StringsHi extends AppStrings {
  @override
  String get languageCode => 'hi';
  @override
  String get languageName => 'Hindi';
  @override
  String get languageNativeName => 'हिन्दी';

  // Bottom Navigation Tabs
  @override
  String get dashboard => 'डैशबोर्ड';
  @override
  String get history => 'इतिहास';
  @override
  String get tutorials => 'ट्यूटोरियल';
  @override
  String get activity => 'गतिविधि';
  @override
  String get profile => 'प्रोफ़ाइल';

  // Common UI
  @override
  String get cancel => 'रद्द करें';
  @override
  String get save => 'सुरक्षित करें';
  @override
  String get viewAll => 'सभी देखें >';
  @override
  String get fixed => 'फिक्स्ड';
  @override
  String get linked => 'लिंक किया गया';
  @override
  String get verified => 'सत्यापित';
  @override
  String get active => 'सक्रिय';
  @override
  String get inactive => 'निष्क्रिय';
  @override
  String get enabled => 'चालू';
  @override
  String get disabled => 'बंद';

  // Dashboard Screen
  @override
  String get autoAccept => 'ऑटो-स्वीकार';
  @override
  String get enableAccessibilityTitle => 'एक्सेसिबिलिटी सेवा चालू करें';
  @override
  String get enableAccessibilitySubtitle => 'राइड्स ऑटो-स्वीकार करने के लिए आवश्यक है';
  @override
  String get openSettings => 'सेटिंग्स खोलें >';
  @override
  String get accessibilitySteps => 'कदम: सेटिंग्स → एक्सेसिबिलिटी → AutoRide Accept 🛺 → चालू करें';
  @override
  String get fareFilter => 'किराया फ़िल्टर';
  @override
  String get fareFilterSubtitle => 'केवल इस किराया सीमा की राइड्स स्वीकार करें';
  @override
  String get minFare => 'न्यूनतम किराया';
  @override
  String get maxFare => 'अधिकतम किराया';
  @override
  String get distanceLimit => 'दूरी सीमा';
  @override
  String get distanceLimitSubtitle => 'इन दूरी सीमाओं से अधिक वाले ऑर्डर छोड़ें';
  @override
  String get maxPickupDistance => 'अधिकतम पिकअप दूरी';
  @override
  String get maxTripDistance => 'अधिकतम ट्रिप दूरी';
  @override
  String get clickerResponseAlerts => 'क्लिकर रिस्पांस और अलर्ट';
  @override
  String get clickerResponseSubtitle => 'ऑटो-स्वीकार स्पीड और आवाज़ सेट करें';
  @override
  String get autoClickSpeed => 'ऑटो-क्लिक स्पीड:';
  @override
  String get instant => 'तुरंत (0ms)';
  @override
  String get fast => 'तेज़ (80ms)';
  @override
  String get safe => 'सुरक्षित (200ms)';
  @override
  String get soundAlert => 'स्वीकार पर आवाज़ अलर्ट';
  @override
  String get vibrationFeedback => 'वाइब्रेशन फ़ीडबैक';
  @override
  String get applySaveChanges => 'बदलाव लागू और सुरक्षित करें';
  @override
  String get testAutoAccept => 'ऑटो-स्वीकार टेस्ट करें';
  @override
  String get recentAutoAccepts => 'हाल की ऑटो-स्वीकृत राइड्स';
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
  String get rideHistory => 'राइड इतिहास';
  @override
  String get totalAcceptedRides => 'कुल स्वीकृत राइड्स';
  @override
  String get faresFiltered => 'फ़िल्टर किया किराया';
  @override
  String get avgSpeed => 'औसत स्पीड';
  @override
  String get filterAll => 'सभी राइड्स';
  @override
  String get filterToday => 'आज';
  @override
  String get filterThisWeek => 'इस सप्ताह';
  @override
  String get filterAutoAccepted => 'ऑटो-स्वीकृत';
  @override
  String get noRidesFound => 'कोई राइड नहीं मिली';

  // Activity Screen
  @override
  String get liveActivityTitle => 'लाइव गतिविधि और निदान';
  @override
  String get accessibilityEngine => 'एक्सेसिबिलिटी इंजन';
  @override
  String get systemMonitor => 'सिस्टम मॉनिटर';
  @override
  String get diagnosticEvents => 'निदान कार्यक्रम';
  @override
  String get simulateRideEvent => 'सिम्युलेट राइड इवेंट';

  // Profile Screen
  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';
  @override
  String get signOut => 'साइन आउट';
  @override
  String get signOutConfirmTitle => 'साइन आउट';
  @override
  String get signOutConfirmMessage => 'क्या आप वाकई साइन आउट करना चाहते हैं?';
  @override
  String get driverPartner => 'ड्राइवर पार्टनर';
  @override
  String get activePlan => 'सक्रिय प्लान';
  @override
  String get upgradePlan => 'प्लान अपग्रेड करें';
  @override
  String get freeTrial => 'मुफ़्त ट्रायल';
  @override
  String get daysLeft => 'दिन बाकी';
  @override
  String get viewPlans => 'प्लान देखें';
  @override
  String get driverDetails => 'ड्राइवर विवरण';
  @override
  String get driverDetailsSubtitle => 'आपके खाते से जुड़े पंजीकृत विवरण';
  @override
  String get fullName => 'पूरा नाम';
  @override
  String get googleAccountName => 'Google खाता नाम';
  @override
  String get mobileNumber => 'मोबाइल नंबर';
  @override
  String get registeredPhone => 'पंजीकृत फ़ोन';
  @override
  String get appLanguage => 'ऐप की भाषा';
  @override
  String get selectLanguage => 'भाषा चुनें';
  @override
  String get choosePreferredLanguage => 'अपनी पसंदीदा भाषा चुनें';
  @override
  String get languageChangedSuccess => 'भाषा सफलतापूर्वक बदली गई!';

  // Auth & Setup Screen
  @override
  String get signInWithGoogle => 'Google से साइन इन करें';
  @override
  String get continueAsGuest => 'अतिथि ड्राइवर के रूप में जारी रखें >';
  @override
  String get driverSetup => 'ड्राइवर सेटअप';
  @override
  String get completeProfile => 'अपनी ड्राइवर प्रोफ़ाइल पूरी करें';
  @override
  String get saveAndStart => 'सुरक्षित करें और राइड्स स्वीकारना शुरू करें';
}
