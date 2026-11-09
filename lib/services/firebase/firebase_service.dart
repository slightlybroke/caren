import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the initialization state and diagnostic message for Firebase services.
class FirebaseState {
  final bool isInitialized;
  final String? errorMessage;
  final String statusDescription;

  const FirebaseState({
    required this.isInitialized,
    this.errorMessage,
    required this.statusDescription,
  });

  factory FirebaseState.uninitialized() => const FirebaseState(
        isInitialized: false,
        statusDescription: 'Firebase not yet initialized.',
      );

  factory FirebaseState.configured() => const FirebaseState(
        isInitialized: true,
        statusDescription: 'Firebase services connected and operational.',
      );

  factory FirebaseState.configurationPending(String details) => FirebaseState(
        isInitialized: false,
        errorMessage: details,
        statusDescription:
            'Firebase configuration pending (add google-services.json to android/app).',
      );
}

class FirebaseService {
  static FirebaseState _state = FirebaseState.uninitialized();

  static FirebaseState get state => _state;
  static bool get isInitialized => _state.isInitialized;

  /// Safely attempts to initialize Firebase.
  /// If google-services.json or credentials are not yet present,
  /// it fails gracefully without terminating the application.
  static Future<FirebaseState> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _state = FirebaseState.configured();
        return _state;
      }

      await Firebase.initializeApp();
      _state = FirebaseState.configured();
      developer.log('Firebase initialized successfully', name: 'FirebaseService');
    } catch (e, stack) {
      final msg = e.toString();
      developer.log(
        'Firebase initialization bypassed or failed: $msg',
        name: 'FirebaseService',
        error: e,
        stackTrace: stack,
      );
      _state = FirebaseState.configurationPending(msg);
    }
    return _state;
  }
}

/// Riverpod provider for the global Firebase state.
final firebaseStateProvider = Provider<FirebaseState>((ref) {
  return FirebaseService.state;
});

