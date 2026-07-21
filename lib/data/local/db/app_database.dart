import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/activity_events_table.dart';
import 'tables/card_entries_table.dart';
import 'tables/document_fields_table.dart';
import 'dao/activity_dao.dart';
import 'dao/cards_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CardEntriesTable, DocumentFieldsTable, ActivityEventsTable],
  daos: [CardsDao, ActivityDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
                cardEntriesTable, cardEntriesTable.frontImagePath);
            await migrator.addColumn(
                cardEntriesTable, cardEntriesTable.backImagePath);
          }
          if (from < 3) {
            // paymentCard was split into creditCard / debitCard / prepaidCard;
            // migrate any existing rows to creditCard as best guess.
            await customStatement(
              "UPDATE card_entries SET category = 'creditCard' WHERE category = 'paymentCard'",
            );
          }
          if (from < 4) {
            await migrator.createTable(activityEventsTable);
          }
        },
      );

  // SQLCipher database-level encryption is applied via platform channel on first open.
  // Field-level AES-256-GCM encryption in CardRepositoryImpl is the primary security layer.
  static AppDatabase create() {
    return AppDatabase(driftDatabase(name: 'omnivault'));
  }
}
