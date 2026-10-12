import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/free_rides_service.dart';
import '../../../data/datasources/user_profile_service.dart';
import '../../../services/payment/razorpay_service.dart';
import '../../../services/payment/dynamic_payment_config_service.dart';
import '../../../services/analytics/analytics_service.dart';

class PlanItem {
  final String id;
  final String title;
  final int price;
  final String durationText;
  final int validityDays; // -1 for lifetime
  final String badge;
  final bool isPopular;
  final bool isLifetime;
  final List<String> features;

  const PlanItem({
    required this.id,
    required this.title,
    required this.price,
    required this.durationText,
    required this.validityDays,
    required this.badge,
    this.isPopular = false,
    this.isLifetime = false,
    required this.features,
  });
}

class PlanScreen extends StatefulWidget {
  final String userPhone;
  final UserPlanInfo? currentPlan;

  const PlanScreen({
    super.key,
    required this.userPhone,
    this.currentPlan,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final RazorpayService _razorpayService = RazorpayService();
  final UserProfileService _userProfileService = UserProfileService();
  final FreeRidesService _freeRidesService = FreeRidesService();
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FreeRidesInfo? _freeRidesInfo;
  bool _isProcessing = false;
  PlanItem? _selectedPlan;
  String? _dynamicRazorpayKeyId;
  List<PlanItem> _plans = DynamicPaymentConfigService.defaultFallbackPlans;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logViewPlans();
    _initRazorpay();
    _loadFreeRidesInfo();
    _loadDynamicPlansAndKey();
  }

  Future<void> _loadDynamicPlansAndKey() async {
    final config = await DynamicPaymentConfigService.fetchLivePlansAndConfig();
    if (mounted) {
      setState(() {
        _dynamicRazorpayKeyId = config.keyId;
        _plans = config.plans;
      });
    }
  }

  Future<void> _loadFreeRidesInfo() async {
    final info = await _freeRidesService.getStatus();
    if (mounted) {
      setState(() => _freeRidesInfo = info);
    }
  }

  void _initRazorpay() {
    _razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: (wallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected wallet: $wallet')),
        );
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResultData response) async {
    final user = _auth?.currentUser;
    final plan = _selectedPlan;

    if (plan == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final uid = user?.uid ?? 'guest_driver';

    // Log Analytics eCommerce purchase event
    AnalyticsService().logPurchaseSuccess(
      planId: plan.id,
      planName: plan.title,
      amount: plan.price,
      paymentId: response.paymentId,
      orderId: response.orderId,
    );

    // Also notify VPS to record transaction & activate plan in MySQL
    if (response.orderId != null && response.signature != null) {
      DynamicPaymentConfigService.verifyPaymentOnVps(
        orderId: response.orderId!,
        paymentId: response.paymentId,
        signature: response.signature!,
        userId: uid,
      );
    }

    // Save to Firestore / local storage
    final success = await _userProfileService.activateSubscriptionPlan(
      uid: uid,
      planId: plan.id,
      planName: plan.title,
      amount: plan.price,
      paymentId: response.paymentId,
      validityDays: plan.validityDays,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      await _loadFreeRidesInfo();
      _showSuccessDialog(plan, response.paymentId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received, but failed to update cloud. Contact support.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentErrorResultData response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    AnalyticsService().logPaymentFailed(
      planId: _selectedPlan?.id ?? 'unknown',
      reason: response.message ?? 'Cancelled or Failed',
      errorCode: response.code,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Payment failed or cancelled'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startPayment(PlanItem plan) {
    final user = _auth?.currentUser;
    final userContact = widget.userPhone.isNotEmpty
        ? widget.userPhone
        : (user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : '9876543210');
    final userEmail = user?.email ?? 'driver@autoaccept.local';

    setState(() {
      _selectedPlan = plan;
      _isProcessing = true;
    });

    AnalyticsService().logPlanSelected(
      planId: plan.id,
      planName: plan.title,
      price: plan.price,
    );
    AnalyticsService().logBeginCheckout(
      planId: plan.id,
      planName: plan.title,
      amount: plan.price,
    );

    _razorpayService.openCheckout(
      amountInRupees: plan.price,
      planName: plan.title,
      userEmail: userEmail,
      userContact: userContact,
      customKeyId: _dynamicRazorpayKeyId,
    );
  }

  void _showSuccessDialog(PlanItem plan, String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Subscription Active!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have successfully activated ${plan.title} (₹${plan.price}).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              'Payment ID: $paymentId',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context, true); // return to profile with refreshed state
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Go to Profile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = widget.currentPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upgrade to AutoRide Pro 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get ultra-fast auto-clicking, zero delays, and all ride services support with 100% reliability.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    if (currentPlan != null && currentPlan.isActive) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current: ${currentPlan.planName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ] else if (_freeRidesInfo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _freeRidesInfo!.isTrialExpired
                              ? Colors.red.shade900.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _freeRidesInfo!.isTrialExpired
                                ? Colors.redAccent.shade100
                                : Colors.white38,
                          ),
                        ),
                        child: Text(
                          _freeRidesInfo!.isTrialExpired
                              ? '⚠️ Free Trial Ended (${_freeRidesInfo!.used}/${_freeRidesInfo!.limit} used) • Buy Plan to activate'
                              : '🎁 Free Trial Active: ${_freeRidesInfo!.remaining} of ${_freeRidesInfo!.limit} free rides left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Plan Cards
              ..._plans.map((plan) => _buildPlanCard(plan)),

              const SizedBox(height: 20),
              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by Razorpay • UPI, Cards, NetBanking',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Opening Razorpay Payment...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanItem plan) {
    final bool isCurrentPlan = widget.currentPlan?.planId == plan.id && (widget.currentPlan?.isActive ?? false);

    Color borderColor = Colors.grey.shade300;
    List<Color> gradientColors = [Colors.white, Colors.white];

    if (plan.isPopular) {
      borderColor = AppColors.primary;
    } else if (plan.isLifetime) {
      borderColor = Colors.amber.shade700;
      gradientColors = [
        Colors.amber.shade50.withValues(alpha: 0.5),
        Colors.white,
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (plan.isPopular || plan.isLifetime) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isPopular
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row badge & title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: plan.isLifetime
                        ? Colors.amber.shade800
                        : (plan.isPopular ? AppColors.primary : Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${plan.price}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: plan.isLifetime
                        ? Colors.amber.shade900
                        : (plan.isPopular ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ ${plan.durationText}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Feature list
            ...plan.features.map(
              (feat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: plan.isLifetime ? Colors.amber.shade800 : Colors.green.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feat,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : () => _startPayment(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.isLifetime
                      ? Colors.amber.shade700
                      : (plan.isPopular ? AppColors.primary : Colors.grey.shade800),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: plan.isPopular ? 2 : 0,
                ),
                child: Text(
                  isCurrentPlan ? 'Current Active Plan' : 'Subscribe for ₹${plan.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
