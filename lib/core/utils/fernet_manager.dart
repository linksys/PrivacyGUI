import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // Add crypto import
import 'package:meta/meta.dart';
import 'package:privacy_gui/core/utils/logger.dart';

class FernetManager {
  static final FernetManager _instance = FernetManager._internal();
  factory FernetManager() => _instance;
  FernetManager._internal();

  Encrypter? _encrypter;

  @visibleForTesting
  void resetForTest() {
    _encrypter = null;
  }

  // Public method to update key from a serial number
  void updateKeyFromSerial(String serialNumber) {
    final rawKeyString = _deriveKeyFromSerial(serialNumber);
    _updateKey(rawKeyString);
  }

  // Made the original updateKey private
  void _updateKey(String rawKeyString) {
    try {
      Uint8List rawBytes = Uint8List.fromList(utf8.encode(rawKeyString));
      if (rawBytes.length != 32) {
        logger.e('Fernet Key must be 32 bytes long! Current length: ${rawBytes.length}');
        _encrypter = null;
        return;
      }
      String base64Key = base64Url.encode(rawBytes);
      final key = Key.fromBase64(base64Key);
      _encrypter = Encrypter(Fernet(key));
      logger.d('FernetManager key updated successfully.');
    } catch (e) {
      logger.e('Error updating FernetManager key: $e');
      _encrypter = null;
    }
  }

  // Moved from key_derivation.dart
  String _deriveKeyFromSerial(String serialNumber) {
    var bytes = utf8.encode(serialNumber); // data being hashed
    var digest = sha256.convert(bytes);
    // Take the first 32 characters of the hex digest.
    return digest.toString().substring(0, 32);
  }

  String? encrypt(String plainText) {
    if (_encrypter == null) {
      logger.w('Fernet encrypter not initialized, cannot encrypt.');
      return null;
    }
    try {
      return _encrypter!.encrypt(plainText).base64;
    } catch (e) {
      logger.e('Fernet encryption failed: $e');
      return null;
    }
  }
  
  String? decrypt(String cipherTextBase64) {
    if (_encrypter == null) {
      logger.w('Fernet encrypter not initialized, cannot decrypt.');
      return null;
    }
    try {
      final encrypted = Encrypted.fromBase64(cipherTextBase64);
      return _encrypter!.decrypt(encrypted);
    } catch (e) {
      logger.e('Fernet decryption failed: $e');
      return 'Decryption Error (Invalid Token or Key)';
    }
  }
}
