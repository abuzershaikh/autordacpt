import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../tutorial/tutorial_screen.dart';
import '../activity/activity_screen.dart';
import '../profile/profile_screen.dart';

import '../../../data/datasources/version_check_service.dart';
import '../update/force_update_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  AppVersionStatus? _versionStatus;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const TutorialScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppVersion();
    }
  }

  Future<void> _checkAppVersion() async {
    try {
      final status = await VersionCheckService().checkVersion();
      if (mounted) {
        setState(() {
          _versionStatus = status;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // If VPS Control Engine demands mandatory update or has blocked this version,
    // lock the app completely so old version cannot be used
    if (_versionStatus != null && _versionStatus!.shouldLockScreen) {
      return ForceUpdateScreen(
        versionStatus: _versionStatus!,
        onRetryCheck: _checkAppVersion,
      );
    }

    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: strings.dashboard,
                  icon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: strings.history,
                  icon: Icons.history_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: strings.tutorials,
                  icon: Icons.play_circle_fill_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: strings.activity,
                  icon: Icons.stars_rounded,
                  hasRedBadge: true,
                ),
                _buildNavItem(
                  index: 4,
                  label: strings.profile,
                  icon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    bool hasRedBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF00A84D);
    const inactiveColor = Color(0xFF9E9E9E);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 23,
              ),
              if (hasRedBadge)
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 2),
          // Tiny green rounded line under active item like reference image
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
