import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/utils/logger.dart';

class DeviceDetails {
  final String brand;
  final String model;
  final String manufacturer;
  final String androidVersion;
  final int sdkInt;

  const DeviceDetails({
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdkInt,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'manufacturer': manufacturer,
      'androidVersion': androidVersion,
      'sdkInt': sdkInt,
    };
  }

  factory DeviceDetails.fallback() {
    return const DeviceDetails(
      brand: 'Android Device',
      model: 'Unknown',
      manufacturer: 'Unknown',
      androidVersion: 'Unknown',
      sdkInt: 0,
    );
  }
}

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        
        // Capitalize first letter of brand (e.g. samsung -> Samsung)
        String brand = androidInfo.brand;
        if (brand.isNotEmpty) {
          brand = brand[0].toUpperCase() + brand.substring(1);
        }

        return DeviceDetails(
          brand: brand.isNotEmpty ? brand : 'Android',
          model: androidInfo.model,
          manufacturer: androidInfo.manufacturer,
          androidVersion: 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
          sdkInt: androidInfo.version.sdkInt,
        );
      }
    } catch (e) {
      Logger.error('Failed to get device info', error: e);
    }
    return DeviceDetails.fallback();
  }
}
