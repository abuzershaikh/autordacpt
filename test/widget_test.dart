// Basic Flutter test for Rapido and Porter service configuration

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autorideacceptor/core/di/injection_container.dart';
import 'package:autorideacceptor/domain/entities/service_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Service Configuration Tests', () {
    late InjectionContainer di;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      di = InjectionContainer();
      await di.init();
    });

    test('Dependency injection initializes correctly', () {
      expect(di.serviceRepository, isNotNull);
      expect(di.serviceProvider, isNotNull);
    });

    test('Supported services load with correct configuration', () async {
      final services = await di.serviceRepository.getAllServices();
      
      expect(services.length, equals(2)); // Rapido & Porter
      expect(services.any((s) => s.type == ServiceType.service1), isTrue);
      expect(services.any((s) => s.type == ServiceType.service2), isTrue);
    });

    test('Service can be toggled on and off', () async {
      await di.serviceRepository.toggleService(ServiceType.service1, true);
      var service = await di.serviceRepository.getService(ServiceType.service1);
      expect(service?.isEnabled, isTrue);

      await di.serviceRepository.toggleService(ServiceType.service1, false);
      service = await di.serviceRepository.getService(ServiceType.service1);
      expect(service?.isEnabled, isFalse);
    });

    test('Each service has correct package ID', () async {
      final services = await di.serviceRepository.getAllServices();
      
      final rapido = services.firstWhere((s) => s.type == ServiceType.service1);
      expect(rapido.packageId, equals('com.rapido.rider'));
      
      final porter = services.firstWhere((s) => s.type == ServiceType.service2);
      expect(porter.packageId, equals('in.porter.rider'));
    });
  });
}
