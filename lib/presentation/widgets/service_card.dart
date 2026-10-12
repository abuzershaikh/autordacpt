import 'package:flutter/material.dart';
import '../../domain/entities/service_entity.dart';
import '../../config/services/service_config.dart';
import '../../core/theme/app_colors.dart';

/// Service card widget to display service information
class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isEnabled;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isEnabled,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = ServiceConfig.getBrandColor(service.type);
    final icon = ServiceConfig.getServiceIcon(service.type);

    return Card(
      elevation: isEnabled ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEnabled
            ? BorderSide(color: brandColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Tappable area for navigation (icon + text)
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    // Service Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: brandColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Service Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isEnabled ? brandColor : AppColors.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Settings Icon Button
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.settings_outlined,
                color: brandColor,
              ),
              tooltip: 'Settings',
              splashRadius: 24,
            ),

            const SizedBox(width: 4),

            // Toggle Switch (separate from tappable area)
            GestureDetector(
              onTap: () => onToggle(!isEnabled),
              child: Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: brandColor,
                ),
              ),
            ),

            // Checkmark when enabled
            if (isEnabled)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: brandColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
