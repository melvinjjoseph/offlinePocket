import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/activity_events_table.dart';

part 'activity_dao.g.dart';

@DriftAccessor(tables: [ActivityEventsTable])
class ActivityDao extends DatabaseAccessor<AppDatabase> with _$ActivityDaoMixin {
  ActivityDao(super.db);

  /// Hard caps on the trail — an unbounded access log only grows exposure.
  static const maxEvents = 500;
  static const maxAgeDays = 30;

  Future<List<ActivityRow>> recent({int limit = 200}) =>
      (select(activityEventsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  Future<void> insertEvent(ActivityEventsTableCompanion event) async {
    await into(activityEventsTable).insert(event);
    await _prune();
  }

  /// Trims by age first, then by count.
  Future<void> _prune() async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: maxAgeDays))
        .millisecondsSinceEpoch;
    await (delete(activityEventsTable)
          ..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
        .go();
    await customStatement(
      'DELETE FROM activity_events WHERE id NOT IN '
      '(SELECT id FROM activity_events ORDER BY timestamp DESC LIMIT $maxEvents)',
    );
  }

  Future<void> clearAll() => delete(activityEventsTable).go();
}
