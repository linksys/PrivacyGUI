import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/device_token_store.dart';

void main() {
  const store = DeviceTokenStore();
  const kDay = 60 * 60 * 24 * 1000;

  late Map<String, String> storage;

  void seed({required String serialNumber, int ageMs = 0}) {
    storage
      ..[pLinksysToken] = 'token-A'
      ..[pLinksysTokenSn] = serialNumber
      ..[pLinksysTokenTs] = '${DateTime.now().millisecondsSinceEpoch - ageMs}';
  }

  setUp(() {
    storage = {};
    FlutterSecureStorage.setMockInitialValues(storage);
  });

  group('read', () {
    test('returns the token of the same device', () async {
      seed(serialNumber: 'SN-A');

      expect(await store.read('SN-A'), 'token-A');
    });

    test('returns null for another device', () async {
      seed(serialNumber: 'SN-A');

      expect(await store.read('SN-B'), isNull);
    });

    test('returns null once the token expired', () async {
      seed(serialNumber: 'SN-A', ageMs: kDay + 1);

      expect(await store.read('SN-A'), isNull);
    });

    test('returns null when nothing is stored', () async {
      expect(await store.read('SN-A'), isNull);
    });

    test('returns null when the timestamp is missing', () async {
      storage
        ..[pLinksysToken] = 'token-A'
        ..[pLinksysTokenSn] = 'SN-A';

      expect(await store.read('SN-A'), isNull);
    });
  });

  test('save keeps the token together with its device', () async {
    await store.save('token-B', 'SN-B');

    expect(storage[pLinksysToken], 'token-B');
    expect(storage[pLinksysTokenSn], 'SN-B');
    expect(int.tryParse(storage[pLinksysTokenTs] ?? ''), isNotNull);
    expect(await store.read('SN-B'), 'token-B');
  });

  test('clear removes every part of the token', () async {
    seed(serialNumber: 'SN-A');

    await store.clear();

    expect(storage[pLinksysToken], isNull);
    expect(storage[pLinksysTokenSn], isNull);
    expect(storage[pLinksysTokenTs], isNull);
  });
}
