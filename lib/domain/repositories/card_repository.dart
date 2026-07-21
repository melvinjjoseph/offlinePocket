import '../entities/card_entry.dart';

abstract interface class CardRepository {
  Future<List<CardEntry>> getAll();
  Future<CardEntry?> getById(String id);
  Future<void> save(CardEntry card);
  Future<void> update(CardEntry card);
  Future<void> delete(String id);

  /// Irreversibly removes every card, all scanned image files, and the
  /// device encryption key. Does not touch exported backup files.
  Future<void> purgeAll();
}
