import 'package:flutter/material.dart';
import '../../emergency/presentation/emergency_landing_screen.dart';

/// Compatibility wrapper for the former AssistLandingScreen.
/// Re-routes to the primary EmergencyLandingScreen.
class AssistLandingScreen extends StatelessWidget {
  const AssistLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmergencyLandingScreen();
  }
}
