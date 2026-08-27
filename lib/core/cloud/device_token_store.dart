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
    if (serialNumber.isEmpty) {
      // Without a device there is nothing a stored token could belong to.
      return null;
    }
    final storedSerialNumber = await _storage.read(key: pLinksysTokenSN);
    if (storedSerialNumber != serialNumber) {
      return null;
    }
    final timestamp =
        int.tryParse(await _storage.read(key: pLinksysTokenTs) ?? '');
    if (timestamp == null ||
        DateTime.now().millisecondsSinceEpoch - timestamp > _expirationMs) {
      return null;
    }
    final token = await _storage.read(key: pLinksysToken);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> save(String token, String serialNumber) async {
    if (token.isEmpty || serialNumber.isEmpty) {
      // Nothing worth caching, and an entry without a device could later be
      // handed back to the wrong one.
      return;
    }
    // The three keys are not written atomically, so the serial number doubles
    // as the commit marker: it is removed before the token changes and written
    // back last. A save that is interrupted half way therefore reads back as a
    // miss instead of handing the new token out for the previous device.
    await _storage.delete(key: pLinksysTokenSN);
    await _storage.write(key: pLinksysToken, value: token);
    await _storage.write(
      key: pLinksysTokenTs,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );
    await _storage.write(key: pLinksysTokenSN, value: serialNumber);
  }

  Future<void> clear() async {
    // Same reason as in [save]: drop the commit marker first, so an interrupted
    // clear cannot leave a readable token behind.
    await _storage.delete(key: pLinksysTokenSN);
    await _storage.delete(key: pLinksysToken);
    await _storage.delete(key: pLinksysTokenTs);
  }
}
