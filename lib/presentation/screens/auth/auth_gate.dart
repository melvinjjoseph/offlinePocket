import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _authenticating = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger on first launch via lifecycle — didChangeAppLifecycleState fires
    // with resumed shortly after the activity window is ready, sidestepping the
    // "Called after onSaveInstanceState" hang on MIUI.
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
    try {
      final success = await _auth
          .authenticate(
            localizedReason: 'Authenticate to access OfflinePocket',
            options: const AuthenticationOptions(biometricOnly: false),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => false,
          );
      if (success && mounted) {
        _done = true;
        context.go('/home');
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
