import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/card_entry.dart';
import '../../../domain/entities/document_field.dart';
import '../../providers/activity_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/fullscreen_gallery.dart';
import '../home/add_card_screen.dart';

/// Masks a value showing at most the last 4 chars, unless [revealed].
String maskValue(String value, bool revealed) {
  if (revealed) return value;
  final digits = value.replaceAll(RegExp(r'[\s\-]'), '');
  if (digits.length >= 12) {
    return '•••• •••• •••• ${digits.substring(digits.length - 4)}';
  }
  if (value.length <= 4) return '•' * value.length;
  return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
}

class CardDetailScreen extends ConsumerStatefulWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  bool _revealAll = false;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsNotifierProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (cards) {
        final card = cards.where((c) => c.id == widget.cardId).firstOrNull;
        if (card == null) {
          return const Scaffold(body: Center(child: Text('Card not found')));
        }
        final cat = config.categoryById(card.category);
        final hasSensitive = card.fields.any((f) => f.isSensitive);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Card Details'),
            actions: [
              if (hasSensitive)
                IconButton(
                  tooltip: _revealAll ? 'Hide values' : 'Reveal values',
                  icon: Icon(_revealAll ? Icons.visibility_off : Icons.visibility,
                      color: neon.accent),
                  onPressed: () => setState(() => _revealAll = !_revealAll),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddCardScreen(initialCard: card)));
                  } else if (v == 'share') {
                    _showShareSheet(context, ref, card, cat);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(children: [
                      Icon(Icons.share_outlined),
                      SizedBox(width: 12),
                      Text('Share'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeroCard(card: card, cat: cat, revealAll: _revealAll),
              const SizedBox(height: 24),
              if (card.frontImagePath != null || card.backImagePath != null) ...[
                _ScannedImages(card: card),
                const SizedBox(height: 8),
              ],
              ..._buildFieldPanels(card),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, card),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Card'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _SecureClipboardBar(
            seconds: ref.watch(settingsProvider).clipboardClearSeconds,
          ),
        );
      },
    );
  }

  /// Lays fields into panels, pairing consecutive "compact" fields (short
  /// values like expiry / CVV) into two-column rows to match the design.
  List<Widget> _buildFieldPanels(CardEntry card) {
    bool isCompact(DocumentField f) => f.value.replaceAll(' ', '').length <= 10;

    final widgets = <Widget>[];
    final fields = card.fields;
    var i = 0;
    while (i < fields.length) {
      final f = fields[i];
      if (isCompact(f) && i + 1 < fields.length && isCompact(fields[i + 1])) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // IntrinsicHeight bounds the row's height so CrossAxisAlignment.stretch
          // is valid inside the ListView (unbounded height) and both columns
          // render at equal height.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _FieldPanel(field: f, revealAll: _revealAll)),
                const SizedBox(width: 12),
                Expanded(child: _FieldPanel(field: fields[i + 1], revealAll: _revealAll)),
              ],
            ),
          ),
        ));
        i += 2;
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FieldPanel(field: f, revealAll: _revealAll),
        ));
        i += 1;
      }
    }
    return widgets;
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, CardEntry card) async {
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
  }

  // ── Share (unchanged behaviour) ──────────────────────────────────────

  void _showShareSheet(BuildContext context, WidgetRef ref, CardEntry card, CategoryConfig? cat) {
    final hasImages = card.frontImagePath != null || card.backImagePath != null;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('SHARE',
                  style: Theme.of(sheetContext).textTheme.labelSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(card.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
            ),
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
                  Navigator.pop(sheetContext);
                  _shareAsImage(context, ref, card);
                },
              ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Share as text'),
              subtitle: const Text('Plain text with all field values'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmShareAsText(context, card, cat);
              },
            ),
            const SizedBox(height: 12),
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
      final result = await SharePlus.instance.share(ShareParams(files: xfiles));
      // Only record a completed share — a dismissed sheet leaked nothing.
      if (result.status == ShareResultStatus.success) {
        await ref.read(activityLoggerProvider).log(
              ActivityType.sharedImage,
              cardId: card.id,
              sensitive: true, // scanned images show the card face
              target: result.raw.isEmpty ? null : result.raw,
            );
      }
    } finally {
      for (final f in tmpFiles) {
        if (await f.exists()) await f.delete();
      }
    }
  }

  Future<void> _confirmShareAsText(BuildContext context, CardEntry card, CategoryConfig? cat) async {
    final hasSensitive = card.fields.any((f) => f.isSensitive);
    if (!hasSensitive) {
      _shareAsText(card, cat);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share sensitive data?'),
        content: const Text(
          'This card contains sensitive fields (card numbers, CVV, ID numbers, etc.).\n\n'
          'Sharing as text sends all values in plain text to whichever app you choose. '
          'Once shared, OfflinePocket has no control over that data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share anyway'),
          ),
        ],
      ),
    );
    if (confirm == true) _shareAsText(card, cat);
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
    final result =
        await SharePlus.instance.share(ShareParams(text: buf.toString()));
    // Only record a completed share — a dismissed sheet leaked nothing.
    if (result.status == ShareResultStatus.success) {
      await ref.read(activityLoggerProvider).log(
            ActivityType.sharedAsText,
            cardId: card.id,
            sensitive: card.fields.any((f) => f.isSensitive),
            target: result.raw.isEmpty ? null : result.raw,
          );
    }
  }
}

