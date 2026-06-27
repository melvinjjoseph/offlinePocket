import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../crypto/crypto_service.dart';
import '../keystore/keystore_service.dart';

// Top-level so compute() can send it to a background isolate.
Uint8List _decryptInIsolate((Uint8List bytes, Uint8List key) args) {
  try {
    return CryptoService().decrypt(args.$1, args.$2);
  } catch (_) {
    return args.$1; // legacy plain-image fallback
  }
}

class ImageService {
  final CryptoService _crypto;
  final KeystoreService _keystore;

  ImageService(this._crypto, this._keystore);

  // Session cache: each path is decrypted at most once per app lifecycle.
  final _cache = <String, Future<Uint8List>>{};

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
    _cache.remove(path); // invalidate if the file is replaced
    final key = await _key;
    final plain = await File(path).readAsBytes();
    final encrypted = _crypto.encrypt(plain, key);
    await File(path).writeAsBytes(encrypted);
  }

  // Returns decrypted bytes. Cached — subsequent calls for the same path
  // return instantly without re-reading or re-decrypting.
  Future<Uint8List> decryptToBytes(String path) =>
      _cache.putIfAbsent(path, () => _decryptToBytes(path));

  Future<Uint8List> _decryptToBytes(String path) async {
    final key = await _key;
    final bytes = await File(path).readAsBytes();
    // AES-GCM decryption on a background isolate — keeps the UI thread free.
    return compute(_decryptInIsolate, (bytes, key));
  }
}
