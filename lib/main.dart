import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/clipboard_service.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';

const _backupChannel = MethodChannel('com.melvinjjoseph.offlinepocket/backup');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    PackageInfo.fromPlatform(),
    _backupChannel.invokeMethod<Uint8List>('consumePendingBackup').catchError((_) => null),
  ]);

  final prefs = results[0] as SharedPreferences;
  final packageInfo = results[1] as PackageInfo;
  final pendingBackup = results[2] as Uint8List?;

  final lastSeenVersion = prefs.getString('onboarding_last_version') ?? '';
  final onboardingSeen = lastSeenVersion == packageInfo.version;

  runApp(ProviderScope(
    overrides: [
      onboardingSeenProvider.overrideWith((_) => onboardingSeen),
      if (pendingBackup != null)
        pendingBackupProvider.overrideWith((_) => List<int>.from(pendingBackup)),
    ],
    child: const OfflinePocketApp(),
  ));
}

class OfflinePocketApp extends ConsumerStatefulWidget {
  const OfflinePocketApp({super.key});

  @override
  ConsumerState<OfflinePocketApp> createState() => _OfflinePocketAppState();
}

class _OfflinePocketAppState extends ConsumerState<OfflinePocketApp>
    with WidgetsBindingObserver {
  Timer? _lockTimer;

  Future<void> _checkPendingBackup() async {
    try {
      final bytes = await _backupChannel.invokeMethod<Uint8List>('consumePendingBackup');
      if (bytes != null && mounted) {
        ref.read(pendingBackupProvider.notifier).state = List<int>.from(bytes);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final lockTimeout =
          Duration(seconds: ref.read(settingsProvider).autoLockSeconds);
      _lockTimer?.cancel();
      _lockTimer = Timer(lockTimeout, () {
        ref.read(authStateProvider.notifier).state = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      _lockTimer = null;
      ClipboardService.onResumed();
      _checkPendingBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (_, next) {
      ClipboardService.configure(next.clipboardClearSeconds);
    });
    // Apply the initial value immediately (listen only fires on change).
    ClipboardService.configure(ref.read(settingsProvider).clipboardClearSeconds);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'OfflinePocket',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
