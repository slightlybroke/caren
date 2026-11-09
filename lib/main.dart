import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'services/firebase/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase services if configured
  await FirebaseService.initialize();

  // Root app wrapped with Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: CarenApp(),
    ),
  );
}
