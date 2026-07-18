import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../../providers/theme_provider.dart';
import 'add_card_screen.dart';
import '../backup/backup_screen.dart';
import '../card_detail/card_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _backupNavigating = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenBackup());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _maybeOpenBackup() {
    if (_backupNavigating || !mounted) return;
    if (ref.read(pendingBackupProvider) == null) return;
    _backupNavigating = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BackupScreen()))
        .then((_) => _backupNavigating = false);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<CardEntry> _applySearch(List<CardEntry> cards, AppConfig config) {
    if (_searchQuery.isEmpty) return cards;
    final q = _searchQuery.toLowerCase();
    return cards.where((card) {
      if (card.label.toLowerCase().contains(q)) return true;
      final cat = config.categoryById(card.category);
      if (cat != null && cat.label.toLowerCase().contains(q)) return true;
      return card.fields.any((f) => f.key.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<int>?>(pendingBackupProvider, (_, next) {
      if (next != null) _maybeOpenBackup();
    });

    final cardsAsync = ref.watch(cardsNotifierProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;
    final themeMode = ref.watch(themeModeProvider);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopSearch();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _stopSearch,
                )
              : null,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search cards…',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              : const Text('OfflinePocket'),
          actions: [
            if (!_isSearching) ...[
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: () => setState(() => _isSearching = true),
              ),
              IconButton(
                tooltip: switch (themeMode) {
                  ThemeMode.system => 'System theme',
                  ThemeMode.light => 'Light theme',
                  ThemeMode.dark => 'Dark theme',
                },
                icon: Icon(switch (themeMode) {
                  ThemeMode.system => Icons.brightness_auto_outlined,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                }),
                onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'backup') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupScreen()),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'backup',
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined),
                        SizedBox(width: 12),
                        Text('Backup & Restore'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear',
                onPressed: () => setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                }),
              ),
          ],
        ),
        body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text('No cards yet'),
                    const SizedBox(height: 8),
                    const Text('Tap + to add your first card'),
                  ],
                ),
              );
            }

            if (_searchQuery.isNotEmpty) {
              final results = _applySearch(cards, config);
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No results for "$_searchQuery"'),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final card in results)
                    _CardTile(card: card, config: config),
                ],
              );
            }

            // Grouped view when not searching
            final grouped = <CategoryConfig, List<CardEntry>>{};
            for (final cat in config.categories) {
              final group = cards.where((c) => c.category == cat.id).toList();
              if (group.isNotEmpty) grouped[cat] = group;
            }
            final knownIds = config.categories.map((c) => c.id).toSet();
            final orphans =
                cards.where((c) => !knownIds.contains(c.category)).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final entry in grouped.entries) ...[
                  _CategoryHeader(cat: entry.key, count: entry.value.length),
                  for (final card in entry.value)
                    _CardTile(card: card, config: config),
                  const SizedBox(height: 8),
                ],
                if (orphans.isNotEmpty) ...[
                  _OrphanHeader(count: orphans.length),
                  for (final card in orphans)
                    _CardTile(card: card, config: config),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCardScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Card'),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.cat, required this.count});
  final CategoryConfig cat;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(cat.iconData, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            cat.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrphanHeader extends StatelessWidget {
  const _OrphanHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            'Other',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.config});
  final CardEntry card;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final cat = config.categoryById(card.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              cat?.iconData ?? Icons.card_membership_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(card.label),
          subtitle: Text(
            '${card.fields.length} field${card.fields.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CardDetailScreen(cardId: card.id),
            ),
          ),
        ),
      ),
    );
  }
}
