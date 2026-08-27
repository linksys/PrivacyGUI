import 'dart:collection';

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
      ..[pLinksysTokenSN] = serialNumber
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
        ..[pLinksysTokenSN] = 'SN-A';

      expect(await store.read('SN-A'), isNull);
    });

    test('returns null without a device, even for a stored empty device',
        () async {
      seed(serialNumber: '');

      expect(await store.read(''), isNull);
    });

    test('returns null when the stored token is empty', () async {
      seed(serialNumber: 'SN-A');
      storage[pLinksysToken] = '';

      expect(await store.read('SN-A'), isNull);
    });
  });

  group('save', () {
    test('keeps the token together with its device', () async {
      await store.save('token-B', 'SN-B');

      expect(storage[pLinksysToken], 'token-B');
      expect(storage[pLinksysTokenSN], 'SN-B');
      expect(int.tryParse(storage[pLinksysTokenTs] ?? ''), isNotNull);
      expect(await store.read('SN-B'), 'token-B');
    });

    test('stores nothing without a device', () async {
      await store.save('token-B', '');

      expect(storage, isEmpty);
    });

    test('stores nothing without a token', () async {
      await store.save('', 'SN-B');

      expect(storage, isEmpty);
    });

    test('interrupted half way, cannot be read back for the previous device',
        () async {
      final data = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(
          _InterruptedStorage(data, allowedMutations: 1));
      data
        ..[pLinksysToken] = 'token-A'
        ..[pLinksysTokenSN] = 'SN-A'
        ..[pLinksysTokenTs] = '${DateTime.now().millisecondsSinceEpoch}';

      await expectLater(store.save('token-B', 'SN-B'), throwsStateError);

      expect(await store.read('SN-A'), isNull);
      expect(await store.read('SN-B'), isNull);
    });
  });

  test('clear removes every part of the token', () async {
    seed(serialNumber: 'SN-A');

    await store.clear();

    expect(storage[pLinksysToken], isNull);
    expect(storage[pLinksysTokenSN], isNull);
    expect(storage[pLinksysTokenTs], isNull);
  });
}

/// Secure storage that refuses to change anything after [allowedMutations],
/// standing in for a save that is interrupted before it finishes writing all of
/// its keys.
class _InterruptedStorage extends MapBase<String, String> {
  _InterruptedStorage(this._data, {required this.allowedMutations});

  final Map<String, String> _data;
  final int allowedMutations;
  int _mutations = 0;

  void _mutate() {
    if (_mutations++ >= allowedMutations) {
      throw StateError('storage interrupted');
    }
  }

  @override
  String? operator [](Object? key) => _data[key as String];

  @override
  void operator []=(String key, String value) {
    _mutate();
    _data[key] = value;
  }

  @override
  String? remove(Object? key) {
    _mutate();
    return _data.remove(key);
  }

  @override
  void clear() => _data.clear();

  @override
  Iterable<String> get keys => _data.keys;
}
