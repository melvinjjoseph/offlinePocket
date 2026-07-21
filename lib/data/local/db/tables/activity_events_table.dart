import 'package:drift/drift.dart';

/// Local-only audit trail. Stores *references* (cardId) and event metadata —
/// never field values, never clipboard/share payloads.
@DataClassName('ActivityRow')
class ActivityEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // ActivityType.name
  IntColumn get timestamp => integer()();

  /// Reference to the card involved, if any. Deliberately not the label —
  /// the label is resolved at render time so deleted cards degrade gracefully.
  TextColumn get cardId => text().nullable()();

  /// True when the event moved sensitive values outside the app.
  BoolColumn get sensitive => boolean().withDefault(const Constant(false))();

  /// Best-effort share destination (e.g. package name). Null when unknown.
  TextColumn get target => text().nullable()();

  @override
  String get tableName => 'activity_events';

  @override
  Set<Column> get primaryKey => {id};
}
