import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../../services/accessibility_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<Map<String, dynamic>> _diagnosticLogs = [];

  bool _isTesting = false;

  void _simulateRideEvent() async {
    setState(() => _isTesting = true);

    // Trigger REAL physical touch click via Accessibility Service
    final bool tapped = await AccessibilityService().testRealClick(x: 500, y: 1000);
    await Future.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} AM';

    setState(() {
      _diagnosticLogs.insert(0, {
        'time': timeStr,
        'type': tapped ? 'success' : 'warning',
        'title': tapped ? 'Asli Real Click Dispatched ✓' : 'Simulated Test Order Detected',
        'desc': tapped
            ? 'Real hardware touchscreen touch event (100ms) executed with haptic vibration.'
            : 'Simulated order evaluated. (Turn ON Accessibility in Settings for real touch injection).',
        'icon': tapped ? Icons.touch_app : Icons.warning_amber_rounded,
        'color': tapped ? const Color(0xFF00C853) : const Color(0xFFFF9800),
      });
      _isTesting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tapped
              ? '✓ Asli Real Hardware Touch Click Executed Successfully!'
              : '⚠️ Accessibility off: Turn ON service in Settings to inject real taps.'),
          backgroundColor: tapped ? const Color(0xFF00C853) : const Color(0xFFE65100),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final isServiceActive = provider.universalConfig.autoAccept;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Live Activity Monitor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00A84D)),
            tooltip: 'Refresh Diagnostics',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          // 1. Live Engine Status Card
          _buildLiveStatusCard(isServiceActive),
          const SizedBox(height: 14),

          // 2. Metrics 2x2 Grid
          _buildMetricsGrid(provider),
          const SizedBox(height: 16),

          // 3. Action Button: Simulate Ride Event
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _simulateRideEvent,
              icon: _isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.flash_on, color: Colors.white, size: 18),
              label: Text(
                _isTesting ? 'Simulating Click...' : 'Simulate Test Detection Event',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A84D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Activity Logs Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Diagnostic Event Stream',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live Stream',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A84D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Timeline Logs
          if (_diagnosticLogs.isEmpty)
            _buildEmptyLogsCard()
          else
            ..._diagnosticLogs.map((log) => _buildLogItem(log)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No Diagnostic Logs Yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live order evaluations and real click events will stream here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard(bool isServiceActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isServiceActive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isServiceActive ? const Color(0xFFE8F8F0) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isServiceActive ? Icons.radar : Icons.pause_circle_outline,
              color: isServiceActive ? const Color(0xFF00A84D) : const Color(0xFF94A3B8),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isServiceActive ? const Color(0xFF00C853) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isServiceActive ? 'Clicker Engine: ACTIVE' : 'Clicker Engine: IDLE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isServiceActive ? const Color(0xFF00A84D) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Accessibility screen node listener active • Monitoring all apps',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ServiceProvider provider) {
    final config = provider.universalConfig;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMetricCard(
                label: 'Response Speed',
                value: '${config.clickDelayMs}ms',
                subtitle: 'Super fast dispatch',
                icon: Icons.bolt,
                iconColor: const Color(0xFFEAB308),
                bgColor: const Color(0xFFFEFCE8),
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                label: 'Fare Filter',
                value: '₹${config.minFare.toInt()} - ₹${config.maxFare.toInt()}',
                subtitle: 'Active price window',
                icon: Icons.currency_rupee,
                iconColor: const Color(0xFF00A84D),
                bgColor: const Color(0xFFE8F8F0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildMetricCard(
                label: 'Max Pickup',
                value: '${config.pickupDistance.toStringAsFixed(1)} km',
                subtitle: 'Nearby orders only',
                icon: Icons.near_me,
                iconColor: const Color(0xFFFF6E00),
                bgColor: const Color(0xFFFFF7ED),
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                label: 'Sound & Vibrate',
                value: config.soundAlert && config.vibrationAlert ? 'Enabled' : 'Partial',
                subtitle: 'Instant driver notice',
                icon: Icons.notifications_active,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (log['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              log['icon'] as IconData,
              color: log['color'] as Color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      log['time'] as String,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log['desc'] as String,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
