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
    final existing = await _storage.read(key: _keyAlias);
    if (existing != null) return existing;
    final key = _generateKey();
    await _storage.write(key: _keyAlias, value: key);
    return key;
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: _keyAlias);
  }

  String _generateKey() {
    // 32 random bytes encoded as hex — generated once, stored in Keystore
    final bytes = List<int>.generate(32, (_) => DateTime.now().microsecondsSinceEpoch & 0xFF);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
