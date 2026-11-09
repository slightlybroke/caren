import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_service.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';

/// Contract for authentication operations in CAREN.
abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// Firebase-backed implementation of AuthRepository.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository([fb.FirebaseAuth? firebaseAuth])
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) {
        throw const AuthFailure(message: 'Sign in succeeded but user was null.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }
      final user = _mapUser(_firebaseAuth.currentUser ?? credential.user);
      if (user == null) {
        throw const AuthFailure(
            message: 'Registration succeeded but user was null.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }
}

/// In-memory mock repository used for testing and offline development fallback.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  final Map<String, String> _passwords = {};

  MockAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signInWithEmailAndPassword(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final normalized = email.trim().toLowerCase();
    if (_passwords.containsKey(normalized) &&
        _passwords[normalized] != password) {
      throw const AuthFailure(
        message: 'The email address or password entered does not match our records.',
        code: 'INVALID_CREDENTIALS',
      );
    }
    _currentUser = AuthUser(
      uid: 'mock_uid_${normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: normalized,
      displayName: normalized.split('@').first,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final normalized = email.trim().toLowerCase();
    _passwords[normalized] = password;
    _currentUser = AuthUser(
      uid: 'mock_uid_${normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: normalized,
      displayName: displayName ?? normalized.split('@').first,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider for the AuthRepository.
/// Dynamically uses FirebaseAuthRepository when Firebase is configured,
/// or MockAuthRepository when Firebase is pending local configuration.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final fbState = ref.watch(firebaseStateProvider);
  if (fbState.isInitialized) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

/// Stream of auth changes for the current user.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Synchronous access to current AuthUser, reactive to auth state changes.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.asData?.value ?? ref.watch(authRepositoryProvider).currentUser;
});
