# AutoRide Accept - Enterprise Multi-Service Auto Acceptor

Enterprise-level automatic ride/delivery acceptance app for Android supporting multiple service providers with clean architecture.

## 📱 Supported Services

- **Ola** - Ride • Auto • Bike • Cab
- **Uber** - Ride • Bike • Auto • XL
- **Rapido** - Bike • Auto
- **Porter** - Delivery • Truck • Tempo  
- **Swiggy** - Food • Grocery
- **Zapto (Zepto)** - Grocery • Quick Commerce

## 🏗️ Architecture

Clean Architecture with separation of concerns:

```
lib/
├── core/                      # Core utilities & constants
│   ├── constants/             # App-wide constants & service IDs
│   ├── di/                    # Dependency injection
│   ├── theme/                 # App theme & colors
│   └── utils/                 # Utility classes
├── data/                      # Data layer
│   ├── datasources/           # Local storage services
│   ├── models/                # JSON serialization models
│   └── repositories/          # Repository implementations
├── domain/                    # Business logic layer
│   ├── entities/              # Business entities
│   ├── repositories/          # Repository interfaces
│   └── usecases/              # Business use cases
├── presentation/              # UI layer
│   ├── providers/             # State management
│   ├── screens/               # App screens
│   │   ├── splash/            # Splash screen
│   │   ├── service_selection/ # Service selection
│   │   ├── dashboard/         # Main dashboard
│   │   └── settings/          # Service settings
│   └── widgets/               # Reusable widgets
└── config/                    # Configuration
    └── services/              # Service-specific configs
```

## ✨ Features

### Accessibility Service Integration
- ✅ **Auto-Accept Engine** - Monitors ride/delivery apps in real-time
- ✅ **Porter Integration** - Full support based on research (fare, distance extraction)
- ✅ **Smart Filtering** - Accepts only orders matching your rules
- ✅ **Highest Fare Priority** - Automatically selects best paying orders

### Service Management
- ✅ **Multi-Service Support** - Enable/disable multiple services simultaneously
- ✅ **Individual Configuration** - Customize settings for each service
- ✅ **Brand Colors** - Each service has its own theme & icons
- ✅ **Package ID Mapping** - Accurate package identification for each service

### Auto Accept Rules
- ✅ **Fare Filters** - Set minimum and maximum fare limits (₹50-₹1000)
- ✅ **Distance Filters** - Control pickup distance (0.5-10 km) and trip distance (2-50 km)
- ✅ **Payment Methods** - Choose Cash, UPI, or Online payment
- ✅ **Vehicle Types** - Select specific vehicle types (Bike, Auto, Cab, XL, Truck, Tempo)

### Monitoring
- ✅ **Real-time Dashboard** - Monitor all active services
- ✅ **Activity Feed** - Track accepted rides with timestamp and fare
- ✅ **Service Status** - See auto-accept status for each service
- ✅ **Quick Actions** - Fast access to common operations

## 🎨 Design Patterns

- **Clean Architecture** - Separation of concerns across layers
- **Repository Pattern** - Abstraction of data sources
- **Provider Pattern** - State management with ChangeNotifier
- **Dependency Injection** - Centralized DI container
- **Use Case Pattern** - Single responsibility for business logic

## 🚀 Setup Instructions

### 1. Install the App
```bash
flutter install -d <device-id>
```

### 2. Enable Accessibility Service
**Critical Step for Auto-Accept:**

1. Open **Settings** on your Android device
2. Go to **Accessibility**
3. Find **AutoRide Accept** in the list
4. Toggle it **ON**
5. Confirm permission when prompted

**Why needed:** Accessibility service allows the app to monitor and interact with Porter, Ola, Uber, Rapido, Swiggy, and Zapto apps to automatically accept orders.

### 3. Configure Services
1. Open AutoRide Accept app
2. Select services you want to monitor
3. Configure settings for each:
   - Min/Max fare
   - Pickup distance
   - Trip distance
   - Payment method
   - Vehicle types

### 4. Start Monitoring
1. Tap green **Start** button on dashboard
2. Open Porter/Ola/Uber app
3. App will automatically accept matching orders

---

## 🔧 Porter Auto-Accept Research

Based on extensive research (`research/Auto_Accept_Research.md`), the app:

### Detects Orders Using:
- **Resource IDs**: `acceptOrderCard`, `tvAmount`, `dryRun`
- **Data Extraction**: Fare (₹), Distance (km), Pickup, Drop addresses
- **Package**: `in.porter.rider`

### Acceptance Logic:
1. Detects all orders in tray
2. Extracts fare & distance from each
3. Filters by max distance (user setting)
4. Sorts by fare (highest first)
5. Clicks accept on best order

### Research Highlights:
- **Fare extraction**: `TrayDriverFare.f59535b.f59539b`
- **Distance**: `TrayDryRun.f59537a` (km from location)
- **Order ID**: `TrayOrder.f59541a`
- **Surge support**: `TrayDriverFare.f59536c` (multiplier)

---

## Development Setup

### Prerequisites
- Flutter SDK (3.11.4 or higher)
- Android Studio / VS Code
- Android SDK

### Installation
1. Clone or navigate to this project directory
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App
```bash
flutter run
```

### Building APK
```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure
```
lib/
  └── main.dart          # Main app file with UI and logic
android/
  └── app/
      ├── build.gradle.kts
      └── src/main/AndroidManifest.xml
```

## Version
- **Version**: 1.0.0+1

---
Created with Flutter 💙
