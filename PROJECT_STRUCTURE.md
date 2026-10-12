# Project Structure Documentation

## Overview
This is an enterprise-level Flutter application following Clean Architecture principles with complete separation of concerns.

## Layer Architecture

### 1. **Core Layer** (`lib/core/`)
Foundation layer with shared utilities and constants.

#### Constants (`core/constants/`)
- `app_constants.dart` - App-wide constants, storage keys, default values
- `service_ids.dart` - Package IDs for all supported services

#### Theme (`core/theme/`)
- `app_colors.dart` - Color palette including brand colors for each service
- `app_theme.dart` - MaterialTheme configuration

#### Dependency Injection (`core/di/`)
- `injection_container.dart` - Centralized DI container managing all dependencies

#### Utils (`core/utils/`)
- `logger.dart` - Debug logging utility

---

### 2. **Domain Layer** (`lib/domain/`)
Business logic layer - framework independent.

#### Entities (`domain/entities/`)
Pure Dart objects representing business concepts:
- `service_entity.dart` - Service model with settings
- `service_type.dart` - Enum for service types
- `ride_activity.dart` - Ride activity tracking

#### Repositories (`domain/repositories/`)
Abstract interfaces:
- `service_repository.dart` - Contract for service data operations

#### Use Cases (`domain/usecases/`)
Single-responsibility business operations:
- `get_all_services.dart` - Fetch all available services
- `get_enabled_services.dart` - Get only enabled services
- `toggle_service.dart` - Enable/disable a service
- `update_service_settings.dart` - Update service configuration
- `get_ride_activities.dart` - Fetch ride history
- `get_ride_count.dart` - Get ride count per service
- `save_ride_activity.dart` - Save new ride activity

---

### 3. **Data Layer** (`lib/data/`)
Implementation of data operations.

#### Data Sources (`data/datasources/`)
- `local_storage_service.dart` - SharedPreferences wrapper with JSON support

#### Models (`data/models/`)
JSON serialization models:
- `service_model.dart` - Service with JSON conversion
- `ride_activity_model.dart` - Ride activity with JSON conversion

#### Repositories (`data/repositories/`)
Implementation of domain repository interfaces:
- `service_repository_impl.dart` - Concrete implementation using local storage

---

### 4. **Presentation Layer** (`lib/presentation/`)
UI and state management.

#### Providers (`presentation/providers/`)
State management with ChangeNotifier:
- `service_provider.dart` - Manages service state, rides, and UI updates

#### Screens (`presentation/screens/`)

**Splash Screen** (`screens/splash/`)
- Animated logo
- Auto-navigates based on setup state

**Service Selection** (`screens/service_selection/`)
- List all 6 services
- Enable/disable toggle
- Navigation to settings

**Dashboard** (`screens/dashboard/`)
- Active services monitoring
- Start/Stop monitoring
- Recent activity feed
- Quick actions
- Widgets:
  - `active_service_card.dart` - Shows service status
  - `recent_activity_item.dart` - Activity list item
  - `quick_action_button.dart` - Action buttons

**Settings** (`screens/settings/`)
- Individual service configuration
- Fare sliders
- Distance sliders
- Payment method selection
- Vehicle type chips

#### Widgets (`presentation/widgets/`)
Reusable UI components:
- `service_card.dart` - Service selection card
- `setting_section.dart` - Settings section container
- `vehicle_type_chip.dart` - Vehicle type selector

---

### 5. **Config Layer** (`lib/config/`)
Configuration and static data.

#### Services (`config/services/`)
- `service_config.dart` - Default settings, brand colors, icons, vehicle types per service

---

## Service Configuration

Each service has:
1. **Package ID** - Android package name
2. **Brand Color** - Unique color scheme
3. **Icon** - Service icon
4. **Default Settings**:
   - Min/Max fare range
   - Pickup distance
   - Trip distance  
   - Payment method
   - Supported vehicle types

### Service Details

| Service | Package ID | Default Min Fare | Default Max Fare |
|---------|-----------|------------------|------------------|
| Ola | com.olacabs.customer | ₹80 | ₹400 |
| Uber | com.ubercab | ₹70 | ₹500 |
| Rapido | com.rapido.passenger | ₹60 | ₹300 |
| Porter | in.porter.rider | ₹80 | ₹500 |
| Swiggy | in.swiggy.android | ₹50 | ₹200 |
| Zapto | com.app.zeptonow | ₹40 | ₹150 |

---

## Data Flow

### 1. User Action
```
User taps "Enable Ola"
    ↓
ServiceSelectionScreen
    ↓
ServiceProvider.toggleService()
```

### 2. Business Logic
```
ServiceProvider
    ↓
ServiceRepository.toggleService()
    ↓
ToggleService UseCase (if needed)
```

### 3. Data Persistence
```
ServiceRepositoryImpl
    ↓
LocalStorageService
    ↓
SharedPreferences
```

### 4. State Update
```
Repository updates data
    ↓
Provider notifyListeners()
    ↓
UI rebuilds automatically
```

---

## State Management

Using **Provider** pattern:
- `ServiceProvider` - Single source of truth for service state
- `ChangeNotifier` - Notifies listeners on state changes
- `Consumer<ServiceProvider>` - Rebuilds UI on state changes

---

## Testing

Tests verify:
1. ✅ Dependency injection initializes correctly
2. ✅ All 6 services load with proper configuration
3. ✅ Services can be toggled on/off
4. ✅ Each service has correct package ID

Run tests:
```bash
flutter test
```

---

## Build Commands

### Development
```bash
flutter run
```

### Release APK
```bash
flutter build apk --release
```

### Debug APK
```bash
flutter build apk --debug
```

---

## Dependencies

- `provider: ^6.1.2` - State management
- `shared_preferences: ^2.2.3` - Local data persistence
- `intl: ^0.19.0` - Date/time formatting

---

## Key Benefits of This Architecture

1. **Testability** - Each layer can be tested independently
2. **Maintainability** - Clear separation of concerns
3. **Scalability** - Easy to add new services or features
4. **Flexibility** - UI can be changed without affecting business logic
5. **Reusability** - Domain logic can be used in other platforms
6. **Clean Code** - SOLID principles applied throughout

---

## Adding a New Service

1. Add service to `ServiceType` enum
2. Add package ID to `ServiceIds`
3. Add brand color to `AppColors`
4. Add configuration in `ServiceConfig`
5. Service automatically appears in UI!

---

## Future Enhancements

- [ ] Background service for actual ride monitoring
- [ ] Accessibility service integration
- [ ] Notification system
- [ ] Statistics & analytics dashboard
- [ ] Global rules (apply to all services)
- [ ] Exclude areas/times
- [ ] Ride history export
- [ ] Cloud sync
