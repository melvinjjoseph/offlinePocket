import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/services/clipboard_service.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: OfflinePocketApp()));
}

const _seed = Color(0xFF1565C0);

class OfflinePocketApp extends ConsumerStatefulWidget {
  const OfflinePocketApp({super.key});

  @override
  ConsumerState<OfflinePocketApp> createState() => _OfflinePocketAppState();
}

class _OfflinePocketAppState extends ConsumerState<OfflinePocketApp>
    with WidgetsBindingObserver {
  Timer? _lockTimer;

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
      final config = ref.read(appConfigProvider).valueOrNull ?? AppConfig.fallback;
      final lockTimeout = Duration(seconds: config.securityIdleTimeoutSeconds);
      _lockTimer?.cancel();
      _lockTimer = Timer(lockTimeout, () {
        ref.read(authStateProvider.notifier).state = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      _lockTimer = null;
      ClipboardService.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appConfigProvider, (_, next) {
      if (next.hasValue) {
        ClipboardService.configure(next.value!.clipboardClearTimeoutSeconds);
      }
    });
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'OfflinePocket',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
