import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/ride_activity.dart';
import '../../providers/service_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Rides', 'Today', 'This Week', 'Auto-Accepted'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServiceProvider>().loadRecentActivities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final realActivities = provider.recentActivities;

    // Filter activities based on selection
    final now = DateTime.now();
    final filteredActivities = realActivities.where((act) {
      if (_selectedFilterIndex == 1) {
        // Today
        return act.timestamp.year == now.year &&
            act.timestamp.month == now.month &&
            act.timestamp.day == now.day;
      } else if (_selectedFilterIndex == 2) {
        // This Week
        return now.difference(act.timestamp).inDays <= 7;
      } else if (_selectedFilterIndex == 3) {
        // Auto-Accepted only
        return act.status == RideStatus.accepted;
      }
      return true;
    }).toList();

    // Calculate totals from real activities
    int totalRides = realActivities.length;
    double totalFare = realActivities.fold(0.0, (acc, act) => acc + act.fare);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00A84D)),
            tooltip: 'Refresh',
            onPressed: () => provider.loadRecentActivities(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            tooltip: 'Clear History',
            onPressed: () => _confirmClearHistory(context, provider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadRecentActivities();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Stats Overview Summary Row
            _buildStatsOverview(totalRides, totalFare),
            const SizedBox(height: 14),

            // 2. Filter Chips
            _buildFilterChips(),
            const SizedBox(height: 14),

            // 3. Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity Records',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '$totalRides Orders',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00A84D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Real Provider Activities (if any) or Empty State
            if (filteredActivities.isEmpty)
              _buildEmptyState()
            else
              ...filteredActivities.map((act) => _buildRealActivityCard(act)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(int totalRides, double totalFare) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF076632), Color(0xFF148E49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF076632).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Accepted', '$totalRides', Icons.check_circle_outline),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatColumn('Fares Filtered', '₹${totalFare.toInt()}', Icons.currency_rupee),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatColumn('Avg Speed', '80ms', Icons.flash_on),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFEB3B), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilterIndex = index);
                }
              },
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              selectedColor: const Color(0xFF00A84D),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00A84D) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, color: Color(0xFF00A84D), size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Ride History Recorded',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Real auto-accepted orders from Rapido, Porter, Ola & Uber will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealActivityCard(RideActivity activity) {
    final isAccepted = activity.status == RideStatus.accepted;

    IconData serviceIcon;
    Color iconBg;
    Color iconColor;
    final svcLower = (activity.serviceType.name).toLowerCase();
    if (svcLower.contains('rapido')) {
      serviceIcon = Icons.two_wheeler_rounded;
      iconBg = const Color(0xFFFEF08A);
      iconColor = const Color(0xFFB45309);
    } else if (svcLower.contains('porter')) {
      serviceIcon = Icons.local_shipping_rounded;
      iconBg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF1D4ED8);
    } else if (svcLower.contains('ola')) {
      serviceIcon = Icons.directions_car_rounded;
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF15803D);
    } else if (svcLower.contains('uber')) {
      serviceIcon = Icons.local_taxi_rounded;
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF334155);
    } else {
      serviceIcon = Icons.electric_rickshaw_rounded;
      iconBg = const Color(0xFFE8F8F0);
      iconColor = const Color(0xFF00A84D);
    }

    final timeStr =
        '${activity.timestamp.day.toString().padLeft(2, '0')}/${activity.timestamp.month.toString().padLeft(2, '0')} • ${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              serviceIcon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.serviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '₹${activity.fare.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isAccepted ? const Color(0xFF00A84D) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activity.rideDetails,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isAccepted ? const Color(0xFFE8F8F0) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAccepted ? '✓ Auto Accepted' : 'Filtered Out',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isAccepted ? const Color(0xFF00A84D) : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, ServiceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Ride History'),
        content: const Text('Are you sure you want to clear recent activity records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
