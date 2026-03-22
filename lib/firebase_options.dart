import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDiTtquolusO6xbupgoazTdH3gXKNnKkas',
    appId: '1:126481720028:web:2e2ead20710350526fca19',
    messagingSenderId: '126481720028',
    projectId: 'study-mate-official',
    authDomain: 'study-mate-official.firebaseapp.com',
    storageBucket: 'study-mate-official.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCcGTPSDlSZjD6MYmvF7Nflv2RhwdFhbI',
    appId: '1:126481720028:android:e4fc3d595a817f366fca19',
    messagingSenderId: '126481720028',
    projectId: 'study-mate-official',
    storageBucket: 'study-mate-official.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXMKO0i_IO3BxL9HgFpTgSj4-QYcgT9T8',
    appId: '1:126481720028:ios:24a607c2fa3407d66fca19',
    messagingSenderId: '126481720028',
    projectId: 'study-mate-official',
    storageBucket: 'study-mate-official.firebasestorage.app',
    iosBundleId: 'com.example.computingGroupProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXMKO0i_IO3BxL9HgFpTgSj4-QYcgT9T8',
    appId: '1:126481720028:ios:24a607c2fa3407d66fca19',
    messagingSenderId: '126481720028',
    projectId: 'study-mate-official',
    storageBucket: 'study-mate-official.firebasestorage.app',
    iosBundleId: 'com.example.computingGroupProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDiTtquolusO6xbupgoazTdH3gXKNnKkas',
    appId: '1:126481720028:web:d1d41ec90ce11a986fca19',
    messagingSenderId: '126481720028',
    projectId: 'study-mate-official',
    authDomain: 'study-mate-official.firebaseapp.com',
    storageBucket: 'study-mate-official.firebasestorage.app',
  );
}
