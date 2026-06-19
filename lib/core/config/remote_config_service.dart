import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  Future<AppConfig> fetch() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.fetchAndActivate();
      final json = jsonDecode(_remoteConfig.getString('app_config')) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (_) {
      return _loadBundledFallback();
    }
  }

  Future<AppConfig> _loadBundledFallback() async {
    try {
      final raw = await rootBundle.loadString('assets/config.json');
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppConfig.fallback;
    }
  }
}
