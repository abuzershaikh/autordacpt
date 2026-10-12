import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_mr.dart';
import 'strings_ta.dart';
import 'strings_ml.dart';
import 'strings_kn.dart';

/// Representation of a supported language
class LanguageModel {
  final String code;
  final String englishName;
  final String nativeName;
  final String flag;

  const LanguageModel({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
  });
}

/// Provider to manage application language and notify listeners on change
class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_user_language_code';

  /// Supported Indian regional languages + English
  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇬🇧'),
    LanguageModel(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    LanguageModel(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    LanguageModel(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
    LanguageModel(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
    LanguageModel(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
  ];

  String _currentLanguageCode = 'en';
  AppStrings _strings = StringsEn();

  String get currentLanguageCode => _currentLanguageCode;
  AppStrings get strings => _strings;

  LanguageModel get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == _currentLanguageCode,
        orElse: () => supportedLanguages.first,
      );

  LanguageProvider() {
    _loadLanguageFromPrefs();
  }

  Future<void> _loadLanguageFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && savedCode != _currentLanguageCode) {
        setLanguage(savedCode, persist: false);
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String code, {bool persist = true}) async {
    if (_currentLanguageCode == code && _strings.languageCode == code) {
      return;
    }

    _currentLanguageCode = code;
    switch (code) {
      case 'hi':
        _strings = StringsHi();
        break;
      case 'mr':
        _strings = StringsMr();
        break;
      case 'ta':
        _strings = StringsTa();
        break;
      case 'ml':
        _strings = StringsMl();
        break;
      case 'kn':
        _strings = StringsKn();
        break;
      case 'en':
      default:
        _strings = StringsEn();
        break;
    }

    notifyListeners();

    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, code);
      } catch (_) {}
    }
  }
}
