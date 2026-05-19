import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String _keySemanticSearch = 'enable_semantic_search';

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? const Duration(seconds: 0)
          : const Duration(minutes: 60),
    ));

    await _remoteConfig.setDefaults({
      _keySemanticSearch: true,
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] fetch failed, using defaults: $e');
    }
  }

  /// Feature flag: Gemini semantic search on home screen.
  /// Rollback: set to false in Firebase Console → takes effect within 60s.
  bool get isSemanticSearchEnabled => _remoteConfig.getBool(_keySemanticSearch);
}
