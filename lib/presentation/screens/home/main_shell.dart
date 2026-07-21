import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../activity/activity_tab.dart';
import '../backup/backup_screen.dart';
import '../settings/settings_tab.dart';
import 'add_card_screen.dart';
import 'vault_dashboard.dart';

/// Root authenticated shell: bottom navigation (Vault / Activity / Settings)
/// with a glowing add-card FAB on the Vault tab. Also owns the pending-backup
/// auto-open flow (moved here from the former HomeScreen).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _backupNavigating = false;

  static const _tabs = [VaultDashboard(), ActivityTab(), SettingsTab()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenBackup());
  }

  void _maybeOpenBackup() {
    if (_backupNavigating || !mounted) return;
    if (ref.read(pendingBackupProvider) == null) return;
    _backupNavigating = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BackupScreen()))
        .then((_) => _backupNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<int>?>(pendingBackupProvider, (_, next) {
      if (next != null) _maybeOpenBackup();
    });

    final neon = context.neon;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _index == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: neon.glowShadow(),
              ),
              child: FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddCardScreen()),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.lock_outline),
              selectedIcon: Icon(Icons.lock),
              label: 'Vault'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
