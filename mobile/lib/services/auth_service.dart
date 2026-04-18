import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth service — handles Google, email/password, and user profiles.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Save/update user profile in Firestore
      await _saveUserProfile(userCredential.user!);

      notifyListeners();
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Error al iniciar sesión con Google: $e');
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

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();

      // Save profile to Firestore
      await _saveUserProfile(userCredential.user!, name: displayName);

      notifyListeners();
      return AuthResult.success(userCredential.user!);
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
      return AuthResult.success(null, message: 'Correo de recuperación enviado.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  // ── Firestore Profile ──────────────────────────────────────────────────────
  Future<void> _saveUserProfile(User user, {String? name}) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // New user
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
      // Returning user — update last login
      await ref.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
      });
    }
  }

  // ── Get User Profile from Firestore ───────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // ── Update broker credentials in Firestore ────────────────────────────────
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

  // ── Save trading stats ─────────────────────────────────────────────────────
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

  // ── Error mapping ──────────────────────────────────────────────────────────
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

/// Result object for auth operations.
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
