import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeystoreService {
  static const _keyAlias = 'omnivault_master_key';

  final FlutterSecureStorage _storage;

  KeystoreService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
            keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          ),
        );

  Future<String> getOrCreateKey() async {
    try {
      final existing = await _storage.read(key: _keyAlias);
      if (existing != null) return existing;
    } catch (_) {
      // The EncryptedSharedPreferences backing key was deleted (e.g. the app
      // was uninstalled and reinstalled) but stale ciphertext survived in the
      // SharedPreferences XML on some Android versions/OEMs. Wipe it so we
      // can write a fresh key without hitting the same error again.
      await _storage.deleteAll();
    }
    final key = _generateKey();
    await _storage.write(key: _keyAlias, value: key);
    return key;
  }

  Future<void> deleteKey() async {
    await _storage.deleteAll();
  }

  String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
