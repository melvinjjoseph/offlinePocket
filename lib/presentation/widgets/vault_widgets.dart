import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/card_entry.dart';
import '../theme/app_theme.dart';

/// A masked one-line preview for a card, safe to show in lists (never reveals
/// a full sensitive value — at most the last 4 digits).
String cardPreviewLine(CardEntry card) {
  // Prefer a sensitive number-like field (card number, ID number).
  for (final f in card.fields) {
    if (!f.isSensitive) continue;
    final digits = f.value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return '•••• •••• •••• ${digits.substring(digits.length - 4)}';
    }
  }
  // Otherwise the first non-sensitive value, if any.
  final plain = card.fields.where((f) => !f.isSensitive && f.value.isNotEmpty);
  if (plain.isNotEmpty) return plain.first.value;
  return '${card.fields.length} field${card.fields.length == 1 ? '' : 's'}';
}

String _brandTag(CardEntry card, CategoryConfig? cat) {
  final label = cat?.label.toUpperCase() ?? 'CARD';
  if (label.contains('CREDIT') || label.contains('DEBIT')) return 'CARD';
  if (label.contains('PASSPORT')) return 'TRAVEL';
  if (label.contains('LICENSE') || label.contains('LICENCE')) return 'ID';
  if (label.contains('ID')) return 'ID';
  return label.length > 8 ? label.substring(0, 8) : label;
}

/// List row used in bucket / search / all-cards lists.
class VaultCardTile extends StatelessWidget {
  const VaultCardTile({super.key, required this.card, required this.config, this.onTap});

  final CardEntry card;
  final AppConfig config;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final cat = config.categoryById(card.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
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
                  child: Icon(cat?.iconData ?? Icons.card_membership_outlined,
                      size: 20, color: neon.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(cardPreviewLine(card),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally-scrolling card visual used in the "Recently Added" carousel.
class RecentCardVisual extends StatelessWidget {
  const RecentCardVisual({super.key, required this.card, required this.config, this.onTap});

  final CardEntry card;
  final AppConfig config;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neon = context.neon;
    final cat = config.categoryById(card.category);
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neon.panelBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -16,
              child: Icon(cat?.iconData ?? Icons.security,
                  size: 120, color: scheme.onSurface.withValues(alpha: 0.05)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(cat?.iconData ?? Icons.credit_card,
                        color: neon.accentBright, size: 24),
                    Text(_brandTag(card, cat), style: text.labelSmall),
                  ],
                ),
                const Spacer(),
                Text(cardPreviewLine(card),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(
                        color: scheme.onSurface, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(card.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
