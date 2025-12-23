import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';

void main() {
  group('FernetManager', () {
    // Reset the singleton's state before each test to ensure isolation.
    setUp(() {
      FernetManager().resetForTest();
    });

    test('factory constructor should always return the same instance', () {
      final instance1 = FernetManager();
      final instance2 = FernetManager();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should return null when encrypting or decrypting without a key', () {
      // Arrange
      final manager = FernetManager(); // Has been reset by setUp

      // Act
      final encrypted = manager.encrypt('this should fail');
      final decrypted = manager.decrypt('this should also fail');

      // Assert
      expect(encrypted, isNull);
      expect(decrypted, isNull);
    });

    test('should correctly encrypt and then decrypt a message', () {
      // Arrange
      final manager = FernetManager();
      const serialNumber = 'my-test-serial-number-12345';
      const plainText = 'This is a secret message for testing.';

      // Act: Update key and encrypt
      manager.updateKeyFromSerial(serialNumber);
      final encryptedText = manager.encrypt(plainText);

      // Assert: Encryption was successful
      expect(encryptedText, isNotNull);
      expect(encryptedText, isA<String>());
      expect(encryptedText, isNot(plainText));

      // Act: Decrypt
      final decryptedText = manager.decrypt(encryptedText!);

      // Assert: Decryption was successful
      expect(decryptedText, isNotNull);
      expect(decryptedText, plainText);
    });

    test('should fail to decrypt a message if the key changes', () {
      // Arrange
      final manager = FernetManager();
      const serialNumber1 = 'my-first-secret-serial';
      const serialNumber2 = 'a-completely-different-serial';
      const plainText = 'This message is sensitive.';

      // Act: Encrypt with the first key
      manager.updateKeyFromSerial(serialNumber1);
      final encryptedText = manager.encrypt(plainText);
      expect(encryptedText, isNotNull);

      // Act: Change to a different key and try to decrypt
      manager.updateKeyFromSerial(serialNumber2);
      final decryptedText = manager.decrypt(encryptedText!);

      // Assert: Decryption fails with the expected error message
      expect(decryptedText, 'Decryption Error (Invalid Token or Key)');
    });

    test('should fail to decrypt an invalid or malformed token', () {
      // Arrange
      final manager = FernetManager();
      const serialNumber = 'a-valid-serial-for-this-test';
      const invalidToken = 'this-is-not-a-valid-base64-fernet-token';

      // Act
      manager.updateKeyFromSerial(serialNumber);
      final decryptedText = manager.decrypt(invalidToken);

      // Assert
      expect(decryptedText, 'Decryption Error (Invalid Token or Key)');
    });
  });
}
