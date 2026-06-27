import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/masked_field.dart';
import '../../widgets/fullscreen_gallery.dart';
import '../home/add_card_screen.dart';

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsNotifierProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (cards) {
        final card = cards.where((c) => c.id == cardId).firstOrNull;
        if (card == null) {
          return const Scaffold(body: Center(child: Text('Card not found')));
        }
        final cat = config.categoryById(card.category);

        return Scaffold(
          appBar: AppBar(
            title: Text(card.label),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AddCardScreen(initialCard: card),
                )),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _showShareSheet(context, ref, card, cat),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete card?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(cardsNotifierProvider.notifier).delete(card.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Icon(cat?.iconData ?? Icons.card_membership_outlined, size: 32),
                  const SizedBox(width: 12),
                  Text(cat?.label ?? card.category,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              // ── Scanned images ──────────────────────────────────────
              if (card.frontImagePath != null || card.backImagePath != null) ...[
                const SizedBox(height: 16),
                Text('Scanned Images',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final pages = <(String, String)>[
                    if (card.frontImagePath != null) ('Front', card.frontImagePath!),
                    if (card.backImagePath != null) ('Back', card.backImagePath!),
                  ];
                  return Row(
                    children: [
                      for (var i = 0; i < pages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _CardThumb(
                          label: pages[i].$1,
                          path: pages[i].$2,
                          onTap: () => openFullscreenGallery(context, pages, i),
                        ),
                      ],
                    ],
                  );
                }),
              ],
              const Divider(height: 32),
              ...card.fields.map((f) => MaskedField(
                    label: f.key,
                    value: f.value,
                    isSensitive: f.isSensitive,
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref, CardEntry card, CategoryConfig? cat) {
    final hasImages = card.frontImagePath != null || card.backImagePath != null;

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Share "${card.label}"',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            if (hasImages)
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Share card image'),
                subtitle: Text(
                  [
                    if (card.frontImagePath != null) 'Front',
                    if (card.backImagePath != null) 'Back',
                  ].join(' & '),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsImage(context, ref, card);
                },
              ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Share as text'),
              subtitle: const Text('Plain text with all field values'),
              onTap: () {
                Navigator.pop(context);
                _shareAsText(card, cat);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsImage(BuildContext context, WidgetRef ref, CardEntry card) async {
    final imageService = ref.read(imageServiceProvider);
    final tmpDir = await getTemporaryDirectory();
    final tmpFiles = <File>[];

    Future<XFile> decryptToTemp(String encPath, String name) async {
      final bytes = await imageService.decryptToBytes(encPath);
      final tmp = File(p.join(tmpDir.path, name));
      await tmp.writeAsBytes(bytes);
      tmpFiles.add(tmp);
      return XFile(tmp.path, mimeType: 'image/jpeg');
    }

    try {
      final xfiles = [
        if (card.frontImagePath != null)
          await decryptToTemp(card.frontImagePath!, 'share_front.jpg'),
        if (card.backImagePath != null)
          await decryptToTemp(card.backImagePath!, 'share_back.jpg'),
      ];
      await SharePlus.instance.share(ShareParams(files: xfiles));
    } finally {
      // Clean up temp files after share sheet is dismissed
      for (final f in tmpFiles) {
        if (await f.exists()) await f.delete();
      }
    }
  }

  Future<void> _shareAsText(CardEntry card, CategoryConfig? cat) async {
    final buf = StringBuffer();
    buf.writeln('${cat?.label ?? card.category} — ${card.label}');
    buf.writeln('─' * 32);
    for (final f in card.fields) {
      buf.writeln('${f.key}: ${f.value}');
    }
    buf.writeln();
    buf.write('Shared from OfflinePocket');
    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }
}

// ── Thumbnail widget ─────────────────────────────────────────────────────────

class _CardThumb extends StatelessWidget {
  const _CardThumb({required this.label, required this.path, required this.onTap});
  final String label;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: EncryptedImage(
                path: path,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
