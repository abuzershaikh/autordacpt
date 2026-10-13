import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../services/accessibility_service.dart';
import 'contact_us_screen.dart';

/// Privacy Policy Screen with comprehensive Google Play Accessibility Service
/// prominent disclosures, data handling details, and driver privacy protections.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    HapticFeedback.mediumImpact();
    const phone = "919225278035";
    final message = Uri.encodeComponent(
      "Hello SnapRider Support, I have a question regarding the Privacy Policy.",
    );
    final whatsappUrl = "whatsapp://send?phone=$phone&text=$message";
    final webUrl = "https://wa.me/$phone?text=$message";

    bool success = await AccessibilityService.openUrl(whatsappUrl);
    if (!success) {
      success = await AccessibilityService.openUrl(webUrl);
    }

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp. Number: +91 9225278035'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final isHindi = langCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isHindi ? 'गोपनीयता नीति (Privacy Policy)' : 'Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF00A84D)),
            tooltip: 'Support',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Top Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF076632), Color(0xFF0E7A3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF076632).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFFFFD54F), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SnapRider Privacy Promise',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi
                            ? '100% सुरक्षित • आपका डेटा आपका अधिकार'
                            : '100% On-Device • Zero Personal Data Sold',
                        style: const TextStyle(
                          color: Color(0xFFE8F5E9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Last Updated: October 2026',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. CRITICAL PROMINENT DISCLOSURE (Google Play Accessibility API Compliance)
          _buildSpecialCard(
            badge: 'MANDATORY PROMINENT DISCLOSURE',
            badgeColor: const Color(0xFFFF6E00),
            title: 'Android AccessibilityService API Usage',
            icon: Icons.accessibility_new_rounded,
            accentColor: const Color(0xFFFF6E00),
            bgColor: const Color(0xFFFFF8F1),
            borderColor: const Color(0xFFFFD199),
            content:
                'SnapRider uses Android\'s BIND_ACCESSIBILITY_SERVICE API as a core functionality to assist drivers.\n\n'
                '• What it does: When a new ride offer is presented on supported driver apps (Ola, Uber, Rapido, Porter), '
                'SnapRider detects the on-screen card, reads the fare amount and pickup/drop distances, and automatically '
                'performs a tap gesture on the "Accept" button if the ride matches your user-defined criteria.\n\n'
                '• Zero Data Collection Guarantee: All screen parsing happens 100% locally in-memory on your device. '
                'We NEVER collect, log, record, or transmit your passwords, payment PINs, SMS, personal chat messages, or credentials.\n\n'
                '• User Control: You have complete control and can enable or revoke Accessibility permission at any time in Android Settings.',
          ),
          const SizedBox(height: 14),

          // 3. Information We Collect
          _buildInfoCard(
            title: '1. Information We Collect',
            icon: Icons.inventory_2_outlined,
            accentColor: const Color(0xFF00A84D),
            content:
                'To provide our subscription and account services, we only collect minimal essential information:\n\n'
                '• Mobile Phone Number: Used to authenticate your account securely via OTP.\n'
                '• Device Identifier: A unique anonymized hardware ID used strictly to link your active plan to your single driver device.\n'
                '• Filter Preferences: Your custom Min/Max Fare and Distance settings, stored securely in local device storage.\n'
                '• Ride Acceptance Count: Non-personal numeric count of accepted rides to manage the 10-free-rides trial counter.',
          ),
          const SizedBox(height: 14),

          // 4. Information We NEVER Collect
          _buildInfoCard(
            title: '2. Information We NEVER Collect',
            icon: Icons.do_not_disturb_on_outlined,
            accentColor: const Color(0xFFE53935),
            content:
                'We respect your personal privacy. SnapRider will NEVER:\n\n'
                '• Track or store your 24/7 background GPS location outside of on-screen ride offer distance checks.\n'
                '• Access your personal contacts, photos, microphone, or camera.\n'
                '• Read or monitor your private communications, chats, or web browsing.\n'
                '• Store your banking passwords, CVV, or UPI PINs.',
          ),
          const SizedBox(height: 14),

          // 5. Third-Party Services & Payment Security
          _buildInfoCard(
            title: '3. Third-Party Services & Payments',
            icon: Icons.security_outlined,
            accentColor: const Color(0xFF1976D2),
            content:
                'We integrate only industry-standard, certified third-party providers:\n\n'
                '• Google Firebase: Used for secure driver authentication and encrypted plan status sync.\n'
                '• Razorpay Gateway: All subscription payments (Daily ₹15, Weekly ₹49) are processed through RBI-regulated, '
                'PCI-DSS Level 1 compliant Razorpay. SnapRider does not store or process card or UPI secrets.',
          ),
          const SizedBox(height: 14),

          // 6. Data Security & Storage
          _buildInfoCard(
            title: '4. Data Security & Retention',
            icon: Icons.lock_outline_rounded,
            accentColor: const Color(0xFF7B1FA2),
            content:
                'All communications between SnapRider and our servers use 256-bit TLS/SSL encryption. '
                'We retain your account info only as long as you maintain an active account. You may request '
                'complete deletion of your account and associated records at any time by contacting our support team.',
          ),
          const SizedBox(height: 14),

          // 7. Driver Rights & Account Deletion
          _buildInfoCard(
            title: '5. Your Rights & Data Deletion',
            icon: Icons.manage_accounts_outlined,
            accentColor: const Color(0xFF00897B),
            content:
                'You have the right to:\n'
                '• Access and review your registered profile details.\n'
                '• Revoke Accessibility Service permissions at any moment.\n'
                '• Request account termination and permanent data purge via WhatsApp or email.',
          ),
          const SizedBox(height: 20),

          // 8. Contact & WhatsApp Quick Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: Color(0xFF00A84D), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Have Questions About Privacy?',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our dedicated driver support desk is available 24/7 to answer any data or privacy queries.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context),
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Chat on WhatsApp (+91 9225278035)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSpecialCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
