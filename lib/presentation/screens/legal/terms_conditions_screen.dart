import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../services/accessibility_service.dart';
import 'contact_us_screen.dart';

/// Terms & Conditions Screen specifying driver user agreement, safe driving rules,
/// independent third-party non-affiliation disclaimer, and plan policies.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    HapticFeedback.mediumImpact();
    const phone = "919225278035";
    final message = Uri.encodeComponent(
      "Hello SnapRider Support, I have a query regarding Terms & Conditions.",
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
          isHindi ? 'नियम और शर्तें (Terms & Conditions)' : 'Terms & Conditions',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
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
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  child: const Icon(Icons.gavel_rounded, color: Color(0xFF00E676), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver Partner Agreement',
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
                            ? 'पारदर्शी नियम • सुरक्षित और जिम्मेदार ड्राइविंग'
                            : 'Fair Usage Rules • Driver Safety Guidelines',
                        style: const TextStyle(
                          color: Color(0xFFECEFF1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                          'Version 1.0.8 • October 2026',
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

          // 2. CRITICAL NON-AFFILIATION DISCLAIMER CARD
          _buildSpecialNoticeCard(
            badge: 'LEGAL DISCLAIMER',
            title: 'Third-Party Non-Affiliation Notice',
            icon: Icons.business_outlined,
            content:
                'SnapRider is an independent assistive productivity tool created to help drivers manage incoming ride requests on their own devices.\n\n'
                '• SnapRider is NOT affiliated with, authorized, sponsored, endorsed, or associated in any way with:\n'
                '  - ANI Technologies Pvt. Ltd. (Ola Cabs)\n'
                '  - Uber Technologies Inc.\n'
                '  - Roppen Transportation Services Pvt. Ltd. (Rapido)\n'
                '  - SmartShift Logistics Solutions Pvt. Ltd. (Porter)\n'
                '  or any of their subsidiaries or affiliates.\n\n'
                '• All respective brand names, trademarks, and logos belong solely to their registered owners. '
                'References are made strictly for compatibility identification purposes.',
          ),
          const SizedBox(height: 14),

          // 3. Acceptance of Terms
          _buildTermCard(
            number: '1',
            title: 'Acceptance & Eligibility',
            icon: Icons.verified_user_outlined,
            accentColor: const Color(0xFF00A84D),
            content:
                'By downloading, installing, or operating SnapRider, you confirm that:\n'
                '• You are at least 18 years old and hold a valid Indian driving license.\n'
                '• You are an active commercial driver partner on one or more ride-hailing platforms.\n'
                '• You agree to abide by these Terms and Indian transportation regulations.',
          ),
          const SizedBox(height: 14),

          // 4. Safe Driving & Traffic Regulations
          _buildTermCard(
            number: '2',
            title: 'Driver Responsibility & Safe Driving',
            icon: Icons.traffic_rounded,
            accentColor: const Color(0xFFFF6E00),
            content:
                '• Road Safety First: The primary goal of SnapRider is to reduce distracted driving by eliminating the need to continuously stare at or touch your phone while in motion.\n'
                '• Full Driver Discretion: You retain 100% control over which rides you fulfill. SnapRider merely automates the accept tap based on the filters YOU configure.\n'
                '• You remain solely responsible for operating your vehicle safely in compliance with the Motor Vehicles Act.',
          ),
          const SizedBox(height: 14),

          // 5. No Guarantee of Fares or Volume
          _buildTermCard(
            number: '3',
            title: 'No Guarantee of Rides or Earnings',
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFF1976D2),
            content:
                '• SnapRider executes accept commands in milliseconds ONLY when a ride offer appears on your device screen.\n'
                '• The frequency, fare amounts, and availability of incoming ride requests are strictly governed by ride aggregator algorithms, passenger demand, and location.\n'
                '• SnapRider does not guarantee any minimum number of rides, earnings, or customer bookings.',
          ),
          const SizedBox(height: 14),

          // 6. Subscriptions & Trial Policy
          _buildTermCard(
            number: '4',
            title: 'Free Trial & Subscription Plans',
            icon: Icons.payments_outlined,
            accentColor: const Color(0xFF7B1FA2),
            content:
                '• Free Trial: New users receive 10 complimentary automated ride accepts to test compatibility and speed.\n'
                '• Paid Passes: Drivers can purchase daily (₹15), weekly (₹49), or monthly passes for unlimited access.\n'
                '• Single Device License: Each paid plan is bound to one active driver device. Account sharing is strictly prohibited.\n'
                '• Non-Refundable: Once activated, subscription passes are non-refundable unless verified technical service failure occurred.',
          ),
          const SizedBox(height: 14),

          // 7. Prohibited Uses
          _buildTermCard(
            number: '5',
            title: 'Prohibited Activities',
            icon: Icons.block_flipped,
            accentColor: const Color(0xFFD32F2F),
            content:
                'You agree NOT to:\n'
                '• Decompile, reverse engineer, or extract source code from the application.\n'
                '• Distribute, clone, resell, or run SnapRider on multi-instance emulators.\n'
                '• Use the application for fraudulent activities or in violation of platform guidelines.',
          ),
          const SizedBox(height: 14),

          // 8. Termination & Modifications
          _buildTermCard(
            number: '6',
            title: 'Modifications & Dispute Resolution',
            icon: Icons.policy_outlined,
            accentColor: const Color(0xFF455A64),
            content:
                '• We reserve the right to modify these terms with in-app notice.\n'
                '• Any disputes arising from these Terms will be subject to the exclusive jurisdiction of the courts of Maharashtra, India.',
          ),
          const SizedBox(height: 20),

          // 9. WhatsApp Support Quick Action
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
                    Icon(Icons.live_help_rounded, color: Color(0xFF00A84D), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Questions About Our Terms?',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reach out directly to our driver support team on WhatsApp for any clarifications.',
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
                      'Ask Support on WhatsApp',
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

  Widget _buildSpecialNoticeCard({
    required String badge,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
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
              Icon(icon, color: const Color(0xFF1E293B), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
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
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard({
    required String number,
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
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
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
