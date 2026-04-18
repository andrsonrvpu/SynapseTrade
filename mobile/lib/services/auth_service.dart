import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth service — google_sign_in v7 + Firebase Auth.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Initialize GoogleSignIn (must call once before authenticate) ────────────
  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
  }

  // ── Google Sign-In (v7 API) ────────────────────────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // Listen for the sign-in event from the stream
      final Completer<GoogleSignInAccount?> completer = Completer();

      // Listen to authentication events stream
      late StreamSubscription sub;
      sub = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          sub.cancel();
          if (event is GoogleSignInAuthenticationEventSignIn) {
            completer.complete(event.user);
          } else {
            completer.complete(null);
          }
        },
        onError: (e) {
          sub.cancel();
          completer.completeError(e);
        },
      );

      // Trigger authentication
      final result = await GoogleSignIn.instance.authenticate();
      if (result == null) {
        sub.cancel();
        return AuthResult.cancelled();
      }

      // Wait for stream or use result directly
      GoogleSignInAccount? googleUser;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      googleUser = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => result,
      );

      if (googleUser == null) return AuthResult.cancelled();

      // Get ID token from authentication
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await _saveUserProfile(userCredential.user!);
      notifyListeners();
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Error con Google: $e');
    }
  }

  // ── Email / Password Sign-In ───────────────────────────────────────────────
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  // ── Email / Password Register ──────────────────────────────────────────────
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();
      await _saveUserProfile(
        _auth.currentUser ?? userCredential.user!,
        name: displayName,
      );

      notifyListeners();
      return AuthResult.success(_auth.currentUser ?? userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Error al registrar: $e');
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null,
          message: 'Correo de recuperación enviado.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
    notifyListeners();
  }

  // ── Firestore Profile ──────────────────────────────────────────────────────
  Future<void> _saveUserProfile(User user, {String? name}) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName ?? 'Trader',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'plan': 'free',
        'metaApiToken': '',
        'metaApiAccountId': '',
        'riskPercent': 1.5,
        'autoTradingEnabled': false,
        'totalProfit': 0.0,
        'totalTrades': 0,
        'winRate': 0.0,
      });
    } else {
      await ref.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> saveBrokerCredentials({
    required String token,
    required String accountId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'metaApiToken': token,
      'metaApiAccountId': accountId,
    });
  }

  Future<void> updateTradingStats({
    required double profit,
    required bool win,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'totalProfit': FieldValue.increment(profit),
      'totalTrades': FieldValue.increment(1),
    });
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tus datos.';
      default:
        return 'Error de autenticación ($code).';
    }
  }
}

class AuthResult {
  final bool success;
  final bool cancelled;
  final User? user;
  final String? error;
  final String? message;

  const AuthResult._({
    required this.success,
    this.cancelled = false,
    this.user,
    this.error,
    this.message,
  });

  factory AuthResult.success(User? user, {String? message}) =>
      AuthResult._(success: true, user: user, message: message);

  factory AuthResult.error(String error) =>
      AuthResult._(success: false, error: error);

  factory AuthResult.cancelled() =>
      AuthResult._(success: false, cancelled: true);
}
