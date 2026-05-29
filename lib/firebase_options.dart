

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
    apiKey: 'AIzaSyCturSL3AZ8v9x3zjr6AYjihB_OncbOB5A',
    appId: '1:445557503241:web:c32a677d49cf97f4bb0fd8',
    messagingSenderId: '445557503241',
    projectId: 'miloginapp-b291e',
    authDomain: 'miloginapp-b291e.firebaseapp.com',
    storageBucket: 'miloginapp-b291e.firebasestorage.app',
    measurementId: 'G-JBV4PNFQ32',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4P0ndLGAjBDlL6ntHewKcv45OV5m_lZo',
    appId: '1:445557503241:android:b256d1187c50e1b4bb0fd8',
    messagingSenderId: '445557503241',
    projectId: 'miloginapp-b291e',
    storageBucket: 'miloginapp-b291e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAc-vpZHoL88Cb7W5EL7d1vLQyXuKzgziU',
    appId: '1:445557503241:ios:26708467688299edbb0fd8',
    messagingSenderId: '445557503241',
    projectId: 'miloginapp-b291e',
    storageBucket: 'miloginapp-b291e.firebasestorage.app',
    iosClientId: '445557503241-spa7eji1tpk9aeaj2in767hr4bg6pfls.apps.googleusercontent.com',
    iosBundleId: 'com.example.miLogin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAc-vpZHoL88Cb7W5EL7d1vLQyXuKzgziU',
    appId: '1:445557503241:ios:26708467688299edbb0fd8',
    messagingSenderId: '445557503241',
    projectId: 'miloginapp-b291e',
    storageBucket: 'miloginapp-b291e.firebasestorage.app',
    iosClientId: '445557503241-spa7eji1tpk9aeaj2in767hr4bg6pfls.apps.googleusercontent.com',
    iosBundleId: 'com.example.miLogin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCturSL3AZ8v9x3zjr6AYjihB_OncbOB5A',
    appId: '1:445557503241:web:d6f3f802a22b7be6bb0fd8',
    messagingSenderId: '445557503241',
    projectId: 'miloginapp-b291e',
    authDomain: 'miloginapp-b291e.firebaseapp.com',
    storageBucket: 'miloginapp-b291e.firebasestorage.app',
    measurementId: 'G-VST0P8JTYJ',
  );
}
