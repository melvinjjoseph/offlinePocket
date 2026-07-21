import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/activity_event.dart';
import '../../providers/activity_providers.dart';
import '../../providers/card_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../backup/backup_screen.dart';

/// The "Settings" tab — security posture + vault maintenance, restyled to the
/// cyber design. Values are read from [AppConfig]; no net-new features are
/// wired here (key rotation / purge are deferred).
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: neon.panelBorder.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: neon.accent, size: 26),
                const SizedBox(width: 10),
                Text('OfflinePocket',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700)),
                const Spacer(),
                InkWell(
                  onTap: () => ref.read(themeModeProvider.notifier).cycle(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainer,
                      border: Border.all(color: neon.panelBorder),
                    ),
                    child: Icon(
                      switch (themeMode) {
                        ThemeMode.system => Icons.brightness_auto_outlined,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      },
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              children: [
                _HardwarePanel(),
                const SizedBox(height: 24),
                _sectionLabel(context, 'SECURITY PARAMETERS'),
                const SizedBox(height: 12),
                _ParamCard(
                  title: 'Auto-Lock Timeout',
                  subtitle: 'Automatic vault closure on inactivity',
                  trailing: _formatDuration(settings.autoLockSeconds),
                  accentBar: true,
                  onTap: () => _pickValue(
                    context: context,
                    title: 'Auto-Lock Timeout',
                    current: settings.autoLockSeconds,
                    options: const [30, 60, 120, 300, 600, 1800],
                    onSelected: (v) =>
                        ref.read(settingsProvider.notifier).setAutoLock(v),
                  ),
                ),
                _ParamCard(
                  title: 'Clipboard Clear',
                  subtitle: 'Memory wipe for copied sensitive data',
                  trailing: _formatDuration(settings.clipboardClearSeconds),
                  accentBar: true,
                  onTap: () => _pickValue(
                    context: context,
                    title: 'Clipboard Clear',
                    current: settings.clipboardClearSeconds,
                    options: const [15, 30, 45, 60, 90, 120],
                    onSelected: (v) =>
                        ref.read(settingsProvider.notifier).setClipboardClear(v),
                  ),
                ),
                _ParamCard(
                  title: 'Encryption Standard',
                  subtitle: 'Industry-standard payload protection',
                  trailing: 'AES-256-GCM',
                  trailingIcon: Icons.lock_outline,
                  accentBar: true,
                ),
                const SizedBox(height: 8),
                _ParamCard(
                  title: 'Biometric Unlock',
                  subtitle: 'Fingerprint or device credential required',
                  trailingWidget: Icon(Icons.verified_user,
                      color: neon.accent, size: 22),
                ),
                _ParamCard(
                  title: 'Activity Logging',
                  subtitle: 'Record shares, unlocks, and backups on this device',
                  trailingWidget: Switch(
                    value: ref.watch(activityLoggingEnabledProvider),
                    onChanged: (v) => ref
                        .read(activityLoggingEnabledProvider.notifier)
                        .setEnabled(v),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel(context, 'VAULT MAINTENANCE'),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Backup & Restore',
                  icon: Icons.cloud_sync_outlined,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupScreen())),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Purge All Data',
                  icon: Icons.delete_forever_outlined,
                  destructive: true,
                  onTap: () => _confirmPurge(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60}m';
    return '${seconds}s';
  }

  Future<void> _confirmPurge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PurgeDialog(),
    );
    if (confirmed != true || !context.mounted) return;

    // Block interaction while the wipe runs.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 18),
            Text('Purging vault…'),
          ],
        ),
      ),
    );

    String? error;
    try {
      await ref.read(cardsNotifierProvider.notifier).purgeAll();
      // Logged after the wipe so the entry survives as a record that the
      // purge happened, without naming anything that was deleted.
      await ref.read(activityLoggerProvider).log(ActivityType.dataPurged);
    } catch (e) {
      error = '$e';
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss progress dialog
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(error == null
            ? 'All vault data has been permanently deleted.'
            : 'Purge failed: $error'),
        duration: const Duration(seconds: 4),
      ));
  }

  Future<void> _pickValue({
    required BuildContext context,
    required String title,
    required int current,
    required List<int> options,
    required void Function(int) onSelected,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final neon = Theme.of(context).extension<NeonTheme>()!;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            for (final opt in options)
              ListTile(
                title: Text(_formatDuration(opt)),
                trailing: opt == current
                    ? Icon(Icons.check, color: neon.accent)
                    : null,
                onTap: () => Navigator.pop(context, opt),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) onSelected(chosen);
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// Reports the device's real key-storage posture. The StrongBox claim is
/// queried from the platform rather than assumed — an unverified security
/// assertion is worse than none.
class _HardwarePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final strongBox = ref.watch(strongBoxAvailableProvider);

    final (title, body) = strongBox.when(
      loading: () => (
        'Checking hardware…',
        'Querying this device for a StrongBox secure element.',
      ),
      error: (_, _) => (
        'Android Keystore Active',
        'Encryption keys are managed by the Android Keystore and are never '
            'exposed to the app process. StrongBox status could not be determined.',
      ),
      data: (available) => available
          ? (
              'StrongBox Secure\nElement Active',
              'This device provides a dedicated tamper-resistant security chip. '
                  'Encryption keys are held there, isolated from the main processor.',
            )
          : (
              'Android Keystore\nActive',
              'Encryption keys are managed by the Android Keystore and are '
                  'never exposed to the app process.',
            ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neon.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HARDWARE LAYER',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: neon.accent)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: neon.glowShadow(strength: 0.6),
                ),
                child: Icon(Icons.memory, color: neon.accentBright, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(body, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Type-to-confirm dialog for the irreversible purge. Deliberately spells out
/// exactly what is destroyed — and what is *not* (existing backup files).
class _PurgeDialog extends StatefulWidget {
  const _PurgeDialog();

  @override
  State<_PurgeDialog> createState() => _PurgeDialogState();
}

class _PurgeDialogState extends State<_PurgeDialog> {
  static const _phrase = 'PURGE';
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 32),
      title: const Text('Purge all data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This permanently deletes:', style: text.bodyMedium),
            const SizedBox(height: 8),
            _bullet(context, 'Every card and document in your vault'),
            _bullet(context, 'All scanned images'),
            _bullet(context, 'The device encryption key'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
              ),
              child: Text(
                'This cannot be undone. OfflinePocket keeps no cloud copy — '
                'if you have no backup file, this data is gone forever.',
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Backup files you already exported are not deleted, and stay '
              'readable with their original password.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 18),
            Text('Type $_phrase to confirm', style: text.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: _phrase),
              onChanged: (v) =>
                  setState(() => _matches = v.trim().toUpperCase() == _phrase),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            disabledBackgroundColor: scheme.error.withValues(alpha: 0.25),
          ),
          child: const Text('Purge everything'),
        ),
      ],
    );
  }

  Widget _bullet(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}

class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingIcon,
    this.trailingWidget,
    this.accentBar = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final bool accentBar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (trailingWidget != null)
            trailingWidget!
          else ...[
            if (trailing != null)
              Text(trailing!,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: neon.accent)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 16, color: scheme.onSurfaceVariant),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
            ],
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: accentBar
            ? Border(
                left: BorderSide(color: neon.accent, width: 3),
                top: BorderSide(color: neon.panelBorder),
                right: BorderSide(color: neon.panelBorder),
                bottom: BorderSide(color: neon.panelBorder),
              )
            : Border.all(color: neon.panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final accent = destructive ? scheme.error : neon.accent;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: destructive
                    ? scheme.error.withValues(alpha: 0.5)
                    : neon.panelBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: destructive ? scheme.error : null)),
              ),
              Icon(icon, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
