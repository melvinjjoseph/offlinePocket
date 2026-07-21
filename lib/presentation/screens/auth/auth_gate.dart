import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../domain/entities/activity_event.dart';
import '../../providers/activity_providers.dart';
import '../../providers/auth_provider.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _authenticating = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger auth after first frame — handles both initial launch and
    // re-display after auto-lock (where resumed already fired before this
    // widget was built).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_done && !_authenticating) _authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_authenticating && !_done) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating || _done) return;
    setState(() => _authenticating = true);
    var timedOut = false;
    try {
      final success = await _auth
          .authenticate(
            localizedReason: 'Authenticate to access OfflinePocket',
            options: const AuthenticationOptions(biometricOnly: false),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              timedOut = true;
              return false;
            },
          );
      final logger = ref.read(activityLoggerProvider);
      if (success && mounted) {
        _done = true;
        await logger.log(ActivityType.vaultUnlocked);
        ref.read(authStateProvider.notifier).state = true;
        // Router redirect (authStateProvider → true → onAuth → /home) handles navigation.
      } else if (!success && !timedOut) {
        // Covers both a rejected biometric and a user-dismissed prompt —
        // local_auth's bool API can't distinguish them.
        await logger.log(ActivityType.authFailed);
      }
    } catch (_) {
      // Swallow — user taps Unlock to retry
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 24),
            const Text('OfflinePocket',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Authenticate to continue'),
            const SizedBox(height: 32),
            if (_authenticating)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
          ],
        ),
      ),
    );
  }
}
