import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../presentation/screens/plans/plan_screen.dart';

class DynamicPaymentConfig {
  final String keyId;
  final bool isLiveMode;
  final String accountLabel;
  final List<PlanItem> plans;

  DynamicPaymentConfig({
    required this.keyId,
    required this.isLiveMode,
    required this.accountLabel,
    required this.plans,
  });
}

class DynamicPaymentConfigService {
  // VPS Control Engine Base URL (Bangalore Production VPS)
  static const String vpsBaseUrl = 'http://139.84.158.149:5000';

  // Fallback defaults in case phone is offline or server is temporarily unreachable
  static const String fallbackKeyId = 'rzp_test_1DP5mmOlF5G5ag';

  static final List<PlanItem> defaultFallbackPlans = [
    const PlanItem(
      id: 'daily',
      title: 'Daily Pass',
      price: 15,
      durationText: '1 Day Access',
      validityDays: 1,
      badge: 'Starter',
      features: [
        '1 Day full unlimited auto-accept access',
        'All 4 services included (Porter, Rapido, Ola, Uber)',
        'Unlimited order accepting',
        'Instant zero-delay auto-click algorithm',
        'Cancel anytime, no automatic renewals',
      ],
    ),
    const PlanItem(
      id: 'weekly',
      title: 'Weekly Pro',
      price: 79,
      durationText: '7 Days Access',
      validityDays: 7,
      badge: 'Popular',
      isPopular: true,
      features: [
        '7 Days full access (Saves ₹26 vs Daily)',
        'Ideal for weekly ride goals',
        'All 4 services active simultaneously',
        'Smart distance & high fare filtering',
        'Priority server response rate',
      ],
    ),
    const PlanItem(
      id: 'monthly',
      title: 'Monthly Champion',
      price: 249,
      durationText: '30 Days Access',
      validityDays: 30,
      badge: 'Best Value',
      features: [
        '30 Days nonstop access (Just ~₹8/day)',
        'Highest ROI for full-time drivers',
        'Advanced customized fare filters',
        'VIP fast auto-click thread priority',
        'Zero renewal hassles for a month',
      ],
    ),
    const PlanItem(
      id: 'lifetime',
      title: 'Lifetime Plan',
      price: 499,
      durationText: 'Forever Access',
      validityDays: -1,
      badge: 'VIP Lifetime',
      isLifetime: true,
      features: [
        'Pay once, enjoy forever',
        'Unlimited access to all future updates',
        'Fastest clicker algorithm',
        'Zero renewals or monthly charges',
        'VIP priority customer support',
      ],
    ),
  ];

  /// Fetch live active plans & active Razorpay Key ID directly from VPS MariaDB/MySQL
  static Future<DynamicPaymentConfig> fetchLivePlansAndConfig() async {
    try {
      final uri = Uri.parse('$vpsBaseUrl/api/payment/plans');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final String keyId = data['razorpay_key_id'] ?? fallbackKeyId;
          final bool isLive = data['is_live_mode'] ?? false;
          final String label = data['account_label'] ?? 'Active Account';
          final List rawPlans = data['plans'] ?? [];

          final List<PlanItem> parsedPlans = [];
          for (var item in rawPlans) {
            final List<String> feat = (item['features'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            parsedPlans.add(
              PlanItem(
                id: item['id'] ?? 'plan',
                title: item['title'] ?? 'Subscription',
                price: (item['price'] is num) ? (item['price'] as num).toInt() : 15,
                durationText: item['duration_text'] ?? 'Access',
                validityDays: item['validity_days'] ?? 1,
                badge: item['badge'] ?? '',
                isPopular: item['is_popular'] == true,
                isLifetime: item['is_lifetime'] == true || item['validity_days'] == -1,
                features: feat.isNotEmpty ? feat : ['Full auto-accept access'],
              ),
            );
          }

          if (parsedPlans.isNotEmpty) {
            Logger.log('✅ Dynamic plans loaded from VPS (Key: ${keyId.substring(0, keyId.length > 8 ? 8 : keyId.length)}...)');
            return DynamicPaymentConfig(
              keyId: keyId,
              isLiveMode: isLive,
              accountLabel: label,
              plans: parsedPlans,
            );
          }
        }
      }
    } catch (e) {
      Logger.log('⚠️ Failed to fetch dynamic plans from VPS, falling back to local defaults: $e');
    }

    return DynamicPaymentConfig(
      keyId: fallbackKeyId,
      isLiveMode: false,
      accountLabel: 'Default Fallback',
      plans: defaultFallbackPlans,
    );
  }

  /// Create official Razorpay Order ID on VPS with active secret
  static Future<Map<String, dynamic>?> createOrderOnVps({
    required String userId,
    required String planId,
    String? userPhone,
    String? userEmail,
  }) async {
    try {
      final uri = Uri.parse('$vpsBaseUrl/api/payment/create-order');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'planId': planId,
          'userPhone': userPhone,
          'userEmail': userEmail,
        }),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data['order'];
        }
      }
    } catch (e) {
      Logger.error('Error creating order on VPS', error: e);
    }
    return null;
  }

  /// Verify signature & activate subscription via VPS
  static Future<bool> verifyPaymentOnVps({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$vpsBaseUrl/api/payment/verify');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      Logger.error('Error verifying payment on VPS', error: e);
    }
    return false;
  }
}
