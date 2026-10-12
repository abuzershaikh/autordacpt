import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Enterprise Firebase Analytics Service
/// Handles standard eCommerce, driver telemetry events, and screen tracking.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  bool _isInitialized = false;

  /// Initialize Firebase Analytics instance and observer
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      await _analytics?.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      debugPrint('📊 [AnalyticsService] Firebase Analytics initialized successfully!');
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Failed to initialize Firebase Analytics: $e');
    }
  }

  /// Navigator observer for automatic screen view logging in MaterialApp
  FirebaseAnalyticsObserver? get observer {
    if (_observer == null && _analytics != null) {
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
    }
    return _observer;
  }

  FirebaseAnalytics? get analytics => _analytics;

  // ==========================================
  // User Identity & Properties
  // ==========================================

  /// Set the authenticated Rider/Driver user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      debugPrint('📊 [Analytics] User ID set: $userId');
    } catch (e) {
      debugPrint('⚠️ [Analytics] setUserId error: $e');
    }
  }

  /// Set user property (e.g. plan_status, device_brand, user_type)
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('⚠️ [Analytics] setUserProperty error: $e');
    }
  }

  // ==========================================
  // Screen & Navigation Events
  // ==========================================

  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('📊 [Analytics] Screen: $screenName');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logScreenView error: $e');
    }
  }

  // ==========================================
  // Authentication Events
  // ==========================================

  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      debugPrint('📊 [Analytics] Logged Login via $method');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logLogin error: $e');
    }
  }

  Future<void> logSignUp({String method = 'google'}) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
      debugPrint('📊 [Analytics] Logged SignUp via $method');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logSignUp error: $e');
    }
  }

  // ==========================================
  // Driver Ride Automation Events
  // ==========================================

  Future<void> logRideAccepted({
    required String service,
    required double fare,
    double? pickupDistance,
    double? tripDistance,
    int? responseTimeMs,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'ride_accepted',
        parameters: {
          'service_name': service.toLowerCase(),
          'fare_amount': fare,
          if (pickupDistance != null) 'pickup_distance_km': pickupDistance,
          if (tripDistance != null) 'trip_distance_km': tripDistance,
          if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [Analytics] Event: ride_accepted ($service, ₹$fare)');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logRideAccepted error: $e');
    }
  }

  Future<void> logRideMissed({
    required String service,
    required double fare,
    required String reason,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'ride_missed',
        parameters: {
          'service_name': service.toLowerCase(),
          'fare_amount': fare,
          'miss_reason': reason,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] logRideMissed error: $e');
    }
  }

  Future<void> logServiceToggled({
    required String service,
    required bool isEnabled,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'service_toggle',
        parameters: {
          'service_name': service.toLowerCase(),
          'is_enabled': isEnabled ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] logServiceToggled error: $e');
    }
  }

  Future<void> logAccessibilityToggled({required bool isEnabled}) async {
    try {
      await _analytics?.logEvent(
        name: 'accessibility_service_toggle',
        parameters: {
          'is_enabled': isEnabled ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] logAccessibilityToggled error: $e');
    }
  }

  // ==========================================
  // Subscriptions & Monetization Events
  // ==========================================

  Future<void> logViewPlans() async {
    try {
      await _analytics?.logEvent(name: 'view_subscription_plans');
      debugPrint('📊 [Analytics] Event: view_subscription_plans');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logViewPlans error: $e');
    }
  }

  Future<void> logPlanSelected({
    required String planId,
    required String planName,
    required num price,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'select_plan',
        parameters: {
          'item_id': planId,
          'item_name': planName,
          'price': price.toDouble(),
          'currency': 'INR',
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] logPlanSelected error: $e');
    }
  }

  Future<void> logBeginCheckout({
    required String planId,
    required String planName,
    required num amount,
  }) async {
    try {
      await _analytics?.logBeginCheckout(
        value: amount.toDouble(),
        currency: 'INR',
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: planName,
            price: amount.toDouble(),
            quantity: 1,
          ),
        ],
      );
      debugPrint('📊 [Analytics] Begin checkout: $planName (₹$amount)');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logBeginCheckout error: $e');
    }
  }

  Future<void> logPurchaseSuccess({
    required String planId,
    required String planName,
    required num amount,
    required String paymentId,
    String? orderId,
  }) async {
    try {
      await _analytics?.logPurchase(
        currency: 'INR',
        value: amount.toDouble(),
        transactionId: paymentId,
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: planName,
            price: amount.toDouble(),
            quantity: 1,
          ),
        ],
      );
      debugPrint('📊 [Analytics] Purchase success: $planName (₹$amount, txn: $paymentId)');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logPurchaseSuccess error: $e');
    }
  }

  Future<void> logPaymentFailed({
    required String planId,
    required String reason,
    int? errorCode,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'payment_failed',
        parameters: {
          'plan_id': planId,
          'failure_reason': reason,
          if (errorCode != null) 'error_code': errorCode,
        },
      );
      debugPrint('📊 [Analytics] Payment failed: $planId ($reason)');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logPaymentFailed error: $e');
    }
  }

  // ==========================================
  // Free Rides Usage Events
  // ==========================================

  Future<void> logFreeRideUsed({
    required int ridesRemaining,
    required String service,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'free_ride_consumed',
        parameters: {
          'rides_remaining': ridesRemaining,
          'service_name': service.toLowerCase(),
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] logFreeRideUsed error: $e');
    }
  }

  Future<void> logFreeLimitReached() async {
    try {
      await _analytics?.logEvent(name: 'free_limit_exhausted');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logFreeLimitReached error: $e');
    }
  }
}
