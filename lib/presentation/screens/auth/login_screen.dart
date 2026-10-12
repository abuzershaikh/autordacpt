import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/auth_service.dart';
import '../../../data/datasources/user_profile_service.dart';
import '../../../data/datasources/telemetry_service.dart';
import '../../../services/analytics/analytics_service.dart';
import 'driver_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final userCredential = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userCredential != null) {
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await UserProfileService().ensureUserDocumentExists(user);
        AnalyticsService().setUserId(user.uid);
        AnalyticsService().logLogin(method: 'google');
        try {
          TelemetryService().sendHeartbeat();
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverSetupScreen(user: userCredential.user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign-in cancelled or not completed.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HERO IMAGE BANNER WITH GRADIENT FADE
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: size.height * 0.44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                  ),
                  child: Image.asset(
                    'assets/images/login_hero.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primary,
                      child: const Center(
                        child: Icon(Icons.electric_rickshaw, size: 80, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                // Bottom soft fade to scaffold background
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8FAFC).withValues(alpha: 0.0),
                          const Color(0xFFF8FAFC),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Top Floating Badge
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Driver Partner App',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. WELCOME & BENEFITS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),

                  // App Name Title
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'Apne orders automatically accept karein.\nHigh-fare rides kabhi miss na ho!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 28),

                  // 3. GOOGLE SIGN IN BUTTON (PRIMARY ACTION)
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Official Generated Google G Logo Image
                                    _buildGoogleGLogo(),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Official generated Google 'G' icon image
  Widget _buildGoogleGLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/images/google_logo.jpg',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.g_mobiledata,
          color: Color(0xFF4285F4),
          size: 28,
        ),
      ),
    );
  }
}
