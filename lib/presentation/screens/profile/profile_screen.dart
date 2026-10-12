import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/language_provider.dart';
import '../../../data/datasources/auth_service.dart';
import '../../../data/datasources/user_profile_service.dart';
import '../../../data/datasources/free_rides_service.dart';
import '../../../services/accessibility_service.dart';
import '../auth/login_screen.dart';
import '../plans/plan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final FreeRidesService _freeRidesService = FreeRidesService();
  FreeRidesInfo? _freeRidesInfo;

  UserProfileData? _profileData;

  bool _isLoading = true;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _loadProfileAndDeviceInfo();
  }

  Future<void> _loadProfileAndDeviceInfo() async {
    setState(() => _isLoading = true);

    // Fetch existing profile from Firestore or local cache
    UserProfileData? profile;
    final user = _currentUser;
    final uid = user?.uid ?? 'guest_driver';
    try {
      profile = await _userProfileService.getUserProfile(uid);
      if (profile != null) {
        if (profile.displayName.isNotEmpty) {
          _nameController.text = profile.displayName;
        } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
          _nameController.text = user.displayName!;
        }
        if (profile.phoneNumber.isNotEmpty) {
          _phoneController.text = profile.phoneNumber;
        }
      } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
    } catch (_) {}

    FreeRidesInfo? freeInfo;
    try {
      freeInfo = await _freeRidesService.getStatus();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profileData = profile;
        _freeRidesInfo = freeInfo;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut(AppStrings strings) async {
    final user = _currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(strings.signOut, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.signOut();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openPlanScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanScreen(
          userPhone: _phoneController.text,
          currentPlan: _profileData?.activePlan,
        ),
      ),
    );

    if (result == true) {
      // Reload profile to refresh active plan
      _loadProfileAndDeviceInfo();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsAppSupport() async {
    HapticFeedback.mediumImpact();
    const phone = "919225278035";
    final message = Uri.encodeComponent("Hello SnapRider Support, I have a query related to SnapRider app.");
    final whatsappUrl = "whatsapp://send?phone=$phone&text=$message";
    final webUrl = "https://wa.me/$phone?text=$message";

    bool success = await AccessibilityService.openUrl(whatsappUrl);
    if (!success) {
      success = await AccessibilityService.openUrl(webUrl);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp. Number: +91 9225278035'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildCustomerSupportFab() {
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    String supportText = 'Customer Support';
    switch (langCode) {
      case 'hi':
        supportText = 'कस्टमर सपोर्ट';
        break;
      case 'mr':
        supportText = 'ग्राहक मदत';
        break;
      case 'ta':
        supportText = 'வாடிக்கையாளர் ஆதரவு';
        break;
      case 'ml':
        supportText = 'കസ്റ്റമർ സപ്പോർട്ട്';
        break;
      case 'kn':
        supportText = 'ಗ್ರಾಹಕ ಬೆಂಬಲ';
        break;
    }

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openWhatsAppSupport,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WhatsApp SVG Icon in white circular badge
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: SvgPicture.asset(
                      'assets/images/whatsapp_icon.svg',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  supportText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final activePlan = _profileData?.activePlan;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myProfile),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: strings.signOut,
            onPressed: () => _handleSignOut(strings),
          ),
        ],
      ),
      floatingActionButton: _buildCustomerSupportFab(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileAndDeviceInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 90.0),
                child: Column(
                  children: [
                    // User Header Card
                    _buildUserHeader(user, strings),
                    const SizedBox(height: 16),

                    // Subscription Plan Card
                    _buildSubscriptionCard(activePlan, strings),
                    const SizedBox(height: 16),

                    // 3D Driver Details Form Card (Name & Mobile Number with Indian Flag +91)
                    _build3DDriverFormCard(strings),
                    const SizedBox(height: 16),

                    // Language Selection Card
                    _buildLanguageSelectorCard(context, strings),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader(User? user, AppStrings strings) {
    final photoUrl = user?.photoURL;
    final name = user?.displayName ?? (_phoneController.text.isNotEmpty ? strings.driverPartner : strings.driverPartner);
    final email = user?.email ?? (_phoneController.text.isNotEmpty ? '+91 ${_phoneController.text}' : 'Driver ID: #DRV-8492');
    final bool isGoogleAuth = user != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 36, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGoogleAuth ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isGoogleAuth ? Colors.green.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Text(
                    isGoogleAuth ? '● Google Verified' : '● Device Linked & Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: isGoogleAuth ? Colors.green : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserPlanInfo? plan, AppStrings strings) {
    final bool isActive = plan != null && plan.isActive;

    Color bgGradientStart = isActive ? Colors.blue.shade800 : Colors.indigo.shade900;
    Color bgGradientEnd = isActive ? Colors.blue.shade600 : Colors.indigo.shade700;

    String planStatusText = strings.activePlan;
    String validityText = 'Subscribe to unlock continuous auto-clicking';

    if (isActive) {
      planStatusText = plan.planName;
      if (plan.planId == 'lifetime') {
        validityText = 'Lifetime Unlimited Access';
      } else if (plan.expiresAt != null) {
        final diff = plan.expiresAt!.difference(DateTime.now()).inDays;
        validityText = 'Valid till: ${plan.expiresAt!.day}/${plan.expiresAt!.month}/${plan.expiresAt!.year} ($diff ${strings.daysLeft})';
      }
    } else {
      if (_freeRidesInfo != null) {
        planStatusText = 'Trial: ${_freeRidesInfo!.used}/${_freeRidesInfo!.limit} Used';
        validityText = _freeRidesInfo!.isTrialExpired
            ? '⚠️ Free trial ended. Buy 1-Day Plan (₹15) or Weekly Plan (₹49)'
            : '${_freeRidesInfo!.remaining} free ride(s) left. Upgrade for unlimited.';
      } else {
        planStatusText = strings.freeTrial;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgGradientStart.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    planStatusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? strings.active.toUpperCase() : strings.inactive.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            validityText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openPlanScreen,
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
              label: Text(
                isActive ? strings.upgradePlan : '${strings.viewPlans} (from ₹15)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DDriverFormCard(AppStrings strings) {
    final user = _currentUser;
    final String driverName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (_profileData?.displayName.isNotEmpty == true
            ? _profileData!.displayName
            : (_nameController.text.isNotEmpty ? _nameController.text : 'autoride acceptor'));

    final String phoneDisplay = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : (_profileData?.phoneNumber.isNotEmpty == true
            ? _profileData!.phoneNumber
            : '98765 43210');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.driverDetails,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.driverDetailsSubtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // 1. FULL NAME 3D FIELD (AUTO-FETCHED, FIXED / NON-EDITABLE)
          Text(
            '${strings.fullName} (${strings.googleAccountName})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          _build3DContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF00C853), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.googleAccountName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        strings.fixed,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. MOBILE NUMBER 3D FIELD WITH INDIAN FLAG 🇮🇳 +91 (LINKED & VERIFIED)
          Text(
            strings.mobileNumber,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          _build3DContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇮🇳', style: TextStyle(fontSize: 17)),
                          SizedBox(width: 5),
                          Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.registeredPhone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            phoneDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Linked chip placed neatly below to prevent any overflow in all languages
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB9EACD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 13, color: Color(0xFF00C853)),
                          const SizedBox(width: 5),
                          Text(
                            strings.linked,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A84D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Language Selection Card supporting Hindi, Marathi, Tamil, Malayalam, Kannada, English
  Widget _buildLanguageSelectorCard(BuildContext context, AppStrings strings) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentCode = langProvider.currentLanguageCode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF00C853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.appLanguage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.choosePreferredLanguage,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Current active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB9EACD)),
                ),
                child: Text(
                  '${langProvider.currentLanguage.flag} ${langProvider.currentLanguage.nativeName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A84D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdown Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentCode,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                itemHeight: 56,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF007AFF),
                    size: 22,
                  ),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return LanguageProvider.supportedLanguages.map<Widget>((lang) {
                    return Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          lang.nativeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${lang.englishName})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: LanguageProvider.supportedLanguages.map((lang) {
                  final isSelected = lang.code == currentCode;
                  return DropdownMenuItem<String>(
                    value: lang.code,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F8F0) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(lang.flag, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF00A84D) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  lang.englishName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? const Color(0xFF00A84D).withValues(alpha: 0.85)
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00C853),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newCode) {
                  if (newCode != null && newCode != currentCode) {
                    langProvider.setLanguage(newCode);
                    final selectedLang = LanguageProvider.supportedLanguages.firstWhere((l) => l.code == newCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${selectedLang.nativeName} (${selectedLang.englishName}) selected!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF00A84D),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable 3D tactile card container with bevel highlight and soft shadow
  Widget _build3DContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );
  }
}

