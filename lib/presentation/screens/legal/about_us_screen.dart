import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

/// About Us Screen presenting SnapRider mission, core driver safety values,
/// app version, supported platforms, and quick links to policies.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final isHindi = langCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isHindi ? 'हमारे बारे में (About Us)' : 'About SnapRider',
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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. App Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF076632), Color(0xFF0F9D58), Color(0xFF00C853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo with golden border
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFFFC107),
                        child: const Icon(Icons.electric_rickshaw, color: Colors.black87, size: 36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'SnapRider',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  isHindi
                      ? 'ड्राइवर पार्टनर का भरोसेमंद साथी'
                      : 'India\'s #1 Assistive Driver Utility',
                  style: const TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Version 1.0.8 (Build 9) • Production Stable',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Our Mission
          _buildMissionCard(
            title: 'Our Mission & Vision',
            icon: Icons.rocket_launch_rounded,
            accentColor: const Color(0xFFFF6E00),
            content:
                'Driving on Indian roads requires 100% focus and vigilance. Unfortunately, drivers are forced '
                'to constantly look down at incoming ride cards on Ola, Uber, Rapido, and Porter, leading to dangerous distracted driving.\n\n'
                'SnapRider was created to solve this problem: our smart accessibility engine evaluates fares and distances '
                'and auto-accepts your ideal rides in 1 millisecond, so you can keep your eyes on the road and both hands on the wheel.',
          ),
          const SizedBox(height: 14),

          // 3. Four Core Pillars
          const Text(
            'Core Pillars of SnapRider',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          _buildPillarTile(
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFF00A84D),
            title: 'Road Safety First',
            description: 'Reduces distracted driving and screen-tapping while in moving traffic.',
          ),
          const SizedBox(height: 8),

          _buildPillarTile(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF2196F3),
            title: '1ms Instant Acceptance',
            description: 'High-speed deterministic filter prevents you from missing profitable bookings.',
          ),
          const SizedBox(height: 8),

          _buildPillarTile(
            icon: Icons.route_rounded,
            iconColor: const Color(0xFFFF6E00),
            title: 'Dead-Mileage Protection',
            description: 'Eliminates far-away 6-8 km pickups that waste petrol, gas, and valuable time.',
          ),
          const SizedBox(height: 8),

          _buildPillarTile(
            icon: Icons.lock_person_rounded,
            iconColor: const Color(0xFF7B1FA2),
            title: '100% Driver Privacy',
            description: 'Runs locally on your device. Zero keystroke logging, zero personal data tracking.',
          ),
          const SizedBox(height: 18),

          // 4. Compatible Driver Apps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF00A84D), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Universal Compatibility',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Engineered to seamlessly inspect and accept rides across India\'s leading driver partner apps:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAppChip('🚖 Ola Partner', const Color(0xFFFFD54F)),
                    _buildAppChip('🚗 Uber Driver', const Color(0xFFE2E8F0)),
                    _buildAppChip('🛵 Rapido Captain', const Color(0xFFFFE082)),
                    _buildAppChip('🚚 Porter Driver', const Color(0xFFBBDEFB)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 5. Quick Links to Legal & Support
          const Text(
            'Legal & Information Links',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          _buildNavigationTile(
            context: context,
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our data handling and accessibility disclosures',
            destination: const PrivacyPolicyScreen(),
          ),
          const SizedBox(height: 8),

          _buildNavigationTile(
            context: context,
            icon: Icons.gavel_rounded,
            title: 'Terms & Conditions',
            subtitle: 'Review driver rules and non-affiliation disclaimers',
            destination: const TermsConditionsScreen(),
          ),
          const SizedBox(height: 8),

          _buildNavigationTile(
            context: context,
            icon: Icons.headset_mic_rounded,
            title: 'Contact Us',
            subtitle: 'Reach our 24/7 dedicated WhatsApp support desk',
            destination: const ContactUsScreen(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
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

  Widget _buildPillarTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00A84D), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
