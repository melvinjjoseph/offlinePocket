import 'dart:io';
import 'dart:typed_data';

import '../crypto/crypto_service.dart';
import '../keystore/keystore_service.dart';

class ImageService {
  final CryptoService _crypto;
  final KeystoreService _keystore;

  ImageService(this._crypto, this._keystore);

  Future<Uint8List> get _key async {
    final hex = await _keystore.getOrCreateKey();
    return Uint8List.fromList(
      List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  // Encrypts a file in-place — replaces plain bytes with encrypted bytes.
  Future<void> encryptFile(String path) async {
    final key = await _key;
    final plain = await File(path).readAsBytes();
    final encrypted = _crypto.encrypt(plain, key);
    await File(path).writeAsBytes(encrypted);
  }

  // Returns decrypted bytes suitable for Image.memory().
  // Falls back to raw bytes if the file is a legacy plain image (not yet encrypted).
  Future<Uint8List> decryptToBytes(String path) async {
    final key = await _key;
    final bytes = await File(path).readAsBytes();
    try {
      return _crypto.decrypt(bytes, key);
    } catch (_) {
      return bytes;
    }
  }
}
