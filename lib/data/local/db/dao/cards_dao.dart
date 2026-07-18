import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/card_entries_table.dart';
import '../tables/document_fields_table.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [CardEntriesTable, DocumentFieldsTable])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Future<List<CardRow>> getAllCards() => select(cardEntriesTable).get();

  Future<CardRow?> getCardById(String id) =>
      (select(cardEntriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<FieldRow>> getFieldsForCard(String cardId) =>
      (select(documentFieldsTable)
            ..where((t) => t.cardId.equals(cardId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> upsertCard(CardEntriesTableCompanion card) =>
      into(cardEntriesTable).insertOnConflictUpdate(card);

  Future<void> upsertField(DocumentFieldsTableCompanion field) =>
      into(documentFieldsTable).insertOnConflictUpdate(field);

  Future<void> deleteFieldsForCard(String cardId) =>
      (delete(documentFieldsTable)..where((t) => t.cardId.equals(cardId))).go();

  Future<void> deleteCard(String id) async {
    await (delete(documentFieldsTable)..where((t) => t.cardId.equals(id))).go();
    await (delete(cardEntriesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllCards() async {
    await delete(documentFieldsTable).go();
    await delete(cardEntriesTable).go();
  }
}
