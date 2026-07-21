import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' show InvalidCipherTextException;
import 'package:uuid/uuid.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/keystore/keystore_service.dart';
import '../../domain/entities/card_entry.dart';
import '../../domain/entities/document_field.dart';
import '../../domain/repositories/card_repository.dart';
import '../local/db/app_database.dart';

class CardRepositoryImpl implements CardRepository {
  final AppDatabase _db;
  final CryptoService _crypto;
  final KeystoreService _keystore;
  final _uuid = const Uuid();

  CardRepositoryImpl(this._db, this._crypto, this._keystore);

  Future<Uint8List> get _keyBytes async {
    final hex = await _keystore.getOrCreateKey();
    return Uint8List.fromList(
      List.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }

  @override
  Future<List<CardEntry>> getAll() async {
    try {
      final rows = await _db.cardsDao.getAllCards();
      return await Future.wait(rows.map(_rowToEntry));
    } on InvalidCipherTextException {
      // Key mismatch — stale encrypted rows from a previous install whose
      // Keystore key no longer exists. Wipe storage and database so the app
      // starts clean rather than staying in a permanent error state.
      await _keystore.deleteKey();
      await _db.cardsDao.deleteAllCards();
      return [];
    }
  }

  @override
  Future<CardEntry?> getById(String id) async {
    final row = await _db.cardsDao.getCardById(id);
    if (row == null) return null;
    return _rowToEntry(row);
  }

  @override
  Future<void> save(CardEntry card) async {
    final key = await _keyBytes;
    await _db.cardsDao.upsertCard(CardEntriesTableCompanion.insert(
      id: card.id,
      category: card.category,
      label: card.label,
      createdAt: card.createdAt.millisecondsSinceEpoch,
      frontImagePath: Value(card.frontImagePath),
      backImagePath: Value(card.backImagePath),
    ));

    for (var i = 0; i < card.fields.length; i++) {
      final field = card.fields[i];
      final encrypted = _crypto.encrypt(
        Uint8List.fromList(utf8.encode(field.value)),
        key,
      );
      await _db.cardsDao.upsertField(DocumentFieldsTableCompanion.insert(
        id: _uuid.v4(),
        cardId: card.id,
        keyName: field.key,
        encryptedValue: encrypted,
        fieldType: field.type.name,
        isSensitive: field.isSensitive,
        sortOrder: i,
      ));
    }
  }

  @override
  Future<void> update(CardEntry card) async {
    final key = await _keyBytes;
    await _db.cardsDao.upsertCard(CardEntriesTableCompanion.insert(
      id: card.id,
      category: card.category,
      label: card.label,
      createdAt: card.createdAt.millisecondsSinceEpoch,
      frontImagePath: Value(card.frontImagePath),
      backImagePath: Value(card.backImagePath),
    ));
    // Replace all fields — delete old rows first to avoid orphans from UUID changes.
    await _db.cardsDao.deleteFieldsForCard(card.id);
    for (var i = 0; i < card.fields.length; i++) {
      final field = card.fields[i];
      final encrypted = _crypto.encrypt(
        Uint8List.fromList(utf8.encode(field.value)),
        key,
      );
      await _db.cardsDao.upsertField(DocumentFieldsTableCompanion.insert(
        id: _uuid.v4(),
        cardId: card.id,
        keyName: field.key,
        encryptedValue: encrypted,
        fieldType: field.type.name,
        isSensitive: field.isSensitive,
        sortOrder: i,
      ));
    }
  }

  @override
  Future<void> delete(String id) => _db.cardsDao.deleteCard(id);

  @override
  Future<void> purgeAll() async {
    // Order matters: wipe the database first so no row can ever reference a
    // file we failed to delete. Image cleanup and key deletion are then
    // best-effort — neither should leave the vault in a half-purged state.
    await _db.cardsDao.deleteAllCards();
    // The activity trail names what was in the vault — it must not survive.
    await _db.activityDao.clearAll();

    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'card_images'));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort: files left behind are unreadable once the key is gone.
    }

    // Dropping the key renders any residual ciphertext undecryptable.
    try {
      await _keystore.deleteKey();
    } catch (_) {}
  }

  Future<CardEntry> _rowToEntry(CardRow row) async {
    final key = await _keyBytes;
    final fieldRows = await _db.cardsDao.getFieldsForCard(row.id);
    final fields = fieldRows.map((f) {
      final decrypted = utf8.decode(_crypto.decrypt(f.encryptedValue, key));
      return DocumentField(
        key: f.keyName,
        value: decrypted,
        type: FieldType.values.byName(f.fieldType),
        isSensitive: f.isSensitive,
      );
    }).toList();

    return CardEntry(
      id: row.id,
      category: row.category,
      label: row.label,
      fields: fields,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      frontImagePath: row.frontImagePath,
      backImagePath: row.backImagePath,
    );
  }
}
