import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/dashboard_info_strings.dart';
import '../../../domain/entities/universal_config.dart';
import '../../../data/datasources/free_rides_service.dart';
import '../../../services/accessibility_service.dart';
import '../../../data/datasources/version_check_service.dart';
import '../../providers/service_provider.dart';
import '../plans/plan_screen.dart';

/// Pixel-perfect matching Dashboard Screen from user design reference
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late bool _autoAccept;
  late double _minFare;
  late double _maxFare;
  late double _pickupDistance;
  late double _tripDistance;
  late int _clickDelayMs;
  late bool _soundAlert;
  late bool _vibrationAlert;

  bool _isInitialized = false;
  bool _isAccessibilityEnabled = true;
  bool _isBatteryIgnored = true;

  FreeRidesInfo? _freeRidesInfo;
  final FreeRidesService _freeRidesService = FreeRidesService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibilityStatus();
    _checkBatteryStatus();
    _loadFreeRidesInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccessibilityStatus();
      _checkBatteryStatus();
      _loadFreeRidesInfo();
    }
  }

  Future<void> _checkBatteryStatus() async {
    try {
      final ignored = await VersionCheckService().isBatteryOptimizationIgnored();
      if (mounted && _isBatteryIgnored != ignored) {
        setState(() {
          _isBatteryIgnored = ignored;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFreeRidesInfo() async {
    try {
      final info = await _freeRidesService.getStatus();
      if (mounted) {
        setState(() {
          _freeRidesInfo = info;
        });
      }
    } catch (_) {}
  }

  void _openPlanScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlanScreen(userPhone: ''),
      ),
    );
    _loadFreeRidesInfo();
  }

  Future<void> _checkAccessibilityStatus() async {
    try {
      final enabled = await AccessibilityService.checkAccessibilityEnabled();
      if (mounted && _isAccessibilityEnabled != enabled) {
        setState(() {
          _isAccessibilityEnabled = enabled;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final config = context.read<ServiceProvider>().universalConfig;
      _initFromConfig(config);
      _isInitialized = true;
    }
  }

  void _initFromConfig(UniversalConfig config) {
    _autoAccept = config.autoAccept;
    _minFare = config.minFare.clamp(20.0, 25000.0);
    _maxFare = config.maxFare.clamp(20.0, 25000.0);
    if (_minFare > _maxFare) _minFare = _maxFare;
    _pickupDistance = config.pickupDistance.clamp(0.5, 50.0);
    _tripDistance = config.tripDistance.clamp(0.0, 3000.0);
    _clickDelayMs = config.clickDelayMs;
    _soundAlert = config.soundAlert;
    _vibrationAlert = config.vibrationAlert;
  }

  bool get _hasUnsavedChanges {
    if (!_isInitialized) return false;
    final cfg = context.read<ServiceProvider>().universalConfig;
    return _minFare.round() != cfg.minFare.round() ||
        _maxFare.round() != cfg.maxFare.round() ||
        (_pickupDistance * 10).round() != (cfg.pickupDistance * 10).round() ||
        _tripDistance.round() != cfg.tripDistance.round();
  }

  Future<void> _applyAndSaveSettings({String? customMessage}) async {
    final provider = context.read<ServiceProvider>();
    final newConfig = UniversalConfig(
      isEnabled: true,
      autoAccept: _autoAccept,
      minFare: _minFare,
      maxFare: _maxFare,
      pickupDistance: _pickupDistance,
      tripDistance: _tripDistance,
      clickDelayMs: _clickDelayMs,
      soundAlert: _soundAlert,
      vibrationAlert: _vibrationAlert,
    );

    await provider.updateUniversalConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customMessage ?? '✓ Settings confirmed & active on all ride apps!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00A84D),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showSettingsConfirmationDialog({
    required String changeType,
  }) async {
    final langCode = context.read<LanguageProvider>().currentLanguageCode;
    final dStrings = DashboardInfoStrings.getConfirmDialogStrings(langCode);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SVG Vector Graphic
              SvgPicture.asset(
                'assets/images/confirm_dialog_graphic.svg',
                width: 150,
                height: 110,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => Container(
                  width: 150,
                  height: 110,
                  alignment: Alignment.center,
                  child: const Icon(Icons.verified_rounded, size: 64, color: Color(0xFF00A84D)),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                dStrings.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                dStrings.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Settings Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRuleSummaryRow(
                      icon: Icons.currency_rupee_rounded,
                      iconColor: const Color(0xFF00A84D),
                      bgColor: const Color(0xFFE8F8F0),
                      label: dStrings.fareLabel,
                      value: '₹${_minFare.toInt()} - ₹${_maxFare.toInt()}',
                      isHighlighted: changeType == 'fare',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildRuleSummaryRow(
                      icon: Icons.near_me_rounded,
                      iconColor: const Color(0xFFFF6E00),
                      bgColor: const Color(0xFFFFF3E0),
                      label: dStrings.pickupLabel,
                      value: '${_pickupDistance.toStringAsFixed(1)} km',
                      isHighlighted: changeType == 'pickup',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    ),
                    _buildRuleSummaryRow(
                      icon: Icons.alt_route_rounded,
                      iconColor: const Color(0xFF2196F3),
                      bgColor: const Color(0xFFE3F2FD),
                      label: dStrings.tripLabel,
                      value: _tripDistance == 0.0 ? 'No Limit' : '${_tripDistance.toStringAsFixed(1)} km',
                      isHighlighted: changeType == 'trip',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Protective note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF00A84D), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dStrings.note,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Actions (Cancel vs Confirm & Save)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        dStrings.cancelBtn,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A84D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shadowColor: const Color(0xFF00A84D).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        dStrings.confirmBtn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await _applyAndSaveSettings(customMessage: dStrings.savedToast);
    } else {
      // Revert slider back to saved config
      final savedConfig = context.read<ServiceProvider>().universalConfig;
      setState(() {
        _minFare = savedConfig.minFare;
        _maxFare = savedConfig.maxFare;
        _pickupDistance = savedConfig.pickupDistance;
        _tripDistance = savedConfig.tripDistance;
      });
    }
  }

  Widget _buildRuleSummaryRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required bool isHighlighted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF475569),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isHighlighted ? iconColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted ? Border.all(color: iconColor, width: 1) : null,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? iconColor : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final isServiceActive = provider.universalConfig.autoAccept;
    final strings = AppStrings.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Column(
          children: [
            // Top App Header extending to top edge & behind notification bar
            _buildTopHeader(isServiceActive, provider, strings),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    provider.loadServices(),
                    _checkAccessibilityStatus(),
                    _checkBatteryStatus(),
                    _loadFreeRidesInfo(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    // 1. Accessibility Service Warning Banner (Only show when accessibility is NOT enabled)
                    if (!_isAccessibilityEnabled) ...[
                      _buildAccessibilityBanner(strings),
                      const SizedBox(height: 12),
                    ],

                    // 1.5 24/7 Background Battery Optimization Protection Banner
                    if (!_isBatteryIgnored) ...[
                      _buildBackgroundProtectionCard(),
                      const SizedBox(height: 12),
                    ],

                    // 2. Free Trial / Plan Status Banner
                    _buildTrialOrPlanStatusCard(),
                    const SizedBox(height: 12),

                    // 3. Universal Fare Filter Card
                    _buildFareFilterCard(strings),
                    const SizedBox(height: 12),

                    // 4. Universal Distance Limit Card
                    _buildDistanceLimitCard(strings),
                    if (_hasUnsavedChanges) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF009624)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showSettingsConfirmationDialog(changeType: 'all'),
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          label: Text(
                            DashboardInfoStrings.getConfirmDialogStrings(
                              context.read<LanguageProvider>().currentLanguageCode,
                            ).confirmBtn,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1. TOP HEADER BANNER ====================
  Widget _buildTopHeader(bool isServiceActive, ServiceProvider provider, AppStrings strings) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = 122.0 + topPadding;

    return Container(
      width: double.infinity,
      height: totalHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF076632),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Full-width horizontal illustration with Auto, Bike, and Tempo with ground shadows
          Positioned.fill(
            child: Image.asset(
              'assets/images/header_driver.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // 2. Balanced gradient: rich green on left for text/logo, clear across center & right for vehicles
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF076632).withValues(alpha: 0.90),
                    const Color(0xFF076632).withValues(alpha: 0.62),
                    const Color(0xFF0E7A3D).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 0.68, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 3. TOP NOTIFICATION BAR SHADOW: Dark gradient from physical top edge down
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topPadding + 28,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 4. Subtle bottom vignette shadow across entire width
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // Top Right Notification Bell with badge "3" and Switch
          Positioned(
            right: 14,
            top: topPadding + 10,
            child: Row(
              children: [
                // Notification Bell with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications, color: Colors.white, size: 22),
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Accessibility Settings Icon Button
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await AccessibilityService.openSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    _checkAccessibilityStatus();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                    ),
                    child: const Icon(
                      Icons.accessibility_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Green/White iOS Style Switch
                GestureDetector(
                  onTap: () {
                    final newVal = !isServiceActive;
                    if (newVal && _freeRidesInfo?.isTrialExpired == true) {
                      _showTrialExpiredDialog();
                      return;
                    }
                    provider.toggleUniversalAutoAccept(newVal);
                    setState(() => _autoAccept = newVal);
                  },
                  child: Container(
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isServiceActive ? const Color(0xFF00E676) : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isServiceActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header Content (App Icon + Titles)
          Positioned(
            left: 14,
            top: topPadding + 14,
            bottom: 14,
            right: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo with yellow border
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFFFC107),
                        child: const Icon(Icons.electric_rickshaw, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Texts
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.autoAccept,
                        style: const TextStyle(
                          color: Color(0xFFFFEB3B),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isServiceActive ? const Color(0xFF69F0AE) : Colors.white60,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isServiceActive ? strings.active : strings.inactive,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. ACCESSIBILITY SERVICE BANNER ====================
  Widget _buildAccessibilityBanner(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Warning Icon in soft orange square
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_rounded, color: Color(0xFFFF7A00), size: 22),
              ),
              const SizedBox(width: 10),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.enableAccessibilityTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.enableAccessibilitySubtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),

              // Open Settings Orange Pill Button
              ElevatedButton.icon(
                onPressed: () async {
                  await AccessibilityService.openSettings();
                  await Future.delayed(const Duration(seconds: 1));
                  _checkAccessibilityStatus();
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 13),
                label: Text(
                  strings.openSettings,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6E00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Steps Breadcrumb
          Text(
            strings.accessibilitySteps,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2.5 BACKGROUND PROTECTION BANNER ====================
  Widget _buildBackgroundProtectionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background 24/7 Work',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Allow background run so AutoRide never sleeps while driving.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await VersionCheckService().requestIgnoreBatteryOptimizations();
              await Future.delayed(const Duration(seconds: 1));
              _checkBatteryStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Allow',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. FREE TRIAL / PLAN STATUS CARD ====================
  Widget _buildTrialOrPlanStatusCard() {
    final info = _freeRidesInfo;
    if (info == null) return const SizedBox.shrink();

    // Case 1: Active Paid Plan
    if (info.hasActivePlan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF00C853), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Plan: ${info.activePlanName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Unlimited instant auto-accept enabled',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _openPlanScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Plans',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Free Trial Expired (2/2 rides used)
    if (info.isTrialExpired) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE082),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Free Trial Ended (${info.used}/${info.limit} Used)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Auto-accept is paused. Buy plan to activate!',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: const Text(
                      '⚡ 1-Day: ₹15  •  🔥 Weekly: ₹49',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A84D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _openPlanScreen,
                  child: const Text('Buy Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Case 3: Free Trial Active (< 2 rides used)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF2E7D32), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Trial: ${info.used}/${info.limit} rides used',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${info.remaining} free ride(s) left • Plans start @ ₹15/day',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _openPlanScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Plans (₹15)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrialExpiredDialog() {
    final limit = _freeRidesInfo?.limit ?? 10;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.workspace_premium, color: Color(0xFFFF9800), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Free Trial Limit Reached',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aapke $limit free trial rides complete ho chuke hain. Auto-accept enable karne ke liye subscription plan select karein:',
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('⚡ 1-Day Plan (24 Hours):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('₹15', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 15)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔥 Weekly Plan (7 Days):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('₹49', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A84D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openPlanScreen();
            },
            child: const Text('View Plans (from ₹15)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================== INFO DETAIL CARD HELPER ====================
  Widget _buildInfoDetailCard({
    required IconData icon,
    required Color accentColor,
    required String tag,
    required String title,
    required String content,
    String? example,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.48,
              color: Color(0xFF475569),
            ),
          ),
          if (example != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      example,
                      style: const TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== FARE FILTER INFO BOTTOM SHEET ====================
  void _showFareFilterInfoBottomSheet() {
    final langCode = context.read<LanguageProvider>().currentLanguageCode;
    final info = DashboardInfoStrings.getFareFilterInfo(langCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '₹',
                        style: TextStyle(
                          color: Color(0xFF00A84D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            info.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ...info.cards.map((card) => _buildInfoDetailCard(
                          icon: card.icon,
                          accentColor: card.accentColor,
                          tag: card.tag,
                          title: card.title,
                          content: card.content,
                          example: card.example,
                        )),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A84D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(info.buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DISTANCE LIMIT INFO BOTTOM SHEET ====================
  void _showDistanceLimitInfoBottomSheet() {
    final langCode = context.read<LanguageProvider>().currentLanguageCode;
    final info = DashboardInfoStrings.getDistanceLimitInfo(langCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Color(0xFFFF6E00),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            info.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ...info.cards.map((card) => _buildInfoDetailCard(
                          icon: card.icon,
                          accentColor: card.accentColor,
                          tag: card.tag,
                          title: card.title,
                          content: card.content,
                          example: card.example,
                        )),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6E00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(info.buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 3. UNIVERSAL FARE FILTER CARD ====================
  Widget _buildFareFilterCard(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(
                      color: Color(0xFF00A84D),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.fareFilter,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showFareFilterInfoBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F8F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF00A84D),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      strings.fareFilterSubtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),

              // Right stack: green pill + gold coin icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹${_minFare.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/coins_stack.jpg',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Minimum Fare & Maximum Fare Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        strings.minFare,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${_minFare.toInt()}',
                        style: const TextStyle(color: Color(0xFF00A84D), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        strings.maxFare,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${_maxFare.toInt()}',
                        style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Range Slider
          RangeSlider(
            values: RangeValues(_minFare.clamp(20.0, 25000.0), _maxFare.clamp(20.0, 25000.0)),
            min: 20,
            max: 25000,
            divisions: 499,
            activeColor: const Color(0xFF00C853),
            inactiveColor: const Color(0xFFE0E0E0),
            onChanged: (values) {
              setState(() {
                _minFare = values.start;
                _maxFare = values.end;
              });
            },
            onChangeEnd: (values) {
              final saved = context.read<ServiceProvider>().universalConfig;
              if (values.start.round() != saved.minFare.round() ||
                  values.end.round() != saved.maxFare.round()) {
                _showSettingsConfirmationDialog(changeType: 'fare');
              }
            },
          ),

          // Under slider labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹20', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                Text('₹25000', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 4. UNIVERSAL DISTANCE LIMIT CARD ====================
  Widget _buildDistanceLimitCard(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFFFF6E00), size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.distanceLimit,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showDistanceLimitInfoBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3E0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFFF6E00),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      strings.distanceLimitSubtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),

              // Route Map 3D Illustration
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/route_map.jpg',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.alt_route, color: Colors.blue, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup Distance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.maxPickupDistance, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_pickupDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: const Color(0xFFFF6E00),
              activeTrackColor: const Color(0xFFFF8C00),
              inactiveTrackColor: const Color(0xFFFFE0B2),
              trackHeight: 3,
            ),
            child: Slider(
              value: _pickupDistance.clamp(0.5, 50.0),
              min: 0.0,
              max: 50.0,
              onChanged: (val) => setState(() => _pickupDistance = val),
              onChangeEnd: (val) {
                final saved = context.read<ServiceProvider>().universalConfig;
                if ((val * 10).round() != (saved.pickupDistance * 10).round()) {
                  _showSettingsConfirmationDialog(changeType: 'pickup');
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 km', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                Text('50 km', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Trip Distance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.maxTripDistance, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_tripDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: const Color(0xFF2196F3),
              activeTrackColor: const Color(0xFF2196F3),
              inactiveTrackColor: const Color(0xFFBBDEFB),
              trackHeight: 3,
            ),
            child: Slider(
              value: _tripDistance.clamp(0.0, 3000.0),
              min: 0.0,
              max: 3000.0,
              divisions: 3000,
              onChanged: (val) => setState(() => _tripDistance = val),
              onChangeEnd: (val) {
                final saved = context.read<ServiceProvider>().universalConfig;
                if (val.round() != saved.tripDistance.round()) {
                  _showSettingsConfirmationDialog(changeType: 'trip');
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 km', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                Text('3000 km', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
