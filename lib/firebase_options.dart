import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Salon Buff
/// Project: salonbuff-435b2
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not configured for this Firebase project.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDX-7xEElF3AfOztsiRxmgHcci14FHpPco',
    authDomain: 'salonbuff-435b2.firebaseapp.com',
    projectId: 'salonbuff-435b2',
    storageBucket: 'salonbuff-435b2.firebasestorage.app',
    messagingSenderId: '572591532042',
    appId: '1:572591532042:web:057ffe40067e0dd133d7f3',
  );

  // Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaWUqmH4xdrbGWFZVMSuy55RRHL_jT-zA',
    appId: '1:572591532042:android:0a9e765aa2e39a0633d7f3',
    messagingSenderId: '572591532042',
    projectId: 'salonbuff-435b2',
    storageBucket: 'salonbuff-435b2.firebasestorage.app',
  );

  // iOS configuration - You need to add iOS app in Firebase Console
  // After adding iOS app, replace these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDX-7xEElF3AfOztsiRxmgHcci14FHpPco',
    appId: '1:572591532042:ios:YOUR_IOS_APP_ID',  // Replace after adding iOS app
    messagingSenderId: '572591532042',
    projectId: 'salonbuff-435b2',
    storageBucket: 'salonbuff-435b2.firebasestorage.app',
    iosBundleId: 'com.salonbuff.app',
  );
}
