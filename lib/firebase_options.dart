import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _androidClientId = String.fromEnvironment(
    'FIREBASE_ANDROID_CLIENT_ID',
  );
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static FirebaseOptions get currentPlatform {
    // On the web, defaultTargetPlatform follows the browser user agent. An
    // Android phone therefore reports TargetPlatform.android even though
    // Firebase must still receive the web app ID.
    final nativeAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final nativeApple =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final appId = nativeAndroid
        ? _androidAppId
        : nativeApple && _iosAppId.isNotEmpty
        ? _iosAppId
        : _webAppId;

    if (_apiKey.isEmpty ||
        appId.isEmpty ||
        _messagingSenderId.isEmpty ||
        _projectId.isEmpty) {
      throw StateError('Missing Firebase configuration.');
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: kIsWeb ? _optional(_authDomain) : null,
      storageBucket: _optional(_storageBucket),
      androidClientId: nativeAndroid ? _optional(_androidClientId) : null,
      iosClientId: nativeApple ? _optional(_iosClientId) : null,
      iosBundleId: nativeApple ? _optional(_iosBundleId) : null,
    );
  }

  static String? _optional(String value) => value.isEmpty ? null : value;
}
