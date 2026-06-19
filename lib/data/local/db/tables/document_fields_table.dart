import 'package:drift/drift.dart';

@DataClassName('FieldRow')
class DocumentFieldsTable extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text()();
  TextColumn get keyName => text()();
  BlobColumn get encryptedValue => blob()();
  TextColumn get fieldType => text()();
  BoolColumn get isSensitive => boolean()();
  IntColumn get sortOrder => integer()();

  @override
  String get tableName => 'document_fields';

  @override
  Set<Column> get primaryKey => {id};
}
