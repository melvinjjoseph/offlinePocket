import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../../domain/entities/card_entry.dart';
import '../../domain/entities/document_field.dart';
import '../crypto/crypto_service.dart';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}

/// Holds the decrypted cards and any image bytes extracted from the backup.
/// Image paths on [cards] are null — the caller is responsible for writing
/// the [images] bytes to disk, re-encrypting them, and setting the paths.
class RestoredBackup {
  final List<CardEntry> cards;

  /// cardId → (frontBytes, backBytes). Both values are null if the card had no image.
  final Map<String, (Uint8List?, Uint8List?)> images;

  const RestoredBackup({required this.cards, required this.images});
}

class BackupService {
  static final _magic = Uint8List.fromList('OPBACKUP'.codeUnits);
  static const _fileVersion = 1;
  static const _saltLength = 16;
  static const _pbkdf2Iterations = 100000;
  static const _keyLength = 32;

  final CryptoService _crypto;

  BackupService(this._crypto);

  /// Encrypts cards (and optional plaintext image bytes) into a .opbackup blob.
  ///
  /// [images] maps card ID → (frontBytes, backBytes) where bytes are the
  /// *plaintext* image data (already decrypted from the device keystore).
  Uint8List export(
    List<CardEntry> cards,
    String password, {
    Map<String, (Uint8List?, Uint8List?)> images = const {},
  }) {
    final salt = _randomBytes(_saltLength);
    final key = _deriveKey(password, salt);

    final payload = jsonEncode({
      'version': _fileVersion,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'cards': cards.map((c) {
        final img = images[c.id];
        return {
          'id': c.id,
          'category': c.category,
          'label': c.label,
          'created_at': c.createdAt.millisecondsSinceEpoch,
          'fields': c.fields
              .map((f) => {
                    'key': f.key,
                    'value': f.value,
                    'type': f.type.name,
                    'is_sensitive': f.isSensitive,
                  })
              .toList(),
          if (img?.$1 != null) 'front_image': base64Encode(img!.$1!),
          if (img?.$2 != null) 'back_image': base64Encode(img!.$2!),
        };
      }).toList(),
    });

    final encrypted = _crypto.encrypt(
      Uint8List.fromList(utf8.encode(payload)),
      key,
    );

    return Uint8List.fromList([..._magic, _fileVersion, ...salt, ...encrypted]);
  }

  /// Decrypts a .opbackup blob and returns cards with their image bytes.
  /// Throws [BackupException] on wrong password or corrupt file.
  RestoredBackup restore(Uint8List bytes, String password) {
    _assertValid(bytes);

    final salt = bytes.sublist(_magic.length + 1, _magic.length + 1 + _saltLength);
    final encrypted = bytes.sublist(_magic.length + 1 + _saltLength);
    final key = _deriveKey(password, salt);

    Uint8List plaintext;
    try {
      plaintext = _crypto.decrypt(encrypted, key);
    } catch (_) {
      throw const BackupException('Incorrect password or corrupted backup.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Corrupted backup file.');
    }

    final cards = <CardEntry>[];
    final images = <String, (Uint8List?, Uint8List?)>{};

    for (final c in data['cards'] as List<dynamic>) {
      final m = c as Map<String, dynamic>;
      final id = m['id'] as String;

      cards.add(CardEntry(
        id: id,
        category: m['category'] as String,
        label: m['label'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        fields: (m['fields'] as List<dynamic>).map((f) {
          final fm = f as Map<String, dynamic>;
          return DocumentField(
            key: fm['key'] as String,
            value: fm['value'] as String,
            type: FieldType.values.byName(fm['type'] as String),
            isSensitive: fm['is_sensitive'] as bool,
          );
        }).toList(),
        // Paths are intentionally null — set by the caller after writing images to disk.
      ));

      final frontB64 = m['front_image'] as String?;
      final backB64 = m['back_image'] as String?;
      if (frontB64 != null || backB64 != null) {
        images[id] = (
          frontB64 != null ? base64Decode(frontB64) : null,
          backB64 != null ? base64Decode(backB64) : null,
        );
      }
    }

    return RestoredBackup(cards: cards, images: images);
  }

  void _assertValid(Uint8List bytes) {
    if (bytes.length < _magic.length + 1 + _saltLength) {
      throw const BackupException('Not a valid OfflinePocket backup file.');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        throw const BackupException('Not a valid OfflinePocket backup file.');
      }
    }
    final version = bytes[_magic.length];
    if (version != _fileVersion) {
      throw BackupException('Unsupported backup version $version.');
    }
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
    return kdf.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
