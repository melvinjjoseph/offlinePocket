import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'dart:math';

class CryptoService {
  static const _ivLength = 12;
  static const _tagLength = 16;

  /// Encrypts [plaintext] and returns [iv (12 bytes) + ciphertext + tag (16 bytes)].
  Uint8List encrypt(Uint8List plaintext, Uint8List keyBytes) {
    final iv = _randomBytes(_ivLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(keyBytes), _tagLength * 8, iv, Uint8List(0)));

    final output = Uint8List(plaintext.length + _tagLength);
    var offset = 0;
    offset += cipher.processBytes(plaintext, 0, plaintext.length, output, offset);
    cipher.doFinal(output, offset);

    return Uint8List.fromList([...iv, ...output]);
  }

  /// Decrypts a blob produced by [encrypt].
  Uint8List decrypt(Uint8List blob, Uint8List keyBytes) {
    final iv = blob.sublist(0, _ivLength);
    final ciphertext = blob.sublist(_ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(keyBytes), _tagLength * 8, iv, Uint8List(0)));

    final output = Uint8List(ciphertext.length - _tagLength);
    var offset = 0;
    offset += cipher.processBytes(ciphertext, 0, ciphertext.length, output, offset);
    cipher.doFinal(output, offset);

    return output;
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
