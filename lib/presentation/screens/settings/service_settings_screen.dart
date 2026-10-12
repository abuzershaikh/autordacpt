import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/service_type.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../config/services/service_config.dart';
import '../../providers/service_provider.dart';
import '../../widgets/setting_section.dart';

/// Settings screen for individual service configuration
class ServiceSettingsScreen extends StatefulWidget {
  final ServiceType serviceType;

  const ServiceSettingsScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<ServiceSettingsScreen> createState() => _ServiceSettingsScreenState();
}

class _ServiceSettingsScreenState extends State<ServiceSettingsScreen> {
  late ServiceEntity service;
  late RideFilters filters;
  late PaymentMethod paymentMethod;
  late List<VehicleType> selectedVehicles;
  late bool autoAccept;

  @override
  void initState() {
    super.initState();
    _loadServiceSettings();
  }

  void _loadServiceSettings() {
    final provider = context.read<ServiceProvider>();
    service = provider.getService(widget.serviceType) ?? 
              ServiceConfig.getDefaultService(widget.serviceType);
    
    filters = service.settings.rideFilters;
    paymentMethod = service.settings.paymentMethod;
    selectedVehicles = List.from(service.settings.vehicleTypes);
    autoAccept = service.settings.autoAccept;
  }

  Future<void> _saveSettings() async {
    final provider = context.read<ServiceProvider>();
    final newSettings = ServiceSettings(
      autoAccept: autoAccept,
      rideFilters: filters,
      paymentMethod: paymentMethod,
      vehicleTypes: selectedVehicles,
    );

    await provider.updateServiceSettings(widget.serviceType, newSettings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${service.name} settings saved'),
          backgroundColor: ServiceConfig.getBrandColor(widget.serviceType),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = ServiceConfig.getBrandColor(widget.serviceType);
    final icon = ServiceConfig.getServiceIcon(widget.serviceType);

    return Scaffold(
      appBar: AppBar(
        title: Text('${service.name} Settings'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Header with Service Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: brandColor.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: brandColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: brandColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        service.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: service.isEnabled,
                  onChanged: (value) {
                    context.read<ServiceProvider>().toggleService(widget.serviceType, value);
                    setState(() {
                      service = service.copyWith(isEnabled: value);
                    });
                  },
                  activeColor: brandColor,
                ),
              ],
            ),
          ),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Auto Accept Toggle
                SettingSection(
                  title: 'Auto Accept',
                  icon: Icons.check_circle_outline,
                  color: brandColor,
                  child: SwitchListTile(
                    title: const Text('Automatically accept rides'),
                    subtitle: const Text('Accept rides based on your rules'),
                    value: autoAccept,
                    onChanged: (value) {
                      setState(() => autoAccept = value);
                    },
                    activeColor: brandColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Ride Filters
                SettingSection(
                  title: 'Ride Filters',
                  icon: Icons.filter_alt_outlined,
                  color: brandColor,
                  child: Column(
                    children: [
                      // Minimum Fare
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Minimum Fare',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '₹${filters.minFare}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: brandColor,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: filters.minFare.toDouble(),
                              min: 0,
                              max: 500,
                              divisions: 50,
                              label: '₹${filters.minFare}',
                              activeColor: brandColor,
                              onChanged: (value) {
                                setState(() {
                                  filters = filters.copyWith(minFare: value.toInt());
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Maximum Fare
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Maximum Fare',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '₹${filters.maxFare}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: brandColor,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: filters.maxFare.toDouble().clamp(100.0, 25000.0),
                              min: 100,
                              max: 25000,
                              divisions: 249,
                              label: '₹${filters.maxFare}',
                              activeColor: brandColor,
                              onChanged: (value) {
                                setState(() {
                                  filters = filters.copyWith(maxFare: value.toInt());
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // Pickup Distance
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Pickup Distance',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${filters.pickupDistance.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: brandColor,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: filters.pickupDistance.clamp(0.5, 50.0),
                              min: 0.5,
                              max: 50,
                              divisions: 99,
                              label: '${filters.pickupDistance.toStringAsFixed(1)} km',
                              activeColor: brandColor,
                              onChanged: (value) {
                                setState(() {
                                  filters = filters.copyWith(pickupDistance: value);
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Trip Distance
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Trip Distance',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${filters.tripDistance.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: brandColor,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: filters.tripDistance.clamp(1.0, 3000.0),
                              min: 1,
                              max: 3000,
                              divisions: 2999,
                              label: '${filters.tripDistance.toStringAsFixed(1)} km',
                              activeColor: brandColor,
                              onChanged: (value) {
                                setState(() {
                                  filters = filters.copyWith(tripDistance: value);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Save Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
