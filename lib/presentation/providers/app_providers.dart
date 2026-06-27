import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/home/home_screen.dart';
import 'auth_provider.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    final raw = await rootBundle.loadString('assets/config.json');
    return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return AppConfig.fallback;
  }
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authed = ref.read(authStateProvider);
      final onAuth = state.matchedLocation == '/auth';
      if (!authed && !onAuth) return '/auth';
      if (authed && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, _) => const AuthGate()),
      GoRoute(path: '/home', builder: (context, _) => const HomeScreen()),
    ],
  );
});
