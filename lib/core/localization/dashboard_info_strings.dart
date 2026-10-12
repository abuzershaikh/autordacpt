import 'package:flutter/material.dart';

/// Data model representing a stylized information card inside the bottom sheet
class InfoCardData {
  final IconData icon;
  final Color accentColor;
  final String tag;
  final String title;
  final String content;
  final String? example;

  const InfoCardData({
    required this.icon,
    required this.accentColor,
    required this.tag,
    required this.title,
    required this.content,
    this.example,
  });
}

/// Data model representing complete content for an Info Bottom Sheet
class DashboardInfoContent {
  final String title;
  final String subtitle;
  final String buttonText;
  final List<InfoCardData> cards;

  const DashboardInfoContent({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.cards,
  });
}

/// Data model representing localized strings for Setting Confirmation Dialog
class ConfirmationDialogStrings {
  final String title;
  final String subtitle;
  final String fareLabel;
  final String pickupLabel;
  final String tripLabel;
  final String note;
  final String cancelBtn;
  final String confirmBtn;
  final String savedToast;

  const ConfirmationDialogStrings({
    required this.title,
    required this.subtitle,
    required this.fareLabel,
    required this.pickupLabel,
    required this.tripLabel,
    required this.note,
    required this.cancelBtn,
    required this.confirmBtn,
    required this.savedToast,
  });
}

/// Central class providing multi-language content for Dashboard (i) Info Sheets.
/// Automatically changes when user switches language in Profile Screen.
/// Supported codes: 'en', 'hi', 'mr', 'ta', 'ml', 'kn'.
class DashboardInfoStrings {
  // ==================== 1. FARE FILTER INFO CONTENT ====================
  static DashboardInfoContent getFareFilterInfo(String langCode) {
    switch (langCode) {
      case 'hi':
        return const DashboardInfoContent(
          title: 'Fare Filter (किराया फ़िल्टर) गाइड',
          subtitle: 'मनपसंद कमाई वाली राइड्स ऑटो-स्वीकार करने का तरीका',
          buttonText: 'समझ गया (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'ऑटो-एक्सेप्ट इंजन',
              title: 'Smart Offer Scanner (0ms स्पीड)',
              content:
                  'जब भी Ola, Uber, Rapido या Porter पर नई राइड स्क्रीन पर आती है, 🛺 SnapRider बिना किसी देरी के 1 मिलीसेकंड में किराया पढ़ लेता है। यदि किराया आपके सेट किए गए Min और Max Fare के बीच है, तो ऐप तुरंत Accept बटन दबा देता है।',
              example:
                  'चलते वाहन में स्क्रीन पर नजर टिकाने की जरूरत नहीं—सिर्फ अच्छी कमाई वाली राइड्स ही अपने-आप बुक हो जाएंगी!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'कम से कम सीमा',
              title: 'Minimum Fare (कम से कम किराया)',
              content:
                  'यह आपकी कमाई की न्यूनतम सीमा तय करता है। अगर आप छोटी ₹20-₹40 वाली घाटे की बुकिंग्स नहीं लेना चाहते, तो इसे ₹80 या ₹100 पर सेट करें। इससे कम किराए की सभी राइड्स ऐप खुद-ब-खुद नजरअंदाज (Skip) कर देगा।',
              example:
                  'उदा. Min Fare = ₹120 रखने पर ₹70 की कोई भी राइड स्वीकार नहीं होगी।',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'अधिकतम सीमा (₹5000 तक)',
              title: 'Maximum Fare (अधिकतम किराया)',
              content:
                  'अब आप अधिकतम किराया पूरे ₹5000 तक सेट कर सकते हैं! यदि आप लंबी दूरी, बड़ी गाड़ियों (Porter Tempo, UberXL) या आउटस्टेशन बुकिंग्स की भारी किराए वाली राइड्स लेना चाहते हैं, तो इसे ₹5000 तक बढ़ाएं।',
              example:
                  'बड़ी बुकिंग्स और मनचाहा मुनाफा कमाने के लिए Max Fare को खुला रखें।',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'ड्राइवर प्रो-टिप',
              title: 'कमाई बढ़ाने की खास रणनीति',
              content:
                  '• पीक आवर्स: Min Fare को बढ़ाएं ताकि केवल मोटी कमाई वाली सर्ज राइड्स ही मिलें।\n• सामान्य समय: Min Fare को संतुलित रखें ताकि गाड़ी खाली न खड़ी रहे।',
              example:
                  'हमेशा अपनी गाड़ी के ईंधन और वापसी के रास्ते को ध्यान में रखकर रेंज सेट करें।',
            ),
          ],
        );

