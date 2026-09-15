// The credentials that have to survive a firmware reboot, behind
// linksys/PrivacyGUI#1553 (REQ-B4).
//
// The setup-complete screen is the only place the new SSID and passphrase are ever
// shown, and the firmware stage reboots the router between the moment they are
// decided and the moment they are shown. So this store is the difference between a
// user who can join their new network and a user who has to factory-reset to find
// out what they just named it.
//
// Two properties are worth a test each and they pull in opposite directions:
// the value must **round-trip exactly** — a passphrase that comes back subtly
// different is worse than one that does not come back at all, since the user will
// try it — and every verb must **swallow**, because a keystore that is unavailable
// must not be what stops setup finishing.
//
// Shaped after `test/core/connection/services/router_fingerprint_service_test.dart`,
// whose service this store is modelled on.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_ready_band.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_wifi_ready_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  /// The key `store` writes. Spelled out rather than imported, because the
  /// constant in the store is private on purpose: what has to keep working across
  /// an app upgrade is the *string*, and a test that read the constant would follow
  /// a rename that orphans everything already in a user's keystore.
  const key = 'pnp_wifi_ready_credentials';

  late MockFlutterSecureStorage storage;
  late PnpWifiReadyStore store;

  setUp(() {
    storage = MockFlutterSecureStorage();
    store = PnpWifiReadyStore(storage);
  });

  /// What the store hands the keystore, or null when it never wrote.
  String? writtenValue() {
    final calls = verify(() => storage.write(
          key: key,
          value: captureAny(named: 'value'),
        )).captured;
    return calls.isEmpty ? null : calls.last as String?;
  }

  group('PnpWifiReadyStore — unified mode', () {
    const phase = WizardWifiReady(
      ssid: 'MyNewNetwork',
      password: r'p@ssw0rd with spaces & symbols',
    );

    test('round-trips through the keystore', () async {
      // The whole point in one test: what `read()` returns after a reboot has to
      // equal what `store()` was given. `WizardWifiReady` is `Equatable`, so this
      // compares every field rather than the two the assertions below name.
      when(() => storage.write(key: key, value: any(named: 'value')))
          .thenAnswer((_) async {});
      await store.store(phase);

      when(() => storage.read(key: key))
          .thenAnswer((_) async => writtenValue());
      final restored = await store.read();

      expect(restored, phase);
      // Named separately because equality would also pass on a store that wrote
      // and read a placeholder. These are the two strings a user types.
      expect(restored!.ssid, 'MyNewNetwork');
      expect(restored.password, r'p@ssw0rd with spaces & symbols');
      expect(restored.isSplitMode, isFalse);
    });

    test('writes JSON, not the phase\'s toString', () async {
      // `jsonEncode` on an object with no `toJson` throws rather than falling back
      // to `toString`, so this cannot regress silently — but the shape is a
      // migration surface, and pinning it is what makes a future format change a
      // decision instead of a surprise.
      when(() => storage.write(key: key, value: any(named: 'value')))
          .thenAnswer((_) async {});

      await store.store(phase);

      final decoded = jsonDecode(writtenValue()!) as Map<String, dynamic>;
      expect(decoded['ssid'], 'MyNewNetwork');
      expect(decoded['bands'], isEmpty);
    });
  });

  group('PnpWifiReadyStore — split mode', () {
    // Three bands, because `isSplitMode` is `bands.length > 1` and a restored
    // one-band snapshot must read as unified. This is the state the reboot is most
    // likely to destroy: the per-band SSIDs exist nowhere else once the wizard's
    // in-memory config is gone.
    const phase = WizardWifiReady(
      ssid: 'Linksys-2.4G',
      password: 'band-password-24',
      bands: [
        PnpWifiReadyBand(
            bandName: '2.4 GHz', ssid: 'Linksys-2.4G', password: 'pass-24'),
        PnpWifiReadyBand(
            bandName: '5 GHz', ssid: 'Linksys-5G', password: 'pass-5'),
        PnpWifiReadyBand(
            bandName: '6 GHz', ssid: 'Linksys-6G', password: 'pass-6'),
      ],
    );

    test('round-trips every band', () async {
      when(() => storage.write(key: key, value: any(named: 'value')))
          .thenAnswer((_) async {});
      await store.store(phase);

      when(() => storage.read(key: key))
          .thenAnswer((_) async => writtenValue());
      final restored = await store.read();

      expect(restored, phase);
      expect(restored!.isSplitMode, isTrue);
      expect(restored.bands.map((b) => b.ssid),
          ['Linksys-2.4G', 'Linksys-5G', 'Linksys-6G']);
      expect(restored.bands.map((b) => b.password),
          ['pass-24', 'pass-5', 'pass-6']);
    });
  });

  group('PnpWifiReadyStore — nothing to restore', () {
    test('reads null when the key was never written', () async {
      when(() => storage.read(key: key)).thenAnswer((_) async => null);

      expect(await store.read(), isNull);
    });

    test('reads null on an empty string', () async {
      // Some keystore backends return '' rather than null for a deleted key.
      when(() => storage.read(key: key)).thenAnswer((_) async => '');

      expect(await store.read(), isNull);
    });

    test('reads null on malformed JSON instead of throwing', () async {
      // A corrupt keystore or a format change. Either way the caller falls back to
      // the in-memory phase, which is a worse screen than the right one and a much
      // better screen than a crash.
      when(() => storage.read(key: key)).thenAnswer((_) async => 'not json {');

      expect(await store.read(), isNull);
    });

    test('reads null on JSON that parses but is the wrong shape', () async {
      // `ssid` is a required cast in `fromJson`, so its absence is a
      // `TypeError` — which is not an exception `on FormatException` would catch.
      // This is the case that decides the store's `catch (e)` is unqualified.
      when(() => storage.read(key: key))
          .thenAnswer((_) async => jsonEncode({'bands': []}));

      expect(await store.read(), isNull);
    });
  });

  group('PnpWifiReadyStore — a keystore that fails', () {
    // The requirement these three serve is REQ-B3's principle rather than REQ-B4's
    // outcome: the firmware stage is a bonus, finishing setup is not. Every verb
    // here is called from a path whose next step is showing the user their network,
    // and none of them may throw into it.
    test('store swallows a write failure', () async {
      when(() => storage.write(key: key, value: any(named: 'value')))
          .thenThrow(PlatformException(code: 'keystore unavailable'));

      await expectLater(
        store.store(const WizardWifiReady(ssid: 'S', password: 'P')),
        completes,
      );
    });

    test('read swallows a read failure', () async {
      when(() => storage.read(key: key))
          .thenThrow(PlatformException(code: 'keystore unavailable'));

      expect(await store.read(), isNull);
    });

    test('clear swallows a delete failure', () async {
      when(() => storage.delete(key: key))
          .thenThrow(PlatformException(code: 'keystore unavailable'));

      await expectLater(store.clear(), completes);
    });

    test('clear deletes the key', () async {
      when(() => storage.delete(key: key)).thenAnswer((_) async {});

      await store.clear();

      verify(() => storage.delete(key: key)).called(1);
    });
  });
}

/// Stands in for the platform channel's error type.
///
/// `flutter_secure_storage` throws `PlatformException` from every method on every
/// platform, and the real class lives in `services.dart` — importing Flutter's
/// bindings into a service test to construct one exception is more coupling than
/// the assertion is worth. What the store's `catch (e)` sees is an object, and the
/// tests above measure that it does not care which.
class PlatformException implements Exception {
  PlatformException({required this.code});
  final String code;
  @override
  String toString() => 'PlatformException($code)';
}
