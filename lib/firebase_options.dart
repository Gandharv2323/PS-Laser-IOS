// File generated for project pslaser-6f7bf
// Supports: Android + Web

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCygMzNRbxqd_zFrwa_w5eP1wTvyUnNZeA',
    authDomain: 'pslaser-6f7bf.firebaseapp.com',
    projectId: 'pslaser-6f7bf',
    storageBucket: 'pslaser-6f7bf.firebasestorage.app',
    messagingSenderId: '498608354354',
    appId: '1:498608354354:web:forgeops0000000000',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCygMzNRbxqd_zFrwa_w5eP1wTvyUnNZeA',
    appId: '1:498608354354:android:6c4e997c8f4e47953ff82b',
    messagingSenderId: '498608354354',
    projectId: 'pslaser-6f7bf',
    storageBucket: 'pslaser-6f7bf.firebasestorage.app',
  );
}
