/// Categories drive both grouping and visual weight in the Activity tab.
/// [egress] ranks highest: those are the events where data left the app.
/// The internal name stays precise; [label] is what the user actually sees.
enum ActivityCategory {
  egress('Shared'),
  security('Security'),
  change('Changes');

  const ActivityCategory(this.label);
  final String label;
}

enum ActivityType {
  // ── Egress: data crossed the app's encryption boundary ──
  sharedAsText(ActivityCategory.egress),
  sharedImage(ActivityCategory.egress),
  backupExported(ActivityCategory.egress),

  // ── Security ──
  vaultUnlocked(ActivityCategory.security),
  authFailed(ActivityCategory.security),
  backupRestored(ActivityCategory.security),
  dataPurged(ActivityCategory.security);

  const ActivityType(this.category);
  final ActivityCategory category;

  static ActivityType? fromName(String name) {
    for (final t in ActivityType.values) {
      if (t.name == name) return t;
    }
    return null; // unknown/legacy rows are skipped rather than crashing
  }
}

class ActivityEvent {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final String? cardId;
  final bool sensitive;
  final String? target;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.cardId,
    this.sensitive = false,
    this.target,
  });
}
