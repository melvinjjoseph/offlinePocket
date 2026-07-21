import 'package:flutter/material.dart';
import '../../../domain/entities/card_entry.dart';

/// The three top-level buckets from the redesign. The app has 7 fine-grained
/// config categories; the dashboard folds them into these groups for browsing.
enum VaultBucket {
  payment(
    'Payment Cards',
    Icons.credit_card,
    {'creditCard', 'debitCard', 'prepaidCard'},
  ),
  government(
    'Government IDs',
    Icons.account_balance,
    {'nationalId', 'driverLicense', 'genericId'},
  ),
  travel(
    'Travel Documents',
    Icons.travel_explore,
    {'passport'},
  );

  const VaultBucket(this.label, this.icon, this.categoryIds);

  final String label;
  final IconData icon;
  final Set<String> categoryIds;

  /// Bucket a config category id belongs to, or null if unknown (orphan).
  static VaultBucket? forCategory(String categoryId) {
    for (final b in VaultBucket.values) {
      if (b.categoryIds.contains(categoryId)) return b;
    }
    return null;
  }

  bool contains(CardEntry card) => categoryIds.contains(card.category);
}

/// Compact "2h ago" style relative time for the "Last updated" subtitle.
String relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = diff.inDays ~/ 7;
  if (weeks < 5) return '${weeks}w ago';
  return '${diff.inDays ~/ 30}mo ago';
}
