import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../../widgets/vault_widgets.dart';
import '../card_detail/card_detail_screen.dart';
import 'vault_buckets.dart';

/// Shows the cards within a single [VaultBucket]. When [bucket] is null it
/// shows all cards ("View All"), or only orphan-category cards when
/// [orphansOnly] is set.
class BucketListScreen extends ConsumerWidget {
  const BucketListScreen({super.key, required this.bucket, this.orphansOnly = false});

  final VaultBucket? bucket;
  final bool orphansOnly;

  String get _title {
    if (bucket != null) return bucket!.label;
    return orphansOnly ? 'Other' : 'All Cards';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsNotifierProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          List<CardEntry> list;
          if (bucket != null) {
            list = cards.where(bucket!.contains).toList();
          } else if (orphansOnly) {
            list = cards
                .where((c) => VaultBucket.forCategory(c.category) == null)
                .toList();
          } else {
            list = [...cards]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          if (list.isEmpty) {
            final scheme = Theme.of(context).colorScheme;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text('Nothing here yet',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final card in list)
                VaultCardTile(
                  card: card,
                  config: config,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CardDetailScreen(cardId: card.id))),
                ),
            ],
          );
        },
      ),
    );
  }
}