      case 'mr':
        return const DashboardInfoContent(
          title: 'Fare Filter (भाडे फिल्टर) मार्गदर्शक',
          subtitle: 'पसंतीची जास्त कमाई देणारी राइड्स ऑटो-स्वीकारण्याची पद्धत',
          buttonText: 'समजले (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'ऑटो-स्वीकृती इंजिन',
              title: 'Smart Offer Scanner (0ms वेग)',
              content:
                  'जेव्हा Ola, Uber, Rapido किंवा Porter वर नवीन राइड स्क्रीनवर येते, 🛺 SnapRider एका मिलीसेकंदात भाडे वाचतो. भाडे तुमच्या Min आणि Max मधील असल्यास, ॲप लगेच Accept बटण दाबतो.',
              example:
                  'गाडी चालवताना फोन बघायची गरज नाही—फक्त फायद्याच्या राइड्स आपोआप बुक होतील!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'किमान मर्यादा',
              title: 'Minimum Fare (कमीत कमी भाडे)',
              content:
                  'हे तुमच्या कमाईची किमान मर्यादा ठरवते. लहान ₹20-₹40 च्या तोट्याच्या फेऱ्या टाळण्यासाठी Min Fare ₹80 किंवा ₹100 सेट करा. कमी भाड्याच्या सर्व फेऱ्या ॲप आपोआप सोडून देईल.',
              example:
                  'उदा. Min Fare = ₹120 ठेवल्यास ₹70 ची कोणतीही राइड स्वीकारली जाणार नाही.',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'कमाल मर्यादा (₹5000 पर्यंत)',
              title: 'Maximum Fare (जास्त भाड्याच्या बुकिंग्स)',
              content:
                  'आता तुम्ही कमाल भाडे ₹5000 पर्यंत ठेवू शकता! लांब पल्ल्याच्या किंवा मोठ्या वाहनांसाठी (Porter Tempo, UberXL) जास्त कमाई मिळवण्यासाठी हे उपयुक्त आहे.',
              example:
                  'मोठ्या बुकिंग्स आणि जास्त नफ्यासाठी Max Fare मोकळा ठेवा.',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'ड्रायव्हर प्रो-टिप',
              title: 'कमाई वाढवण्याची रणनीती',
              content:
                  '• पीक अवर्स: सर्ज राइड्स मिळवण्यासाठी Min Fare वाढवा.\n• सामान्य वेळ: गाडी मोकळी उभी न राहण्यासाठी Min Fare संतुलित ठेवा.',
              example:
                  'वाहनाचे इंधन आणि परतीचा मार्ग लक्षात घेऊनच रेंज सेट करा.',
            ),
          ],
        );

      case 'ta':
        return const DashboardInfoContent(
          title: 'Fare Filter (கட்டண வடிகட்டி) வழிகாட்டி',
          subtitle: 'உங்களுக்கு விருப்பமான அதிக வருமான சவாரிகளை தானாக ஏற்கும் முறை',
          buttonText: 'புரிந்தது (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'தானியங்கி ஏற்பு எஞ்சின்',
              title: 'Smart Offer Scanner (0ms வேகம்)',
              content:
                  'Ola, Uber, Rapido அல்லது Porter-ல் புதிய சவாரி திரையில் வரும்போது, 🛺 SnapRider 1 மில்லி வினாடியில் கட்டணத்தைப் படிக்கும். உங்கள் Min மற்றும் Max வரம்பிற்குள் இருந்தால், உடனே Accept பொத்தானை அழுத்தும்.',
              example:
                  'வாகனம் ஓட்டும்போது திரையைப் பார்க்கத் தேவையில்லை—லாபகரமான சவாரிகள் மட்டுமே தானாக புக் ஆகும்!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'குறைந்தபட்ச வரம்பு',
              title: 'Minimum Fare (குறைந்தபட்ச கட்டணம்)',
              content:
                  'இது உங்கள் குறைந்தபட்ச வருமானத்தை நிர்ணயிக்கிறது. நஷ்டம் தரும் ₹20-₹40 சவாரிகளைத் தவிர்க்க, Min Fare-ஐ ₹80 அல்லது ₹100 என வைக்கவும். குறைவான கட்டண சவாரிகள் தவிர்க்கப்படும்.',
              example:
                  'எ.கா. Min Fare = ₹120 வைத்தால் ₹70 கட்டண சவாரி ஏற்கப்படாது.',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'அதிகபட்ச வரம்பு (₹5000 வரை)',
              title: 'Maximum Fare (அதிகபட்ச கட்டணம்)',
              content:
                  'இப்போது அதிகபட்ச கட்டணத்தை ₹5000 வரை அமைக்கலாம்! நீண்ட தூரம், வெளிமாவட்டம் அல்லது Porter/UberXL போன்ற பெரிய வாகனங்களின் அதிக வருமான சவாரிகளுக்கு சிறந்தது.',
              example:
                  'அதிக வருமானம் தரும் சவாரிகளை உடனடியாகப் பிடிக்க Max Fare-ஐ அதிகமாக வைக்கவும்.',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'ஓட்டுநர் குறிப்பு',
              title: 'வருமானத்தை அதிகரிக்கும் உத்தி',
              content:
                  '• பீக் நேரம்: சர்ஜ் கட்டண சவாரிகளைப் பிடிக்க Min Fare-ஐ உயர்த்தவும்.\n• சாதாரண நேரம்: வண்டி சும்மா நிற்காமல் இருக்க Min Fare-ஐ மிதமாக வைக்கவும்.',
              example:
                  'வாகன எரிபொருள் மற்றும் திரும்பும் வழியை மனதில் வைத்து வரம்பை அமைக்கவும்.',
            ),
          ],
        );

      case 'ml':
        return const DashboardInfoContent(
          title: 'Fare Filter (നിരക്ക് ഫിൽട്ടർ) ഗൈഡ്',
          subtitle: 'കൂടുതൽ വരുമാനമുള്ള റൈഡുകൾ സ്വയമേവ സ്വീകരിക്കുന്ന വിധം',
          buttonText: 'മനസ്സിലായി (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'ഓട്ടോ-ആക്സെപ്റ്റ് എഞ്ചിൻ',
              title: 'Smart Offer Scanner (0ms വേഗത)',
              content:
                  'Ola, Uber, Rapido അല്ലെങ്കിൽ Porter-ൽ പുതിയ റൈഡ് സ്ക്രീനിൽ വരുമ്പോൾ, 🛺 SnapRider 1 മില്ലിസെക്കൻഡിൽ നിരക്ക് വായിക്കും. നിങ്ങളുടെ Min, Max പരിധിക്കുള്ളിലാണെങ്കിൽ ഉടൻ Accept ചെയ്യും.',
              example:
                  'വാഹനം ഓടിക്കുമ്പോൾ സ്ക്രീനിൽ നോക്കേണ്ടതില്ല—ലാഭകരമായ റൈഡുകൾ മാത്രം ഓട്ടോമാറ്റിക്കായി ബുക്ക് ആകും!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'കുറഞ്ഞ പരിധി',
              title: 'Minimum Fare (കുറഞ്ഞ നിരക്ക്)',
              content:
                  'ഇത് നിങ്ങളുടെ കുറഞ്ഞ വരുമാന പരിധി നിശ്ചയിക്കുന്നു. നഷ്ടമുണ്ടാക്കുന്ന ₹20-₹40 റൈഡുകൾ ഒഴിവാക്കാൻ Min Fare ₹80 അല്ലെങ്കിൽ ₹100 ആയി സജ്ജീകരിക്കുക. കുറഞ്ഞ നിരക്കുകൾ ഒഴിവാക്കപ്പെടും.',
              example:
                  'ഉദാ. Min Fare = ₹120 ആക്കിയാൽ ₹70 നിരക്കുള്ള റൈഡ് സ്വീകരിക്കില്ല.',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'പരമാവധി പരിധി (₹5000 വരെ)',
              title: 'Maximum Fare (ഉയർന്ന നിരക്ക് ബുക്കിംഗുകൾ)',
              content:
                  'ഇപ്പോൾ നിങ്ങൾക്ക് പരമാവധി നിരക്ക് ₹5000 വരെ സജ്ജീകരിക്കാം! ദീർഘദൂര യാത്രകൾക്കും Porter, UberXL പോലുള്ള വലിയ വാഹനങ്ങൾക്കും അനുയോജ്യമാണ്.',
              example:
                  'വലിയ ബുക്കിംഗുകൾ നേടാൻ Max Fare ആവശ്യാനുസരണം വർദ്ധിപ്പിക്കുക.',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'ഡ്രൈവർ പ്രോ-ടിപ്പ്',
              title: 'വരുമാനം വർദ്ധിപ്പിക്കാനുള്ള തന്ത്രം',
              content:
                  '• തിരക്കുള്ള സമയം: സർജ് നിരക്കുകൾ ലഭിക്കാൻ Min Fare കൂട്ടുക.\n• സാധാരണ സമയം: വാഹനം വെറുതെ കിടക്കാതിരിക്കാൻ Min Fare മിതമായി വെയ്ക്കുക.',
              example:
                  'വാഹനത്തിന്റെ ഇന്ധനവും തിരിച്ചുവരവും കണക്കിലെടുത്ത് റേഞ്ച് സജ്ജീകരിക്കുക.',
            ),
          ],
        );

      case 'kn':
        return const DashboardInfoContent(
          title: 'Fare Filter (ದರ ಫಿಲ್ಟರ್) ಮಾರ್ಗದರ್ಶಿ',
          subtitle: 'ಹೆಚ್ಚಿನ ಆದಾಯದ ರೈಡ್‌ಗಳನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಸ್ವೀಕರಿಸುವ ವಿಧಾನ',
          buttonText: 'ಅರ್ಥವಾಯಿತು (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'ಸ್ವಯಂಚಾಲಿತ ಸ್ವೀಕಾರ ಎಂಜಿನ್',
              title: 'Smart Offer Scanner (0ms ವೇಗ)',
              content:
                  'Ola, Uber, Rapido ಅಥವಾ Porter ನಲ್ಲಿ ಹೊಸ ರೈಡ್ ಪರದೆಯ ಮೇಲೆ ಬಂದಾಗ, 🛺 SnapRider 1 ಮಿಲಿಸೆಕೆಂಡ್‌ನಲ್ಲಿ ದರವನ್ನು ಓದುತ್ತದೆ. ನಿಮ್ಮ Min ಮತ್ತು Max ವ್ಯಾಪ್ತಿಯಲ್ಲಿದ್ದರೆ, ತಕ್ಷಣ Accept ಕ್ಲಿಕ್ ಮಾಡುತ್ತದೆ.',
              example:
                  'ವಾಹನ ಚಲಾಯಿಸುವಾಗ ಮೊಬೈಲ್ ನೋಡಬೇಕಾಗಿಲ್ಲ—ಲಾಭದಾಯಕ ರೈಡ್‌ಗಳು ಮಾತ್ರ ತಾನಾಗಿಯೇ ಬುಕ್ ಆಗುತ್ತವೆ!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'ಕನಿಷ್ಠ ಮಿತಿ',
              title: 'Minimum Fare (ಕನಿಷ್ಠ ದರ)',
              content:
                  'ಇದು ನಿಮ್ಮ ಕನಿಷ್ಠ ಆದಾಯ ಮಿತಿಯನ್ನು ನಿರ್ಧರಿಸುತ್ತದೆ. ನಷ್ಟದ ₹20-₹40 ಚಿಕ್ಕ ರೈಡ್‌ಗಳನ್ನು ತಪ್ಪಿಸಲು Min Fare ಅನ್ನು ₹80 ಅಥವಾ ₹100 ಕ್ಕೆ ಹೊಂದಿಸಿ. ಕಡಿಮೆ ದರದ ರೈಡ್‌ಗಳನ್ನು ಆಪ್ ಬಿಟ್ಟುಬಿಡುತ್ತದೆ.',
              example:
                  'ಉದಾ. Min Fare = ₹120 ಇಟ್ಟರೆ ₹70 ರ ರೈಡ್ ಸ್ವೀಕಾರವಾಗುವುದಿಲ್ಲ.',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'ಗರಿಷ್ಠ ಮಿತಿ (₹5000 ವರೆಗೆ)',
              title: 'Maximum Fare (ಹೆಚ್ಚಿನ ದರದ ಬುಕಿಂಗ್‌ಗಳು)',
              content:
                  'ಈಗ ನೀವು ಗರಿಷ್ಠ ದರವನ್ನು ₹5000 ವರೆಗೆ ಹೊಂದಿಸಬಹುದು! ದೂರದ ಪ್ರಯಾಣ ಹಾಗೂ Porter/UberXL ನಂತಹ ವಾಹನಗಳ ಹೆಚ್ಚಿನ ಗಳಿಕೆಗೆ ಇದು ಸೂಕ್ತವಾಗಿದೆ.',
              example:
                  'ಹೆಚ್ಚಿನ ಆದಾಯದ ಬುಕಿಂಗ್‌ಗಳನ್ನು ಪಡೆಯಲು Max Fare ಅನ್ನು ಹೆಚ್ಚಾಗಿರಿಸಿ.',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'ಚಾಲಕರ ಪ್ರಮುಖ ಸಲಹೆ',
              title: 'ಗಳಿಕೆ ಹೆಚ್ಚಿಸುವ ತಂತ್ರ',
              content:
                  '• ಪೀಕ್ ಅವರ್‌ಗಳು: ಸರ್ಜ್ ದರದ ರೈಡ್‌ಗಳನ್ನು ಪಡೆಯಲು Min Fare ಹೆಚ್ಚಿಸಿ.\n• ಸಾಮಾನ್ಯ ಸಮಯ: ವಾಹನ ಸುಮ್ಮನೆ ನಿಲ್ಲದಂತೆ Min Fare ಅನ್ನು ಸಮತೋಲನದಲ್ಲಿರಿಸಿ.',
              example:
                  'ವಾಹನದ ಇಂಧನ ಮತ್ತು ಹಿಂದಿರುಗುವ ಮಾರ್ಗವನ್ನು ಗಮನದಲ್ಲಿಟ್ಟುಕೊಂಡು ಸೆಟ್ ಮಾಡಿ.',
            ),
          ],
        );

      case 'en':
      default:
        return const DashboardInfoContent(
          title: 'Fare Filter Guide',
          subtitle: 'How to auto-accept your preferred high-earning rides',
          buttonText: 'Got It',
          cards: [
            InfoCardData(
              icon: Icons.flash_on_rounded,
              accentColor: Color(0xFF00A84D),
              tag: 'Auto-Accept Engine',
              title: 'Smart Offer Scanner (0ms Speed)',
              content:
                  'Whenever a new ride offer appears on Ola, Uber, Rapido, or Porter, 🛺 SnapRider reads the fare in 1 millisecond. If the fare falls within your Min and Max Fare range, it instantly clicks Accept.',
              example:
                  'No need to look at your phone while driving—only profitable rides are booked automatically!',
            ),
            InfoCardData(
              icon: Icons.arrow_downward_rounded,
              accentColor: Color(0xFF16A34A),
              tag: 'Minimum Threshold',
              title: 'Minimum Fare (Loss Prevention)',
              content:
                  'This sets the lowest fare you are willing to accept. If you want to avoid tiny unprofitable ₹20-₹40 rides, set Min Fare to ₹80 or ₹100. The app will automatically ignore/skip lower rides.',
              example:
                  'E.g., If Min Fare is ₹120, no ride paying ₹70 will ever be accepted.',
            ),
            InfoCardData(
              icon: Icons.currency_rupee_rounded,
              accentColor: Color(0xFF0284C7),
              tag: 'Maximum Limit (Up to ₹5000)',
              title: 'Maximum Fare (High-Value Bookings)',
              content:
                  'Now you can set your maximum fare up to ₹5000! Ideal for long-distance, outstation, or commercial vehicles (Porter Tempo, UberXL) seeking premium earnings.',
              example:
                  'Keep Max Fare high to capture high-paying bookings with zero delay.',
            ),
            InfoCardData(
              icon: Icons.tips_and_updates_rounded,
              accentColor: Color(0xFFD97706),
              tag: 'Driver Pro-Tip',
              title: 'Earning Maximization Strategy',
              content:
                  '• Peak Hours: Increase Min Fare to catch surge-priced rides.\n• Normal Hours: Keep Min Fare moderate so your vehicle stays active without empty wait time.',
              example:
                  'Always set your fare range considering your vehicle fuel and return route.',
            ),
          ],
        );
    }
  }

  // ==================== 2. DISTANCE LIMIT INFO CONTENT ====================
  static DashboardInfoContent getDistanceLimitInfo(String langCode) {
    switch (langCode) {
      case 'hi':
        return const DashboardInfoContent(
          title: 'Distance Limit (दूरी सीमा) गाइड',
          subtitle: 'पिकअप व ट्रिप दूरी से ईंधन और समय बचाने का तरीका',
          buttonText: 'समझ गया (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'कस्टमर तक की दूरी',
              title: 'Max Pickup Distance (पिकअप दूरी सीमा)',
              content:
                  'यह तय करता है कि राइडर/कस्टमर आपसे कितनी दूर तक का होना चाहिए।\n\n• ऐप कैसे काम करता है: नई राइड आने पर 🛺 SnapRider स्क्रीन पर तुरंत चेक करता है कि कस्टमर आपसे कितने किलोमीटर दूर है। अगर दूरी आपकी सेट की गई सीमा (जैसे 3 km) से ज़्यादा है, तो ऐप उस राइड को तुरंत छोड़ देगा।\n• क्यों जरूरी है: कई बार 6-8 किमी दूर का पिकअप मिलता है जिसमें पहुंचने का पेट्रोल/समय व्यर्थ जाता है और कस्टमर कैंसिल भी कर देता है। यह सेटिंग आपको खाली दौड़ (Dead Mileage) से बचाती है।',
              example:
                  'सुझाव: शहर के अंदर पिकअप दूरी 2 से 4 km रखें ताकि 5-10 मिनट में पिकअप हो सके।',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'ड्रॉप दूरी (300 km तक)',
              title: 'Max Trip Distance (ट्रिप / ड्रॉप दूरी सीमा)',
              content:
                  'यह पिकअप पॉइंट से ड्रॉप लोकेशन तक की कुल दूरी तय करता है।\n\n• अब 300 KM तक की रेंज: अगर आप सिर्फ लोकल शहर में रहना चाहते हैं तो 15-25 km रखें। यदि आप इंटरसिटी, आउटस्टेशन, या Porter में दूसरे शहर का माल/सवारी ले जाते हैं, तो इसे पूरे 300 km तक सेट कर सकते हैं!\n• ऐप कैसे काम करता है: स्क्रीन पर ट्रिप दूरी चेक की जाती है। यदि ट्रिप आपके KM लिमिट के भीतर है, तो 0ms में राइड कन्फर्म हो जाती है।',
              example:
                  'आउटस्टेशन या लंबी दूरी की बुकिंग्स के लिए इसे 100 km से 300 km तक सेट करें।',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'सही संतुलन (Smart Strategy)',
              title: 'दूरी और कमाई का बेहतरीन तालमेल',
              content:
                  '• ऑटो व बाइक राइडर्स: Max Pickup 2.5 km और Trip Distance 20 km रखें। कम पेट्रोल में ज्यादा लोकल ट्रिप्स होंगी।\n• कैब व कमर्शियल वाहन: Max Pickup 5.0 km और Trip Distance 100-300 km रखें ताकि बड़ी आउटस्टेशन बुकिंग्स हाथ से न छूटें।',
              example:
                  'यह दोनों सेटिंग्स मिलकर आपको कैंसलेशन पेनाल्टी और ईंधन के नुकसान से 100% सुरक्षित रखती हैं।',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'शत-प्रतिशत सुरक्षा',
              title: 'गलत राइड्स से परमानेंट छुटकारा',
              content:
                  '🛺 SnapRider केवल उन्हीं राइड्स को स्वीकार करता है जो आपके सेट किए गए सभी नियमों (Fare + Pickup + Trip) पर 100% फिट बैठती हैं। आपको अनचाही राइड्स कैंसिल करने की नौबत नहीं आएगी और आपकी रेटिंग हमेशा सुरक्षित रहेगी।',
              example:
                  'आराम से ड्राइव करें, बाकी सारा काम SnapRider की स्पीड पर छोड़ दें!',
            ),
          ],
        );

      case 'mr':
        return const DashboardInfoContent(
          title: 'Distance Limit (अंतर मर्यादा) मार्गदर्शक',
          subtitle: 'पिकअप आणि ट्रिप अंतरामुळे इंधन व वेळ वाचवण्याची पद्धत',
          buttonText: 'समजले (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'ग्राहकापर्यंतचे अंतर',
              title: 'Max Pickup Distance (पिकअप अंतर मर्यादा)',
              content:
                  'हे ठरवते की ग्राहक तुमच्यापासून किती लांब असावा.\n\n• ॲप कसे काम करते: नवीन राइड आल्यावर 🛺 SnapRider अंतर तपासतो. जर अंतर मर्यादेपेक्षा जास्त असेल (उदा. ३ किमी), तर ॲप ती राइड त्वरित सोडतो.\n• का आवश्यक: लांबच्या ६-८ किमी पिकअपमध्ये होणारा पेट्रोल आणि वेळेचा अपव्यय थांबवते.',
              example:
                  'टीप: शहरात जलद पिकअपसाठी अंतर २ ते ४ किमी ठेवा.',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'ड्रॉप अंतर (३०० किमी पर्यंत)',
              title: 'Max Trip Distance (ट्रिप / ड्रॉप अंतर मर्यादा)',
              content:
                  'हे पिकअपपासून ड्रॉपपर्यंतचे एकूण अंतर ठरवते.\n\n• आता ३०० किमी पर्यंत: स्थानिक शहरासाठी १५-२५ किमी ठेवा. Porter किंवा लांबच्या प्रवासासाठी ३०० किमी पर्यंत वाढवा!\n• ॲप कसे काम करते: स्क्रीनवरील अंतर मर्यादेत असल्यास 0ms मध्ये राइड कन्फर्म होते.',
              example:
                  'लांब पल्ल्याच्या बुकिंग्ससाठी १०० ते ३०० किमी सेट करा.',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'स्मार्ट रणनीती',
              title: 'अंतर आणि कमाईचा समतोल',
              content:
                  '• ऑटो आणि बाइक: Max Pickup २.५ किमी, Trip २० किमी ठेवा.\n• टॅक्सी आणि व्यावसायिक: Max Pickup ५ किमी, Trip १००-३०० किमी ठेवा.',
              example:
                  'यामुळे कॅन्सलेशन पेनल्टी आणि इंधनाचे नुकसान टळते.',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'पूर्ण सुरक्षा',
              title: 'चुकीच्या राइड्सपासून कायमची मुक्ती',
              content:
                  '🛺 SnapRider फक्त तुमच्या नियमांनुसार बसणाऱ्या राइड्स स्वीकारतो. सुरक्षित गाडी चालवा आणि बाकी काम SnapRider वर सोडा!',
              example:
                  'निश्चिंत होऊन गाडी चालवा, ॲप वेगाने काम करेल!',
            ),
          ],
        );

      case 'ta':
        return const DashboardInfoContent(
          title: 'தொலைவு வரம்பு (Distance Limit) வழிகாட்டி',
          subtitle: 'பிக்கப் மற்றும் பயண தூர விதிகள் மூலம் எரிபொருள், நேரத்தை சேமிக்கவும்',
          buttonText: 'புரிந்தது (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'வாடிக்கையாளர் பிக்கப்',
              title: 'Max Pickup Distance (பிக்கப் தூர வரம்பு)',
              content:
                  'வாடிக்கையாளர் உங்களிடமிருந்து எவ்வளவு தூரத்தில் இருக்கலாம் என்பதை இது நிர்ணயிக்கிறது.\n\n• செயல்பாடு: சவாரி வந்ததும் SnapRider பிக்கப் தூரத்தைச் சரிபார்க்கும். வரம்பை விட அதிகமாக இருந்தால் சவாரியைத் தவிர்க்கும்.\n• முக்கியத்துவம்: 6-8 கிமீ தொலைவு சென்று பெட்ரோல் வீணாவதையும், வாடிக்கையாளர் ரத்து செய்வதையும் தடுக்கும்.',
              example:
                  'குறிப்பு: நகர்ப்புறங்களில் 5-10 நிமிடங்களில் பிக்கப் செய்ய 2 முதல் 4 கிமீ வரை வைக்கவும்.',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'டிராப் தூரம் (300 கிமீ வரை)',
              title: 'Max Trip Distance (பயண தூர வரம்பு)',
              content:
                  'பிக்கப் முதல் டிராப் வரையிலான மொத்த தூரத்தை இது குறிக்கிறது.\n\n• 300 கிமீ வரை வரம்பு: உள்ளூர் நகரத்திற்கு 15-25 கிமீ வைக்கவும். வெளிமாவட்டம் அல்லது Porter சரக்கு வாகனங்களுக்கு 300 கிமீ வரை விரிவுபடுத்தலாம்!\n• செயல்பாடு: பயண தூரத்தைக் கணக்கிட்டு உடனே ஏற்கும்.',
              example:
                  'வெளிமாவட்ட சவாரிகளுக்கு 100 முதல் 300 கிமீ வரை அமைக்கவும்.',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'ஸ்மார்ட் உத்தி',
              title: 'தூரமும் வருமானமும் சமநிலை',
              content:
                  '• ஆட்டோ & பைக்: பிக்கப் 2.5 கிமீ, பயணம் 20 கிமீ.\n• கார் & வணிக வண்டி: பிக்கப் 5 கிமீ, பயணம் 100-300 கிமீ.',
              example:
                  'இது ரத்து அபராதம் மற்றும் எரிபொருள் இழப்பிலிருந்து முழுமையாக பாதுகாக்கும்.',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'முழு தானியங்கி பாதுகாப்பு',
              title: 'தவறான சவாரிகள் இல்லை, முழு பாதுகாப்பு',
              content:
                  '🛺 SnapRider உங்கள் விதிகளுக்கு பொருந்தும் சவாரிகளை மட்டுமே ஏற்கும். நீங்கள் பாதுகாப்பாக ஓட்டுங்கள், மீதியை SnapRider பார்த்துக் கொள்ளும்!',
              example:
                  'மன அமைதியுடன் வாகனம் ஓட்டுங்கள்!',
            ),
          ],
        );

      case 'ml':
        return const DashboardInfoContent(
          title: 'ദൂര പരിധി (Distance Limit) ഗൈഡ്',
          subtitle: 'പിക്കപ്പ്, ട്രിപ്പ് ദൂര പരിധികൾ വഴി ഇന്ധനവും സമയവും ലാഭിക്കാം',
          buttonText: 'മനസ്സിലായി (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'കസ്റ്റമർ പിക്കപ്പ്',
              title: 'Max Pickup Distance (പിക്കപ്പ് ദൂര പരിധി)',
              content:
                  'കസ്റ്റമർ നിങ്ങളിൽ നിന്ന് എത്ര ദൂരെയായിരിക്കണമെന്ന് ഇത് നിശ്ചയിക്കുന്നു.\n\n• പ്രവർത്തനം: റൈഡ് വരുമ്പോൾ പിക്കപ്പ് ദൂരം പരിശോധിച്ച് പരിധിക്ക് മുകളിലാണെങ്കിൽ ഒഴിവാക്കും.\n• പ്രാധാന്യം: 6-8 കി.മീ അകലെയുള്ള പിക്കപ്പുകളിലേക്ക് വെറുതെ പോയി ഇന്ധനവും സമയവും നഷ്ടപ്പെടുന്നത് തടയുന്നു.',
              example:
                  'സൂചന: നഗരങ്ങളിൽ വേഗത്തിൽ പിക്കപ്പ് ചെയ്യാൻ 2 മുതൽ 4 കി.മീ വരെ വെയ്ക്കുക.',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'ഡ്രോപ്പ് ദൂരം (300 കി.മീ വരെ)',
              title: 'Max Trip Distance (യാത്രാ ദൂര പരിധി)',
              content:
                  'പിക്കപ്പ് മുതൽ ഡ്രോപ്പ് വരെയുള്ള ആകെ ദൂരം ഇത് നിശ്ചയിക്കുന്നു.\n\n• 300 കി.മീ വരെ പരിധി: ലോക്കൽ യാത്രകൾക്ക് 15-25 കി.മീ വെയ്ക്കുക. ഇന്റർസിറ്റി, Porter എന്നിവയ്ക്ക് 300 കി.മീ വരെ ഉയർത്താം!\n• പ്രവർത്തനം: സ്ക്രീനിലെ ദൂരം നോക്കി ഉടൻ തന്നെ ഓർഡർ കൺഫേം ചെയ്യുന്നു.',
              example:
                  'ദൂരയാത്രകൾക്കായി 100 മുതൽ 300 കി.മീ വരെ സജ്ಜീകരിക്കുക.',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'സ്മാർട്ട് സ്ട്രാറ്റജി',
              title: 'ദൂരവും ലാഭവും തുലനം ചെയ്യൽ',
              content:
                  '• ഓട്ടോ, ബൈക്ക്: പിക്കപ്പ് 2.5 കി.മീ, യാത്ര 20 കി.മീ.\n• ടാക്സി, വാണിജ്യ വാഹനം: പിക്കപ്പ് 5 കി.മീ, യാത്ര 100-300 കി.മീ.',
              example:
                  'ഇത് റദ്ദാക്കൽ പിഴകളിൽ നിന്നും ഇന്ധന നഷ്ടത്തിൽ നിന്നും പൂർണ്ണ സംരക്ഷണം നൽകുന്നു.',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'പൂർണ്ണ സംരക്ഷണം',
              title: 'തെറ്റായ റൈഡുകൾ ഒഴിവാക്കൂ, റേറ്റിംഗ് സുരക്ഷിതം',
              content:
                  '🛺 SnapRider നിങ്ങളുടെ നിബന്ധനകൾ പാലിക്കുന്ന റൈഡുകൾ മാത്രമേ സ്വീകരിക്കൂ. സുരക്ഷിതമായി ഡ്രൈവ് ചെയ്യുക!',
              example:
                  'സമാധാനമായി വാഹനം ഓടിക്കൂ!',
            ),
          ],
        );

      case 'kn':
        return const DashboardInfoContent(
          title: 'ದೂರದ ಮಿತಿ (Distance Limit) ಮಾರ್ಗದರ್ಶಿ',
          subtitle: 'ಪಿಕಪ್ ಮತ್ತು ಟ್ರಿಪ್ ದೂರದ ಮೂಲಕ ಇಂಧನ ಮತ್ತು ಸಮಯ ಉಳಿಸುವ ವಿಧಾನ',
          buttonText: 'ಅರ್ಥವಾಯಿತು (Got It)',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'ಗ್ರಾಹಕರ ಪಿಕಪ್ ದೂರ',
              title: 'Max Pickup Distance (ಪಿಕಪ್ ದೂರದ ಮಿತಿ)',
              content:
                  'ಗ್ರಾಹಕರು ನಿಮ್ಮಿಂದ ಎಷ್ಟು ದೂರದಲ್ಲಿರಬೇಕು ಎಂಬುದನ್ನು ಇದು ನಿರ್ಧರಿಸುತ್ತದೆ.\n\n• ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ: ರೈಡ್ ಬಂದಾಗ SnapRider ದೂರವನ್ನು ಪರಿಶೀಲಿಸುತ್ತದೆ, ಮಿತಿಗಿಂತ ಹೆಚ್ಚಿದ್ದರೆ ತಕ್ಷಣ ಬಿಟ್ಟುಬಿಡುತ್ತದೆ.\n• ಪ್ರಾಮುಖ್ಯತೆ: 6-8 ಕಿ.ಮೀ ದೂರದ ಪಿಕಪ್‌ಗೆ ಹೋಗಿ ಇಂಧನ ಮತ್ತು ಸಮಯ ವ್ಯರ್ಥವಾಗುವುದನ್ನು 100% ತಡೆಯುತ್ತದೆ.',
              example:
                  'ಸಲಹೆ: ನಗರ ಪ್ರದೇಶಗಳಲ್ಲಿ 5-10 ನಿಮಿಷಗಳಲ್ಲಿ ಪಿಕಪ್ ಮಾಡಲು 2 ರಿಂದ 4 ಕಿ.ಮೀ ಇರಿಸಿ.',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'ಡ್ರಾಪ್ ದೂರ (300 ಕಿ.ಮೀ ವರೆಗೆ)',
              title: 'Max Trip Distance (ಟ್ರಿಪ್ ದೂರದ ಮಿತಿ)',
              content:
                  'ಪಿಕಪ್‌ನಿಂದ ಡ್ರಾಪ್ ಸ್ಥಳದವರೆಗಿನ ಒಟ್ಟು ದೂರವನ್ನು ಇದು ನಿರ್ಧರಿಸುತ್ತದೆ.\n\n• 300 ಕಿ.ಮೀ ವರೆಗೆ ಶ್ರೇಣಿ: ಸ್ಥಳೀಯ ನಗರಕ್ಕೆ 15-25 ಕಿ.ಮೀ ಇರಿಸಿ. ಅಂತರ್ಜಿಲ್ಲೆ ಅಥವಾ Porter ಗಾಗಿ 300 ಕಿ.ಮೀ ವರೆಗೆ ವಿಸ್ತರಿಸಿ!\n• ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ: ನಿಖರ ದೂರವನ್ನು ಪರಿಶೀಲಿಸಿ 0ms ನಲ್ಲಿ ಲಾಕ್ ಮಾಡುತ್ತದೆ.',
              example:
                  'ದೂರದ ಊರುಗಳ ಬುಕಿಂಗ್‌ಗಾಗಿ 100 ರಿಂದ 300 ಕಿ.ಮೀ ಸೆಟ್ ಮಾಡಿ.',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'ಸ್ಮಾರ್ಟ್ ತಂತ್ರ',
              title: 'ದೂರ ಮತ್ತು ಆದಾಯದ ಸಮತೋಲನ',
              content:
                  '• ಆಟೋ ಮತ್ತು ಬೈಕ್: ಪಿಕಪ್ 2.5 ಕಿ.ಮೀ, ಟ್ರಿಪ್ 20 ಕಿ.ಮೀ.\n• ಕ್ಯಾಬ್ ಮತ್ತು ವಾಣಿಜ್ಯ ವಾಹನ: ಪಿಕಪ್ 5 ಕಿ.ಮೀ, ಟ್ರಿಪ್ 100-300 ಕಿ.ಮೀ.',
              example:
                  'ಇದು ರದ್ದತಿ ದಂಡ ಮತ್ತು ಇಂಧನ ನಷ್ಟದಿಂದ ಸಂಪೂರ್ಣ ರಕ್ಷಣೆ ನೀಡುತ್ತದೆ.',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'ಸಂಪೂರ್ಣ ರಕ್ಷಣೆ',
              title: 'ತಪ್ಪಾದ ರೈಡ್‌ಗಳಿಂದ ಶಾಶ್ವತ ಮುಕ್ತಿ',
              content:
                  '🛺 SnapRider ನಿಮ್ಮ ಎಲ್ಲಾ ನಿಯಮಗಳಿಗೆ ಸರಿಹೊಂದುವ ರೈಡ್‌ಗಳನ್ನು ಮಾತ್ರ ಸ್ವೀಕರಿಸುತ್ತದೆ. ನಿರಾಳವಾಗಿ ಚಲಾಯಿಸಿ!',
              example:
                  'ಚಿಂತೆಯಿಲ್ಲದೆ ಡ್ರೈವ್ ಮಾಡಿ!',
            ),
          ],
        );

      case 'en':
      default:
        return const DashboardInfoContent(
          title: 'Distance Limit Guide',
          subtitle: 'Save fuel and time with pickup & trip distance rules',
          buttonText: 'Got It',
          cards: [
            InfoCardData(
              icon: Icons.near_me_rounded,
              accentColor: Color(0xFFFF6E00),
              tag: 'Customer Pickup',
              title: 'Max Pickup Distance (Prevent Dead Mileage)',
              content:
                  '• What it does: Sets how far the customer can be from your current location.\n• How app works: When a ride offer arrives, SnapRider reads pickup distance instantly. If it exceeds your set limit (e.g., 3 km), it immediately skips the offer.\n• Why it matters: Prevents burning fuel and wasting time on far-away 6-8 km pickups that passengers often cancel.',
              example:
                  'Tip: Keep pickup distance 2 to 4 km in city areas for fast 5-minute pickups.',
            ),
            InfoCardData(
              icon: Icons.route_rounded,
              accentColor: Color(0xFF1976D2),
              tag: 'Drop Location (Up to 300 km)',
              title: 'Max Trip Distance (Local to Outstation)',
              content:
                  '• Expanded to 300 KM: Set 15-25 km for local city driving. For outstation, intercity, or commercial transport (Porter intercity trips), expand it up to 300 km!\n• How app works: Analyzes trip drop-off kilometers on screen and instantly confirms matching rides in 0ms.',
              example:
                  'Set 100 to 300 km for lucrative outstation bookings.',
            ),
            InfoCardData(
              icon: Icons.balance_rounded,
              accentColor: Color(0xFF7C3AED),
              tag: 'Smart Strategy',
              title: 'Optimal Distance & Profit Balance',
              content:
                  '• Auto & Bike: Max Pickup 2.5 km, Trip Distance 20 km for low fuel burn and rapid returns.\n• Cabs & Commercial: Max Pickup 5.0 km, Trip Distance 100-300 km to catch high-ticket bookings.',
              example:
                  'Together, these settings eliminate cancellation penalties and dead fuel loss.',
            ),
            InfoCardData(
              icon: Icons.security_rounded,
              accentColor: Color(0xFF059669),
              tag: 'Full Automation',
              title: 'Zero Bad Rides, 100% Rating Safety',
              content:
                  '🛺 SnapRider only accepts rides matching all your parameters (Fare + Pickup + Drop). Drive safely and let SnapRider do the fast clicking!',
              example:
                  'Drive with peace of mind. Instant 0ms hardware taps without touching your screen.',
            ),
          ],
        );
    }
  }

  // ==================== 3. SETTING CONFIRMATION DIALOG CONTENT ====================
  static ConfirmationDialogStrings getConfirmDialogStrings(String langCode) {
    switch (langCode) {
      case 'hi':
        return const ConfirmationDialogStrings(
          title: 'नई सेटिंग्स सुरक्षित करें?',
          subtitle: 'क्या आप इन नियमों को Ola, Uber, Rapido और Porter में लागू करना चाहते हैं?',
          fareLabel: 'किराया दायरा',
          pickupLabel: 'अधिकतम पिकअप',
          tripLabel: 'अधिकतम ट्रिप',
          note: 'केवल वही राइड्स स्वीकार होंगी जो आपके सेट किए गए सभी नियमों पर खरी उतरेंगी।',
          cancelBtn: 'रद्द करें',
          confirmBtn: '✓ पुष्टि करें और सेव करें',
          savedToast: '✓ सेटिंग्स सुरक्षित हो गईं और सभी ऐप्स में लागू हो गईं!',
        );
      case 'mr':
        return const ConfirmationDialogStrings(
          title: 'नवीन सेटिंग जतन करावी?',
          subtitle: 'तुम्हाला हे नियम Ola, Uber, Rapido आणि Porter मध्ये लागू करायचे आहेत का?',
          fareLabel: 'भाडे मर्यादा',
          pickupLabel: 'कमाल पिकअप',
          tripLabel: 'कमाल ट्रिप',
          note: 'फक्त या नियमांत बसणाऱ्या राइड्स स्वीकारल्या जातील.',
          cancelBtn: 'रद्द करा',
          confirmBtn: '✓ पुष्टी करा आणि जतन करा',
          savedToast: '✓ सेटिंग्ज जतन झाल्या आणि सर्व ॲप्सवर सक्रिय झाल्या!',
        );
      case 'ta':
        return const ConfirmationDialogStrings(
          title: 'புதிய அமைப்புகளைச் சேமிக்கவா?',
          subtitle: 'Ola, Uber, Rapido மற்றும் Porter-ல் இந்த விதிகளை உடனடியாகச் செயல்படுத்த விரும்புகிறீர்களா?',
          fareLabel: 'கட்டண வரம்பு',
          pickupLabel: 'அதிகபட்ச பிக்கப்',
          tripLabel: 'அதிகபட்ச பயணம்',
          note: 'இந்த விதிகளுக்குப் பொருந்தும் சவாரிகள் மட்டுமே ஏற்கப்படும்.',
          cancelBtn: 'ரத்துசெய்',
          confirmBtn: '✓ உறுதிசெய்து சேமி',
          savedToast: '✓ அமைப்புகள் சேமிக்கப்பட்டு செயல்படுத்தப்பட்டன!',
        );
      case 'ml':
        return const ConfirmationDialogStrings(
          title: 'പുതിയ ക്രമീകരണങ്ങൾ സേവ് ചെയ്യണോ?',
          subtitle: 'Ola, Uber, Rapido, Porter എന്നിവയിൽ ഈ നിയമങ്ങൾ ഉടൻ പ്രയോഗിക്കണോ?',
          fareLabel: 'നിരക്ക് പരിധി',
          pickupLabel: 'പരമാവധി പിക്കപ്പ്',
          tripLabel: 'പരമാവധി ട്രിപ്പ്',
          note: 'ഈ നിയമങ്ങൾ പാലിക്കുന്ന റൈഡുകൾ മാത്രമേ സ്വീകരിക്കൂ.',
          cancelBtn: 'റദ്ദാക്കുക',
          confirmBtn: '✓ സ്ഥിരീകരിച്ച് സേവ് ചെയ്യുക',
          savedToast: '✓ ക്രമീകരണങ്ങൾ സ്ഥിരീകരിച്ച് സജീവമാക്കി!',
        );
      case 'kn':
        return const ConfirmationDialogStrings(
          title: 'ಹೊಸ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಉಳಿಸುವುದೇ?',
          subtitle: 'Ola, Uber, Rapido ಮತ್ತು Porter ನಲ್ಲಿ ಈ ನಿಯಮಗಳನ್ನು ತಕ್ಷಣ ಸಕ್ರಿಯಗೊಳಿಸಬೇಕೇ?',
          fareLabel: 'ದರ ವ್ಯಾಪ್ತಿ',
          pickupLabel: 'ಗರಿಷ್ಠ ಪಿಕಪ್',
          tripLabel: 'ಗರಿಷ್ಠ ಟ್ರಿಪ್',
          note: 'ಈ ನಿಯಮಗಳಿಗೆ ಹೊಂದಿಕೆಯಾಗುವ ರೈಡ್‌ಗಳನ್ನು ಮಾತ್ರ ಸ್ವೀಕರಿಸಲಾಗುತ್ತದೆ.',
          cancelBtn: 'ರದ್ದುಮಾಡಿ',
          confirmBtn: '✓ ದೃಢೀಕರಿಸಿ ಮತ್ತು ಉಳಿಸಿ',
          savedToast: '✓ ಸೆಟ್ಟಿಂಗ್‌ಗಳು ದೃಢೀಕರಿಸಲ್ಪಟ್ಟಿವೆ ಮತ್ತು ಸಕ್ರಿಯವಾಗಿವೆ!',
        );
      case 'en':
      default:
        return const ConfirmationDialogStrings(
          title: 'Save New Ride Settings?',
          subtitle: 'Do you want to confirm and activate these rules across Ola, Uber, Rapido & Porter?',
          fareLabel: 'Fare Range',
          pickupLabel: 'Max Pickup',
          tripLabel: 'Max Trip',
          note: 'Only ride offers matching all your rules will be accepted automatically.',
          cancelBtn: 'Cancel',
          confirmBtn: '✓ Confirm & Save',
          savedToast: '✓ Settings confirmed & active on all ride apps!',
        );
    }
  }
}
