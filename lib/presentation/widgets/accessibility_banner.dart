import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/accessibility_service.dart';

/// Banner to prompt user to enable accessibility service
class AccessibilityBanner extends StatefulWidget {
  const AccessibilityBanner({super.key});

  @override
  State<AccessibilityBanner> createState() => _AccessibilityBannerState();
}

class _AccessibilityBannerState extends State<AccessibilityBanner> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    setState(() => _isLoading = true);
    final enabled = await _accessibilityService.isAccessibilityEnabled();
    setState(() {
      _isEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _openSettings() async {
    await _accessibilityService.openAccessibilitySettings();
    // Re-check after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    _checkAccessibility();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_isEnabled) {
      return const SizedBox.shrink();
    }

    // Show warning banner
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Accessibility Service',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required for auto-accepting rides',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Steps: Settings → 🛺 SnapRider → Turn ON',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
