import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
      return;
    }

    if (!_supportsNativeGoogleSignIn) {
      throw UnsupportedError(
        'Google sign-in is available on Android, iOS, macOS, and web.',
      );
    }

    await _initialize();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('Google sign-in is not available on this device.');
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google did not return an ID token.');
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (_supportsNativeGoogleSignIn) {
      try {
        await _initialize();
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase sign-out is complete; provider cleanup is best effort.
      }
    }
  }

  static Future<void> reauthenticateWithGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }
    await _initialize();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google did not return an ID token.');
    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.delete();
    if (_supportsNativeGoogleSignIn) {
      try {
        await _initialize();
        await _googleSignIn.disconnect();
      } catch (_) {}
    }
  }

  static Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize(
      clientId: _iosClientId,
      serverClientId: _serverClientId,
    );
  }

  static bool get _supportsNativeGoogleSignIn =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static String? get _iosClientId {
    const value = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    return value.isEmpty ? null : value;
  }

  static String? get _serverClientId {
    const value = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    return value.isEmpty ? null : value;
  }
}
