import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/config/remote_config_service.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/home/home_screen.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final service = RemoteConfigService(FirebaseRemoteConfig.instance);
  return service.fetch();
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(path: '/auth', builder: (_, _) => const AuthGate()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    ],
  );
});