/// The gradient hero card at the top of the detail screen. Adapts to any
/// category: shows the primary (number-like) field large, plus up to two
/// secondary fields, with the card label as the "holder" line.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.card, required this.cat, required this.revealAll});

  final CardEntry card;
  final CategoryConfig? cat;
  final bool revealAll;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final text = Theme.of(context).textTheme;

    // Pick the "primary" number-like field.
    DocumentField? primary;
    for (final f in card.fields) {
      final digits = f.value.replaceAll(RegExp(r'\D'), '');
      if (f.isSensitive && digits.length >= 4) {
        primary = f;
        break;
      }
    }
    primary ??= card.fields.isNotEmpty ? card.fields.first : null;

    final secondaries =
        card.fields.where((f) => f != primary).take(2).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: neon.cardGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neon.panelBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text((cat?.label ?? card.category).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: neon.accent)),
              ),
              Icon(Icons.contactless_outlined,
                  color: Colors.white.withValues(alpha: 0.5), size: 22),
            ],
          ),
          const SizedBox(height: 16),
          // EMV chip motif
          Container(
            width: 42,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE6D28A), Color(0xFFB8974B)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          if (primary != null)
            Text(
              primary.isSensitive
                  ? maskValue(primary.value, revealAll)
                  : primary.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.headlineMedium?.copyWith(
                fontFamily: 'JetBrainsMono',
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final f in secondaries) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.key.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 2),
                      Text(
                          f.isSensitive
                              ? maskValue(f.value, revealAll)
                              : f.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A single labelled field panel with reveal (sensitive) + copy.
class _FieldPanel extends StatefulWidget {
  const _FieldPanel({required this.field, required this.revealAll});

  final DocumentField field;
  final bool revealAll;

  @override
  State<_FieldPanel> createState() => _FieldPanelState();
}

class _FieldPanelState extends State<_FieldPanel> {
  bool _localReveal = false;

  bool get _revealed => widget.revealAll || _localReveal;

  void _copy() {
    final f = widget.field;
    if (f.isSensitive) {
      ClipboardService.copySensitive(f.value.replaceAll(RegExp(r'[\s\-]'), ''));
    } else {
      Clipboard.setData(ClipboardData(text: f.value));
    }
    ScaffoldMessenger.of(context)
      // Replace rather than queue — repeated copies shouldn't stack toasts.
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(f.isSensitive
            ? '${f.key} copied — auto-clears after ${ClipboardService.clearDelaySeconds}s'
            : '${f.key} copied'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final text = Theme.of(context).textTheme;
    final f = widget.field;
    final display = f.isSensitive ? maskValue(f.value, _revealed) : f.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neon.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.key.toUpperCase(), style: text.labelSmall),
                const SizedBox(height: 4),
                Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (f.isSensitive ? text.labelLarge : text.bodyLarge)
                      ?.copyWith(
                    color: f.isSensitive ? neon.accent : scheme.onSurface,
                    letterSpacing: f.isSensitive && !_revealed ? 2 : null,
                  ),
                ),
              ],
            ),
          ),
          if (f.isSensitive)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(_localReveal ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: scheme.onSurfaceVariant),
              onPressed: () => setState(() => _localReveal = !_localReveal),
              tooltip: _localReveal ? 'Hide' : 'Reveal',
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy_outlined, size: 18, color: neon.accent),
            onPressed: _copy,
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}

class _ScannedImages extends StatelessWidget {
  const _ScannedImages({required this.card});
  final CardEntry card;

  @override
  Widget build(BuildContext context) {
    final pages = <(String, String)>[
      if (card.frontImagePath != null) ('Front', card.frontImagePath!),
      if (card.backImagePath != null) ('Back', card.backImagePath!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SCANNED IMAGES', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < pages.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              _Thumb(
                label: pages[i].$1,
                path: pages[i].$2,
                onTap: () => openFullscreenGallery(context, pages, i),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.label, required this.path, required this.onTap});
  final String label;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: neon.panelBorder),
              ),
              clipBehavior: Clip.antiAlias,
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

/// Informational secure-clipboard footer pinned to the bottom of the screen.
class _SecureClipboardBar extends StatelessWidget {
  const _SecureClipboardBar({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neon.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neon.accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.shield_outlined, size: 20, color: neon.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SECURE CLIPBOARD',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: neon.accent)),
                  const SizedBox(height: 2),
                  Text('Sensitive copies auto-clear in ${seconds}s',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.lock_clock_outlined,
                size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
