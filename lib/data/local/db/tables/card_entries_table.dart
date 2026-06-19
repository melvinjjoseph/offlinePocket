import 'package:drift/drift.dart';

@DataClassName('CardRow')
class CardEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()(); // CardCategory.name
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
  TextColumn get frontImagePath => text().nullable()();
  TextColumn get backImagePath => text().nullable()();

  @override
  String get tableName => 'card_entries';

  @override
  Set<Column> get primaryKey => {id};
}
