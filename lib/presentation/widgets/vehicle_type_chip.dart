import 'package:flutter/material.dart';
import '../../domain/entities/service_entity.dart';

/// Vehicle type chip widget
class VehicleTypeChip extends StatelessWidget {
  final VehicleType vehicleType;
  final bool isSelected;
  final Color brandColor;
  final VoidCallback onTap;

  const VehicleTypeChip({
    super.key,
    required this.vehicleType,
    required this.isSelected,
    required this.brandColor,
    required this.onTap,
  });

  IconData _getVehicleIcon() {
    switch (vehicleType) {
      case VehicleType.bike:
        return Icons.two_wheeler;
      case VehicleType.auto:
        return Icons.electric_rickshaw;
      case VehicleType.cab:
        return Icons.local_taxi;
      case VehicleType.xl:
        return Icons.airport_shuttle;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.tempo:
        return Icons.fire_truck;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? brandColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getVehicleIcon(),
              color: isSelected ? brandColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                vehicleType.displayName,
                style: TextStyle(
                  color: isSelected ? brandColor : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                color: brandColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
