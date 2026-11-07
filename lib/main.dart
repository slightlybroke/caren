import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Root app wrapped with Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: CarenApp(),
    ),
  );
}
