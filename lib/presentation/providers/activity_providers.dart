import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/db/app_database.dart';
import '../../data/local/db/dao/activity_dao.dart';
import '../../domain/entities/activity_event.dart';
import 'card_providers.dart';

final activityDaoProvider =
    Provider<ActivityDao>((ref) => ref.read(databaseProvider).activityDao);

/// User-facing switch for the audit trail. Some users won't want a behavioural
/// record kept at all, so logging is disableable. Defaults to on.
class ActivityLoggingNotifier extends Notifier<bool> {
  static const _key = 'activity_logging_enabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final activityLoggingEnabledProvider =
    NotifierProvider<ActivityLoggingNotifier, bool>(ActivityLoggingNotifier.new);

class ActivityLogger {
  ActivityLogger(this._ref);
  final Ref _ref;
  static const _uuid = Uuid();

  /// Records an event. Never throws — logging must not break the action it
  /// is recording.
  Future<void> log(
    ActivityType type, {
    String? cardId,
    bool sensitive = false,
    String? target,
  }) async {
    if (!_ref.read(activityLoggingEnabledProvider)) return;
    try {
      await _ref.read(activityDaoProvider).insertEvent(
            ActivityEventsTableCompanion.insert(
              id: _uuid.v4(),
              type: type.name,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              cardId: Value(cardId),
              sensitive: Value(sensitive),
              target: Value(target),
            ),
          );
      _ref.invalidate(activityLogProvider);
    } catch (_) {
      // Swallow — an audit-trail failure must never surface to the user.
    }
  }
}

final activityLoggerProvider =
    Provider<ActivityLogger>((ref) => ActivityLogger(ref));

class ActivityLogNotifier extends AsyncNotifier<List<ActivityEvent>> {
  @override
  Future<List<ActivityEvent>> build() async {
    final rows = await ref.read(activityDaoProvider).recent();
    return rows
        .map((r) {
          final type = ActivityType.fromName(r.type);
          if (type == null) return null; // skip unknown/legacy rows
          return ActivityEvent(
            id: r.id,
            type: type,
            timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestamp),
            cardId: r.cardId,
            sensitive: r.sensitive,
            target: r.target,
          );
        })
        .nonNulls
        .toList();
  }

  Future<void> clear() async {
    await ref.read(activityDaoProvider).clearAll();
    ref.invalidateSelf();
  }
}

final activityLogProvider =
    AsyncNotifierProvider<ActivityLogNotifier, List<ActivityEvent>>(
        ActivityLogNotifier.new);
