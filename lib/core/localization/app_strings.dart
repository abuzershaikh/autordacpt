import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_mr.dart';
import 'strings_ta.dart';
import 'strings_ml.dart';
import 'strings_kn.dart';

/// Base abstract class for all language translations in AutoRide Accept.
/// Every language has its own dedicated class and file.
abstract class AppStrings {
  /// Static helper to get the active AppStrings from BuildContext
  static AppStrings of(BuildContext context) {
    try {
      final provider = Provider.of<LanguageProvider>(context);
      return provider.strings;
    } catch (_) {
      return StringsEn();
    }
  }

  /// Factory helper to get string instance by ISO code
  static AppStrings fromCode(String code) {
    switch (code) {
      case 'hi':
        return StringsHi();
      case 'mr':
        return StringsMr();
      case 'ta':
        return StringsTa();
      case 'ml':
        return StringsMl();
      case 'kn':
        return StringsKn();
      case 'en':
      default:
        return StringsEn();
    }
  }

  // Language Metadata
  String get languageCode;
  String get languageName;
  String get languageNativeName;

  // Bottom Navigation Tabs
  String get dashboard;
  String get history;
  String get tutorials;
  String get activity;
  String get profile;

  // Common UI
  String get cancel;
  String get save;
  String get viewAll;
  String get fixed;
  String get linked;
  String get verified;
  String get active;
  String get inactive;
  String get enabled;
  String get disabled;

  // Dashboard Screen
  String get autoAccept;
  String get enableAccessibilityTitle;
  String get enableAccessibilitySubtitle;
  String get openSettings;
  String get accessibilitySteps;
  String get fareFilter;
  String get fareFilterSubtitle;
  String get minFare;
  String get maxFare;
  String get distanceLimit;
  String get distanceLimitSubtitle;
  String get maxPickupDistance;
  String get maxTripDistance;
  String get clickerResponseAlerts;
  String get clickerResponseSubtitle;
  String get autoClickSpeed;
  String get instant;
  String get fast;
  String get safe;
  String get soundAlert;
  String get vibrationFeedback;
  String get applySaveChanges;
  String get testAutoAccept;
  String get recentAutoAccepts;
  String get autoRide;
  String get autoAccepted;
  String get pickup;
  String get trip;

  // History Screen
  String get rideHistory;
  String get totalAcceptedRides;
  String get faresFiltered;
  String get avgSpeed;
  String get filterAll;
  String get filterToday;
  String get filterThisWeek;
  String get filterAutoAccepted;
  String get noRidesFound;

  // Activity Screen
  String get liveActivityTitle;
  String get accessibilityEngine;
  String get systemMonitor;
  String get diagnosticEvents;
  String get simulateRideEvent;

  // Profile Screen
  String get myProfile;
  String get signOut;
  String get signOutConfirmTitle;
  String get signOutConfirmMessage;
  String get driverPartner;
  String get activePlan;
  String get upgradePlan;
  String get freeTrial;
  String get daysLeft;
  String get viewPlans;
  String get driverDetails;
  String get driverDetailsSubtitle;
  String get fullName;
  String get googleAccountName;
  String get mobileNumber;
  String get registeredPhone;
  String get appLanguage;
  String get selectLanguage;
  String get choosePreferredLanguage;
  String get languageChangedSuccess;

  // Auth & Setup Screen
  String get signInWithGoogle;
  String get continueAsGuest;
  String get driverSetup;
  String get completeProfile;
  String get saveAndStart;
}
