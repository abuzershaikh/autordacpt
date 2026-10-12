import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/localization/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/datasources/telemetry_service.dart';
import 'data/datasources/free_rides_service.dart';
import 'services/analytics/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global Crashlytics hooks for unhandled exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    TelemetryService().reportCrash(
      errorMessage: details.exceptionAsString(),
      stackTrace: details.stack?.toString() ?? '',
      screenName: details.library ?? 'FlutterFramework',
      isFatal: false,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    TelemetryService().reportCrash(
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
      screenName: 'PlatformRoot',
      isFatal: true,
    );
    return true;
  };

  // Initialize dependency injection
  final di = InjectionContainer();
  await di.init();
  
  // Initialize Firebase with configured options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully!');
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Initialize Enterprise Telemetry & Sync Remote Settings
  try {
    final telemetry = TelemetryService();
    await telemetry.init();
    await AnalyticsService().init();
    await FreeRidesService().syncFromVps();
  } catch (e) {
    debugPrint('Telemetry init warning: $e');
  }
  
  runApp(RideAutoAcceptApp(di: di));
}

class RideAutoAcceptApp extends StatelessWidget {
  final InjectionContainer di;
  
  const RideAutoAcceptApp({super.key, required this.di});

  @override
  Widget build(BuildContext context) {
    final analyticsObserver = AnalyticsService().observer;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: di.serviceProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'AutoRide Accept',
            debugShowCheckedModeBanner: false,
            locale: Locale(langProvider.currentLanguageCode),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            navigatorObservers: [
              ?analyticsObserver,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

