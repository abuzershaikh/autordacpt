import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

/// Deprecated: Service selection is no longer used as services
/// are auto-detected in the background based on custom rules.
@deprecated
class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
