import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseRuntimeOptions {
  const FirebaseRuntimeOptions._();

  static const _nativeApiKeyKey = 'income_sync_firebase_api_key';
  static const _nativeAppIdKey = 'income_sync_firebase_app_id_android';
  static const _nativeProjectIdKey = 'income_sync_firebase_project_id';
  static const _nativeSenderIdKey = 'income_sync_firebase_messaging_sender_id';
  static const _nativeStorageBucketKey = 'income_sync_firebase_storage_bucket';
  static const _nativeBaseUrlKey = 'income_sync_api_base_url';

  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) return true;

    try {
      await Firebase.initializeApp();
      logger.i(
        'Firebase initialized using native platform config.',
      );
      return true;
    } on FirebaseException catch (error, stackTrace) {
      logger
        ..i(
          'Firebase native config unavailable, falling back to env options.',
        )
        ..d(
          'Firebase native init failed: ${error.code} ${error.message}',
          error: error,
          stackTrace: stackTrace,
        );
    }

    final options = _resolveOptions();
    if (options == null) {
      logger.i('Firebase config missing. Income sync stays local-only.');
      return false;
    }

    await Firebase.initializeApp(options: options);
    logger.i('Firebase initialized for income sync.');
    return true;
  }

  static FirebaseOptions? _resolveOptions() {
    if (kIsWeb) return null;

    final apiKey = _readEnv('FIREBASE_API_KEY');
    final projectId = _readEnv('FIREBASE_PROJECT_ID');
    final messagingSenderId = _readEnv('FIREBASE_MESSAGING_SENDER_ID');
    final storageBucket = _readEnv('FIREBASE_STORAGE_BUCKET');

    String? appId;
    String? iosBundleId;

    if (defaultTargetPlatform == TargetPlatform.android) {
      appId =
          _readEnv('FIREBASE_APP_ID_ANDROID') ?? _readEnv('FIREBASE_APP_ID');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      appId = _readEnv('FIREBASE_APP_ID_IOS') ?? _readEnv('FIREBASE_APP_ID');
      iosBundleId = _readEnv('FIREBASE_IOS_BUNDLE_ID');
    } else {
      return null;
    }

    if (apiKey == null ||
        projectId == null ||
        messagingSenderId == null ||
        appId == null) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: iosBundleId,
    );
  }

  static String? _readEnv(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static Future<void> persistNativeSyncConfig() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final sharedPreferences = await SharedPreferences.getInstance();
    final entries = <String, String?>{
      _nativeApiKeyKey: _readEnv('FIREBASE_API_KEY'),
      _nativeAppIdKey:
          _readEnv('FIREBASE_APP_ID_ANDROID') ?? _readEnv('FIREBASE_APP_ID'),
      _nativeProjectIdKey: _readEnv('FIREBASE_PROJECT_ID'),
      _nativeSenderIdKey: _readEnv('FIREBASE_MESSAGING_SENDER_ID'),
      _nativeStorageBucketKey: _readEnv('FIREBASE_STORAGE_BUCKET'),
      _nativeBaseUrlKey: _readEnv('BASE_URL'),
    };

    for (final entry in entries.entries) {
      final value = entry.value;
      if (value == null || value.isEmpty) {
        await sharedPreferences.remove(entry.key);
      } else {
        await sharedPreferences.setString(entry.key, value);
      }
    }
  }
}
