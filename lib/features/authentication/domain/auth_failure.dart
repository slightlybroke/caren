import '../../../core/errors/failures.dart';

/// Authentication-related failures and user-friendly error mappings.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.fromCode(String code, [String? customMessage]) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          message: 'The email address or password entered does not match our records.',
          code: 'INVALID_CREDENTIALS',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          message: 'An account with this email address already exists.',
          code: 'EMAIL_ALREADY_IN_USE',
        );
      case 'invalid-email':
        return const AuthFailure(
          message: 'Please enter a valid email address.',
          code: 'INVALID_EMAIL',
        );
      case 'weak-password':
        return const AuthFailure(
          message: 'The password must be at least 6 characters long.',
          code: 'WEAK_PASSWORD',
        );
      case 'user-disabled':
        return const AuthFailure(
          message: 'This account has been disabled. Please contact support.',
          code: 'USER_DISABLED',
        );
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many unsuccessful attempts. Please wait a moment and try again.',
          code: 'TOO_MANY_REQUESTS',
        );
      case 'network-request-failed':
        return const AuthFailure(
          message: 'Network connection issue. Please check your internet connection.',
          code: 'NETWORK_ERROR',
        );
      case 'firebase-not-configured':
        return const AuthFailure(
          message: 'Firebase is not yet configured for this installation. Please add google-services.json.',
          code: 'FIREBASE_NOT_CONFIGURED',
        );
      default:
        return AuthFailure(
          message: customMessage ?? 'An unexpected authentication error occurred.',
          code: code,
        );
    }
  }
}

