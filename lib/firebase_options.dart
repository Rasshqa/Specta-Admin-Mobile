// File ini di-generate dari google-services.json
// Jika package name berubah, generate ulang via: flutterfire configure
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Reconfigure your Web app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios. '
          'Reconfigure your iOS app.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Values extracted from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAC_Z1Dzhg0iEFvkvZuV6tNdfKkaK5rDI',
    appId: '1:921978903189:android:5fa81130c810d92e19d99c',
    messagingSenderId: '921978903189',
    projectId: 'specta-xxi',
    storageBucket: 'specta-xxi.firebasestorage.app',
  );
}
