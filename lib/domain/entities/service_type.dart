/// Enum for supported service types
enum ServiceType {
  service1,
  service2;

  String get displayName {
    switch (this) {
      case ServiceType.service1:
        return 'Service 1';
      case ServiceType.service2:
        return 'Service 2';
    }
  }

  String get packageId {
    switch (this) {
      case ServiceType.service1:
        return 'com.rapido.rider';
      case ServiceType.service2:
        return 'in.porter.rider';
    }
  }

  String get category {
    switch (this) {
      case ServiceType.service1:
        return 'Ride Orders';
      case ServiceType.service2:
        return 'Delivery Orders';
    }
  }
}
