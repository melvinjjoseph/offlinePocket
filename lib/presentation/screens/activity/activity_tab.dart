import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/activity_providers.dart';
import '../../providers/card_providers.dart';
import '../../theme/app_theme.dart';
import '../home/vault_buckets.dart';

/// Local-only audit trail. Egress events (data that left the app) are
/// emphasized because they are the only actions OfflinePocket cannot undo.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  ActivityCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(activityLogProvider);
    final loggingOn = ref.watch(activityLoggingEnabledProvider);
    final cards = ref.watch(cardsNotifierProvider).valueOrNull ?? const <CardEntry>[];
    final neon = context.neon;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: neon.panelBorder.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Text('Activity',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (logAsync.valueOrNull?.isNotEmpty ?? false)
                  TextButton(
                    onPressed: _confirmClear,
                    child: Text('CLEAR',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          if (!loggingOn) _loggingOffBanner(context),
          _filterBar(context),
          Expanded(
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (events) {
                final filtered = _filter == null
                    ? events
                    : events.where((e) => e.type.category == _filter).toList();
                if (filtered.isEmpty) return _empty(context);
                return _buildGroupedList(context, filtered, cards);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear activity history?'),
        content: const Text(
            'This removes all recorded events. Your cards are not affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await ref.read(activityLogProvider.notifier).clear();
  }

  Widget _loggingOffBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.neon.panelBorder),
      ),
      child: Text(
        'Activity logging is turned off. New events are not being recorded.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _filterBar(BuildContext context) {
    final options = <(String, ActivityCategory?)>[
      ('All', null),
      (ActivityCategory.egress.label, ActivityCategory.egress),
      (ActivityCategory.security.label, ActivityCategory.security),
    ];
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final (label, cat) in options) ...[
            GestureDetector(
              onTap: () => setState(() => _filter = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _filter == cat
                      ? neon.accent.withValues(alpha: 0.15)
                      : scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _filter == cat ? neon.accent : neon.panelBorder),
                ),
                child: Text(label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _filter == cat
                            ? neon.accent
                            : scheme.onSurfaceVariant)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text('No activity yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Shares, unlocks, and backups will appear here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
      BuildContext context, List<ActivityEvent> events, List<CardEntry> cards) {
    final children = <Widget>[];
    String? lastHeader;
    for (final e in events) {
      final header = _dayHeader(e.timestamp);
      if (header != lastHeader) {
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(16, lastHeader == null ? 4 : 20, 16, 8),
          child: Text(header.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
        ));
        lastHeader = header;
      }
      children.add(_ActivityRow(event: e, cards: cards));
    }
    children.add(const SizedBox(height: 100));
    return ListView(children: children);
  }

  static String _dayHeader(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.cards});

  final ActivityEvent event;
  final List<CardEntry> cards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final isEgress = event.type.category == ActivityCategory.egress;
    final isAlert = event.type == ActivityType.authFailed;

    final accent = isAlert
        ? scheme.error
        : isEgress
            ? scheme.error
            : neon.accent;

    // Resolve the label at render time; deleted cards degrade gracefully.
    final cardLabel = event.cardId == null
        ? null
        : cards.where((c) => c.id == event.cardId).firstOrNull?.label ??
            'a deleted card';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEgress || isAlert
                ? accent.withValues(alpha: 0.4)
                : neon.panelBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(_icon(event.type), size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(event, cardLabel),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isEgress || isAlert ? accent : scheme.onSurface)),
                  const SizedBox(height: 3),
                  Text(_subtitle(event),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(relativeTime(event.timestamp),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  static IconData _icon(ActivityType t) => switch (t) {
        ActivityType.sharedAsText => Icons.text_snippet_outlined,
        ActivityType.sharedImage => Icons.image_outlined,
        ActivityType.backupExported => Icons.upload_file_outlined,
        ActivityType.backupRestored => Icons.download_outlined,
        ActivityType.vaultUnlocked => Icons.lock_open_outlined,
        ActivityType.authFailed => Icons.gpp_bad_outlined,
        ActivityType.dataPurged => Icons.delete_forever_outlined,
      };

  static String _title(ActivityEvent e, String? cardLabel) => switch (e.type) {
        ActivityType.sharedAsText =>
          'Shared as text${cardLabel == null ? '' : ' — $cardLabel'}',
        ActivityType.sharedImage =>
          'Shared card image${cardLabel == null ? '' : ' — $cardLabel'}',
        ActivityType.backupExported => 'Backup exported',
        ActivityType.backupRestored => 'Backup restored',
        ActivityType.vaultUnlocked => 'Vault unlocked',
        ActivityType.authFailed => 'Unlock attempt unsuccessful',
        ActivityType.dataPurged => 'All data purged',
      };

  static String _subtitle(ActivityEvent e) {
    final parts = <String>[];
    if (e.sensitive && e.type.category == ActivityCategory.egress) {
      parts.add('Included sensitive values');
    }
    if (e.target != null) parts.add('→ ${_prettyTarget(e.target!)}');
    if (parts.isEmpty) {
      return switch (e.type) {
        ActivityType.authFailed => 'Biometric rejected or prompt dismissed',
        ActivityType.vaultUnlocked => 'Authenticated successfully',
        ActivityType.backupRestored => 'Cards imported from a backup file',
        ActivityType.dataPurged => 'Vault erased from this device',
        _ => '',
      };
    }
    return parts.join(' · ');
  }

  /// Android returns a raw component name (`com.instagram.android/...`).
  /// Many packages end in a generic segment, so walk backwards to the first
  /// meaningful one — otherwise Instagram and Airbnb both read as "android".
  static const _genericSegments = {
    'com', 'android', 'app', 'apps', 'mobile', 'client', 'main'
  };

  static String _prettyTarget(String raw) {
    final pkg = raw.split('/').first;
    final parts = pkg.split('.').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return raw;
    var pick = parts.last;
    for (var i = parts.length - 1; i >= 0; i--) {
      if (!_genericSegments.contains(parts[i].toLowerCase())) {
        pick = parts[i];
        break;
      }
    }
    return pick[0].toUpperCase() + pick.substring(1);
  }
}
