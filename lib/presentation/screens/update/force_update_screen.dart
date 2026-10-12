import 'package:flutter/material.dart';
import '../../../data/datasources/version_check_service.dart';

class ForceUpdateScreen extends StatefulWidget {
  final AppVersionStatus versionStatus;
  final VoidCallback? onRetryCheck;

  const ForceUpdateScreen({
    super.key,
    required this.versionStatus,
    this.onRetryCheck,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDownload() async {
    setState(() => _isDownloading = true);
    final url = widget.versionStatus.downloadUrl;
    final launched = await VersionCheckService().launchDownloadUrl(url);
    if (mounted) {
      setState(() => _isDownloading = false);
      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Chrome me APK download shuru ho raha hai...'),
            backgroundColor: Color(0xFF00A84D),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download URL open nahi hua: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.versionStatus;
    final isBlocked = status.isBlocked;

    return PopScope(
      canPop: false, // Strictly non-dismissible
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium deep dark slate
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Pulsing Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isBlocked
                              ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                              : [const Color(0xFF00A84D), const Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isBlocked ? Colors.red : const Color(0xFF00A84D)).withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isBlocked ? Icons.block_flipped : Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Urgent Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBlocked ? const Color(0x33EF4444) : const Color(0x3300C853),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF00C853),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBlocked ? Icons.gpp_bad_rounded : Icons.system_update_rounded,
                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF00E676),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBlocked ? 'VERSION DISABLED' : 'MANDATORY UPDATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Title (Configured by admin in VPS)
                  Text(
                    status.updateTitle.isNotEmpty
                        ? status.updateTitle
                        : (isBlocked ? 'Purana Version Band Ho Gaya Hai' : 'Naya Update Available Hai!'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Version Pill Comparison
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aapka Version: v${status.currentVersionName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF00E676), size: 16),
                        ),
                        Text(
                          'Naya: v${status.latestVersionName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Custom Message Card from Admin Panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.announcement_outlined, color: Color(0xFF38BDF8), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Update Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status.updateMessage.isNotEmpty
                              ? status.updateMessage
                              : 'Kripya latest version install karein. Purana version disabled ho gaya hai.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFFE2E8F0),
                            height: 1.45,
                          ),
                        ),
                        if (status.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(color: Color(0xFF334155), height: 1),
                          const SizedBox(height: 10),
                          Text(
                            'What\'s New in v${status.latestVersionName}:',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.releaseNotes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Download Button (Launches Chrome directly)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_for_offline_rounded, size: 22),
                      label: Text(
                        _isDownloading ? 'Opening Browser...' : '⬇️ Download & Install New Version',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A84D),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: const Color(0xFF00A84D).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Re-check Button
                  TextButton.icon(
                    onPressed: widget.onRetryCheck,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF94A3B8)),
                    label: const Text(
                      'Maine install kar liya / Refresh Status',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
