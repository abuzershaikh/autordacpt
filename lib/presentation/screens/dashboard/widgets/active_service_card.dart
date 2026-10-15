import 'package:flutter/material.dart';
import '../../../../domain/entities/service_entity.dart';
import '../../../../config/services/service_config.dart';
import '../../../../core/theme/app_colors.dart';

/// Card showing active service with monitoring status
class ActiveServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isMonitoring;
  final VoidCallback onTap;
  final VoidCallback onSimulate;

  const ActiveServiceCard({
    super.key,
    required this.service,
    required this.isMonitoring,
    required this.onTap,
    required this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = ServiceConfig.getBrandColor(service.type);
    final icon = ServiceConfig.getServiceIcon(service.type);
    final autoAccept = service.settings.autoAccept;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMonitoring && autoAccept ? brandColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Tappable area (icon + name + status)
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        // Service Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: brandColor, size: 24),
                        ),
                        const SizedBox(width: 12),

                        // Service Name & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isMonitoring && autoAccept
                                          ? AppColors.success
                                          : AppColors.grey400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      autoAccept
                                          ? (isMonitoring ? 'Auto-accepting' : 'Ready')
                                          : 'Manual mode',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Simulate Button (for testing) - separate from tappable area
                if (isMonitoring) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onSimulate,
                    icon: const Icon(Icons.add_circle_outline),
                    color: brandColor,
                    tooltip: 'Simulate ride',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Settings Summary
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  context,
                  Icons.currency_rupee,
                  '₹${service.settings.rideFilters.minFare}-${service.settings.rideFilters.maxFare}',
                  brandColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.location_on_outlined,
                  service.settings.rideFilters.pickupDistance <= 0.0
                      ? 'Any pickup'
                      : '${service.settings.rideFilters.pickupDistance.toStringAsFixed(1)} km',
                  brandColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.payment,
                  service.settings.paymentMethod.displayName,
                  brandColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.directions_car,
                  '${service.settings.vehicleTypes.length} type${service.settings.vehicleTypes.length != 1 ? 's' : ''}',
                  brandColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Configure Settings Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Configure Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  side: BorderSide(color: brandColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
