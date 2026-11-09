import 'package:flutter/material.dart';
import '../../emergency/presentation/emergency_session_screen.dart';

/// Compatibility wrapper for the former AssistSessionScreen.
/// Re-routes to the primary EmergencySessionScreen.
class AssistSessionScreen extends StatelessWidget {
  final String? sessionId;

  const AssistSessionScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return EmergencySessionScreen(sessionId: sessionId);
  }
}
