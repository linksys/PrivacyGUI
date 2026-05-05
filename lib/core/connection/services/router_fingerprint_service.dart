import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/utils/logger.dart';

const _kStorageKey = 'router_fingerprint_serial';

final routerFingerprintServiceProvider =
    Provider<RouterFingerprintService>((ref) {
  return RouterFingerprintService(const FlutterSecureStorage());
});

class RouterFingerprintService {
  RouterFingerprintService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> store(String serialNumber) async {
    await _storage.write(key: _kStorageKey, value: serialNumber);
    logger.d('[Fingerprint] Stored serial: $serialNumber');
  }

  Future<String?> read() async {
    return _storage.read(key: _kStorageKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kStorageKey);
    logger.d('[Fingerprint] Cleared');
  }

  Future<bool> matches(String serialNumber) async {
    final stored = await read();
    logger.d('[Fingerprint] matches() stored=$stored, incoming=$serialNumber');
    if (stored == null) return false;
    return stored == serialNumber;
  }
}
