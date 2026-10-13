import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../services/accessibility_service.dart';

/// Contact Us Screen featuring direct WhatsApp support integration,
/// phone copy, email dispatch, operating hours, and common driver FAQs.
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  static const String supportPhone = "919225278035";
  static const String displayPhone = "+91 9225278035";
  static const String supportEmail = "support@snaprider.in";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp([String? customMessage]) async {
    HapticFeedback.mediumImpact();
    final message = Uri.encodeComponent(
      customMessage ?? "Hello SnapRider Support, I need help with SnapRider app.",
    );
    final whatsappUrl = "whatsapp://send?phone=$supportPhone&text=$message";
    final webUrl = "https://wa.me/$supportPhone?text=$message";

    bool success = await AccessibilityService.openUrl(whatsappUrl);
    if (!success) {
      success = await AccessibilityService.openUrl(webUrl);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp. Number: $displayPhone'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _openEmail() async {
    HapticFeedback.lightImpact();
    final url = "mailto:$supportEmail?subject=SnapRider%20Driver%20Support%20Request";
    final success = await AccessibilityService.openUrl(url);
    if (!success && mounted) {
      _copyToClipboard(supportEmail, 'Email address copied to clipboard!');
    }
  }

  Future<void> _openPhoneDialer() async {
    HapticFeedback.lightImpact();
    final url = "tel:+$supportPhone";
    await AccessibilityService.openUrl(url);
  }

  void _copyToClipboard(String text, String message) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: const Color(0xFF00A84D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final isHindi = langCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isHindi ? 'संपर्क करें (Contact Us)' : 'Contact Us & Help Desk',
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
          // 1. WhatsApp Hero Card (Pulsing & Interactive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseScale.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/chat_support_icon.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.chat_bubble,
                              color: Color(0xFF25D366),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'WhatsApp Support',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFF69F0AE), size: 7),
                                      SizedBox(width: 4),
                                      Text(
                                        '24/7 ONLINE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isHindi
                                  ? 'सीधे चैट करें • तुरंत रिप्लाई मिलेगा'
                                  : 'Instant reply for active drivers',
                              style: const TextStyle(
                                color: Color(0xFFE8F5E9),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Phone number chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_android_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              displayPhone,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(displayPhone, 'Support number copied!'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, color: Color(0xFF075E54), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: Color(0xFF075E54),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Direct Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _openWhatsApp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF075E54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Open WhatsApp & Chat Now',
                            style: TextStyle(
                              color: Color(0xFF075E54),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Secondary Support Channels (Call & Email)
          Row(
            children: [
              // Phone Call
              Expanded(
                child: _buildContactChannelCard(
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Direct Call',
                  subtitle: displayPhone,
                  actionText: 'Dial Now',
                  onTap: _openPhoneDialer,
                ),
              ),
              const SizedBox(width: 12),
              // Email Support
              Expanded(
                child: _buildContactChannelCard(
                  icon: Icons.mail_rounded,
                  iconColor: const Color(0xFFFF6E00),
                  title: 'Email Us',
                  subtitle: supportEmail,
                  actionText: 'Send Mail',
                  onTap: _openEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Quick Help Topics
          const Text(
            'Quick Help & Common Topics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          _buildFaqItem(
            question: 'Recharge / Plan Activate nahi hua?',
            answer:
                'Payment complete hone par Razorpay status 1-2 minute me update ho jata hai. Agar fir bhi plan activate na ho, WhatsApp par payment screenshot bhej kar turant activate karwayein.',
            onWhatsAppAsk: () => _openWhatsApp("Payment done but plan not activated. Please verify."),
          ),
          const SizedBox(height: 10),

          _buildFaqItem(
            question: 'Accessibility Service baar-baar turn OFF ho rahi hai?',
            answer:
                'Android battery saver background processes ko kill karta hai. Phone Settings → Apps → SnapRider → Battery me jaakar "Unrestricted" select karein aur AutoStart enable karein.',
            onWhatsAppAsk: () => _openWhatsApp("Accessibility service keeps turning off on my phone. Need help."),
          ),
          const SizedBox(height: 10),

          _buildFaqItem(
            question: 'Ride offers accept kyu nahi ho rahe?',
            answer:
                '1. Check karein ki Dashboard par Auto-Accept switch ON hai.\n'
                '2. Min Fare aur Max Fare filter check karein ki kahin actual ride fare se zyada toh nahi.\n'
                '3. Pickup Distance limit badha kar check karein.',
            onWhatsAppAsk: () => _openWhatsApp("App is not accepting rides. Need help configuring settings."),
          ),
          const SizedBox(height: 20),

          // 4. Operating Hours & Address
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
                    Icon(Icons.access_time_filled_rounded, color: Color(0xFF00A84D), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Helpline Availability',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• WhatsApp Support: 24 Hours x 7 Days (Instant Priority Chat)\n'
                  '• Phone Helpline: 9:00 AM - 10:00 PM IST (Mon - Sun)\n'
                  '• Support Hub: Pune / Mumbai, Maharashtra, India',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactChannelCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionText,
                style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required VoidCallback onWhatsAppAsk,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF00A84D), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.45),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onWhatsAppAsk,
              icon: const Icon(Icons.chat, size: 14, color: Color(0xFF00A84D)),
              label: const Text(
                'Ask about this on WhatsApp',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF00A84D)),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }
}
