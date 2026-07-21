import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vault_widgets.dart';
import '../card_detail/card_detail_screen.dart';
import 'bucket_list_screen.dart';
import 'vault_buckets.dart';

/// The "Vault" tab — the redesigned dashboard (status panel, recently added
/// carousel, category buckets). Owns its own header + inline search.
class VaultDashboard extends ConsumerStatefulWidget {
  const VaultDashboard({super.key});

  @override
  ConsumerState<VaultDashboard> createState() => _VaultDashboardState();
}

class _VaultDashboardState extends ConsumerState<VaultDashboard> {
  bool _isSearching = false;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
      _searchController.clear();
    });
  }

  List<CardEntry> _search(List<CardEntry> cards, AppConfig config) {
    final q = _query.toLowerCase();
    return cards.where((card) {
      if (card.label.toLowerCase().contains(q)) return true;
      final cat = config.categoryById(card.category);
      if (cat != null && cat.label.toLowerCase().contains(q)) return true;
      return card.fields.any((f) => f.key.toLowerCase().contains(q));
    }).toList();
  }

  void _openDetail(CardEntry card) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: card.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsNotifierProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopSearch();
      },
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: cardsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (cards) => _isSearching
                    ? _searchResults(cards, config)
                    : _dashboard(cards, config),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Header ----------------------------------------------------------

  Widget _header(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    if (_isSearching) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: neon.panelBorder.withValues(alpha: 0.4))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _stopSearch,
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search cards…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _query = '';
                  _searchController.clear();
                }),
              ),
          ],
        ),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: neon.panelBorder.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Image.asset('assets/icon/logo.png',
              width: 32, height: 32,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.shield_outlined, color: neon.accent, size: 28)),
          const SizedBox(width: 10),
          Text('OfflinePocket',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: neon.accent,
                    fontWeight: FontWeight.w700,
                  )),
          const Spacer(),
          _circleButton(
            icon: Icons.search,
            onTap: () => setState(() => _isSearching = true),
          ),
          const SizedBox(width: 8),
          _circleButton(
            icon: switch (themeMode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            },
            onTap: () => ref.read(themeModeProvider.notifier).cycle(),
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    final neon = context.neon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(color: neon.panelBorder),
        ),
        child: Icon(icon, size: 20, color: color ?? neon.accent),
      ),
    );
  }

  // ---- Search results --------------------------------------------------

  Widget _searchResults(List<CardEntry> cards, AppConfig config) {
    if (_query.isEmpty) {
      return _emptyState(Icons.search, 'Search your vault',
          'Find cards by name, category, or field');
    }
    final results = _search(cards, config);
    if (results.isEmpty) {
      return _emptyState(Icons.search_off, 'No results', 'Nothing matches "$_query"');
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final card in results)
          VaultCardTile(card: card, config: config, onTap: () => _openDetail(card)),
      ],
    );
  }

  // ---- Dashboard -------------------------------------------------------

  Widget _dashboard(List<CardEntry> cards, AppConfig config) {
    if (cards.isEmpty) {
      return _emptyState(Icons.add_card_outlined, 'Your vault is empty',
          'Tap + to add your first card');
    }
    final recent = [...cards]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentTop = recent.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const _SecureVaultPanel(),
        const SizedBox(height: 24),
        // Recently Added
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recently Added', style: Theme.of(context).textTheme.headlineMedium),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BucketListScreen(bucket: null))),
              child: Text('VIEW ALL',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recentTop.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, i) => RecentCardVisual(
              card: recentTop[i],
              config: config,
              onTap: () => _openDetail(recentTop[i]),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Vault Categories', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        for (final bucket in VaultBucket.values)
          _BucketRow(
            bucket: bucket,
            cards: cards.where(bucket.contains).toList(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BucketListScreen(bucket: bucket))),
          ),
        // Orphans (unknown categories) surfaced so nothing is hidden.
        if (cards.any((c) => VaultBucket.forCategory(c.category) == null))
          _BucketRow(
            bucket: null,
            cards: cards
                .where((c) => VaultBucket.forCategory(c.category) == null)
                .toList(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BucketListScreen(bucket: null, orphansOnly: true))),
          ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The pulsing "Secure Vault — locked with biometrics" hero panel.
class _SecureVaultPanel extends StatefulWidget {
  const _SecureVaultPanel();

  @override
  State<_SecureVaultPanel> createState() => _SecureVaultPanelState();
}

class _SecureVaultPanelState extends State<_SecureVaultPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neon.panelBorder),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = 0.7 + 0.3 * _c.value;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: neon.panelBorder),
                  boxShadow: neon.glowShadow(strength: t),
                ),
                child: Transform.scale(scale: 0.96 + 0.04 * _c.value, child: child),
              );
            },
            child: Icon(Icons.fingerprint, size: 44, color: neon.accentBright),
          ),
          const SizedBox(height: 16),
          Text('Secure Vault', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neon.accentBright,
                  boxShadow: neon.glowShadow(),
                ),
              ),
              const SizedBox(width: 8),
              Text('LOCKED WITH BIOMETRICS',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: neon.accentBright)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({required this.bucket, required this.cards, required this.onTap});

  /// Null bucket = "Other" (orphan categories).
  final VaultBucket? bucket;
  final List<CardEntry> cards;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final label = bucket?.label ?? 'Other';
    final icon = bucket?.icon ?? Icons.help_outline;
    final lastUpdated = cards.isEmpty
        ? '—'
        : relativeTime(cards
            .map((c) => c.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neon.panelBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerLowest,
                    border: Border.all(color: neon.panelBorder),
                  ),
                  child: Icon(icon, size: 22, color: neon.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Last updated $lastUpdated',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${cards.length}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSecondaryContainer)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
