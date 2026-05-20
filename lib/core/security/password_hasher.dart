import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static const _algorithm = 'pbkdf2_sha256';
  static const _iterations = 120000;
  static const _saltLength = 16;
  static const _keyLength = 32;

  static String hash(String password) {
    final salt = _randomBytes(_saltLength);
    final key = _pbkdf2(password, salt, _iterations, _keyLength);
    return [
      _algorithm,
      _iterations.toString(),
      base64UrlEncode(salt),
      base64UrlEncode(key),
    ].join(r'$');
  }

  static bool verify(String password, String storedHash) {
    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts.first != _algorithm) {
      return false;
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return false;
    }

    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64Url.decode(parts[2]);
      expected = base64Url.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = _pbkdf2(password, salt, iterations, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  static bool isHash(String value) => value.startsWith('$_algorithm\$');

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _pbkdf2(
    String password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (keyLength / hmac.convert(<int>[]).bytes.length).ceil();
    final output = BytesBuilder();

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      var block = hmac.convert([...salt, ..._int32(blockIndex)]).bytes;
      final result = List<int>.from(block);

      for (var i = 1; i < iterations; i++) {
        block = hmac.convert(block).bytes;
        for (var j = 0; j < result.length; j++) {
          result[j] ^= block[j];
        }
      }

      output.add(result);
    }

    return Uint8List.fromList(output.toBytes().take(keyLength).toList());
  }

  static List<int> _int32(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
