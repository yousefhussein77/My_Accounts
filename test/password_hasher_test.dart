import 'package:flutter_test/flutter_test.dart';
import 'package:my_accounts/core/security/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hashes and verifies the original password', () {
      final hash = PasswordHasher.hash('StrongPass#123');

      expect(PasswordHasher.isHash(hash), isTrue);
      expect(PasswordHasher.verify('StrongPass#123', hash), isTrue);
      expect(PasswordHasher.verify('WrongPass#123', hash), isFalse);
    });

    test('uses a different salt for each hash', () {
      final first = PasswordHasher.hash('StrongPass#123');
      final second = PasswordHasher.hash('StrongPass#123');

      expect(first, isNot(second));
      expect(PasswordHasher.verify('StrongPass#123', first), isTrue);
      expect(PasswordHasher.verify('StrongPass#123', second), isTrue);
    });

    test('rejects malformed hashes', () {
      expect(PasswordHasher.verify('password', ''), isFalse);
      expect(PasswordHasher.verify('password', 'plain-password'), isFalse);
      expect(
        PasswordHasher.verify('password', r'pbkdf2_sha256$bad$hash$value'),
        isFalse,
      );
      expect(
        PasswordHasher.verify('password', r'pbkdf2_sha256$120000$***$***'),
        isFalse,
      );
    });
  });
}
