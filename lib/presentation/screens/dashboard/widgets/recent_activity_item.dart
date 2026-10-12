import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/ride_activity.dart';
import '../../../../config/services/service_config.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget to display recent ride activity item
class RecentActivityItem extends StatelessWidget {
  final RideActivity activity;

  const RecentActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = ServiceConfig.getBrandColor(activity.serviceType);
    final icon = ServiceConfig.getServiceIcon(activity.serviceType);
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: brandColor, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                activity.serviceName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: brandColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(activity.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.status.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(activity.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity.rideDetails,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              timeFormat.format(activity.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          '₹${activity.fare.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
        ),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return AppColors.success;
      case RideStatus.rejected:
        return AppColors.error;
      case RideStatus.completed:
        return AppColors.info;
      case RideStatus.cancelled:
        return AppColors.warning;
    }
  }
}
