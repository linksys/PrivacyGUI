import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/pref_key.dart';

/// Owns the linksys device token that lives in secure storage.
///
/// The cloud issues a token for one specific device, so the token is only ever
/// handed back for the serial number it was issued for. Sharing a browser
/// between two devices therefore cannot make the second one send the first
/// one's token.
class DeviceTokenStore {
  const DeviceTokenStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const int _expirationMs = 60 * 60 * 24 * 1000;

  /// The stored token, but only when it was issued for [serialNumber] and has
  /// not expired. Anything else is a miss and must be re-fetched.
  Future<String?> read(String serialNumber) async {
    final storedSerialNumber = await _storage.read(key: pLinksysTokenSn);
    if (storedSerialNumber != serialNumber) {
      return null;
    }
    final timestamp =
        int.tryParse(await _storage.read(key: pLinksysTokenTs) ?? '');
    if (timestamp == null ||
        DateTime.now().millisecondsSinceEpoch - timestamp > _expirationMs) {
      return null;
    }
    return _storage.read(key: pLinksysToken);
  }

  Future<void> save(String token, String serialNumber) async {
    await _storage.write(key: pLinksysToken, value: token);
    await _storage.write(key: pLinksysTokenSn, value: serialNumber);
    await _storage.write(
      key: pLinksysTokenTs,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: pLinksysToken);
    await _storage.delete(key: pLinksysTokenSn);
    await _storage.delete(key: pLinksysTokenTs);
  }
}
