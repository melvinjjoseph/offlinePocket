import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import 'app_providers.dart';

const _securityChannel =
    MethodChannel('com.melvinjjoseph.offlinepocket/security');

/// Whether this device reports a StrongBox secure element
/// (`FEATURE_STRONGBOX_KEYSTORE`). Queried from the platform — never assumed.
final strongBoxAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    return await _securityChannel.invokeMethod<bool>('strongBoxAvailable') ??
        false;
  } catch (_) {
    return false;
  }
});

/// User-configurable security settings. Defaults come from `config.json`
/// (via [AppConfig]); user overrides are persisted in SharedPreferences —
/// the same store used for theme/onboarding. These values are non-sensitive
/// so they don't belong in the encrypted card database.
class AppSettings {
  final int autoLockSeconds;
  final int clipboardClearSeconds;

  const AppSettings({
    required this.autoLockSeconds,
    required this.clipboardClearSeconds,
  });

  AppSettings copyWith({int? autoLockSeconds, int? clipboardClearSeconds}) =>
      AppSettings(
        autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
        clipboardClearSeconds:
            clipboardClearSeconds ?? this.clipboardClearSeconds,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kAutoLock = 'setting_auto_lock_seconds';
  static const _kClipboard = 'setting_clipboard_clear_seconds';

  @override
  AppSettings build() {
    final config =
        ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;
    // Seed synchronously from config defaults, then apply any saved overrides.
    _loadOverrides(config);
    return AppSettings(
      autoLockSeconds: config.securityIdleTimeoutSeconds,
      clipboardClearSeconds: config.clipboardClearTimeoutSeconds,
    );
  }

  Future<void> _loadOverrides(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      autoLockSeconds:
          prefs.getInt(_kAutoLock) ?? config.securityIdleTimeoutSeconds,
      clipboardClearSeconds:
          prefs.getInt(_kClipboard) ?? config.clipboardClearTimeoutSeconds,
    );
  }

  Future<void> setAutoLock(int seconds) async {
    state = state.copyWith(autoLockSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutoLock, seconds);
  }

  Future<void> setClipboardClear(int seconds) async {
    state = state.copyWith(clipboardClearSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kClipboard, seconds);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
