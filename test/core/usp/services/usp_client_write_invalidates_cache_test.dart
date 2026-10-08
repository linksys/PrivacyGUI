// A write drops the throttler's GET cache, so a read after it reaches the router.
//
// THE DEFECT, measured on the bench (FW 2.0.2, 2026-10-07, #1660). The page read
// `Device.UPnP.Device.Enable` = 0 at 13:34:19, the user switched it on and saved,
// the Set returned `UspSuccess` at 13:34:22.693 — and the confirming read at
// 13:34:22.694 answered `false` in 1 ms without dispatching a GET. It was the
// 13:34:19 answer, still inside `BridgeRequestThrottler.defaultCacheTtl` (5 s),
// because the cache is keyed on the request's paths alone and nothing a write
// did touched it. The router was ON; the switch drew OFF.
//
// That is every page that saves and then re-reads, not one page: the throttler
// sits under all of `UspClient.get`, and the save → re-read sequence is the
// `Preservable` mixin's own (`save()` ends in `fetch(forceRemote: true)`, which
// the cache does not see). It needs only a read inside 5 s of the write, which a
// user toggling a switch off and on again produces.
//
// What the fix promises, pinned below: every mutating entry point of the façade
// drops the completed-GET cache once it has been issued — on failure as well,
// because a refused or partial write may still have changed the router, and an
// extra GET is cheaper than a stale one.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

/// A router of one leaf: a write changes what the next read returns, and every
/// read is counted, so a read the cache answered shows up as a missing call.
class _OneLeafRouter implements UspTransport {
  String value = '0';
  int gets = 0;
  bool failWrites = false;

  Map<String, dynamic> _writeResult() {
    if (failWrites) throw StateError('Set failed: Transport error: refused');
    return {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };
  }

  @override
  Future<Map<String, String>> get(List<String> paths) async {
    gets++;
    return {for (final p in paths) p: value};
  }

  @override
  Future<Map<String, dynamic>> set(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    final result = _writeResult();
    value = parameters.values.first;
    return result;
  }

  @override
  Future<Map<String, dynamic>> setOrdered(
      List<List<Map<String, String>>> parameterGroups,
      {bool allowPartial = false}) async {
    final result = _writeResult();
    value = '1';
    return result;
  }

  @override
  Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
      {bool allowPartial = false}) async {
    final result = _writeResult();
    value = '1';
    return result;
  }

  @override
  Future<Map<String, dynamic>> delete(List<String> paths,
      {bool allowPartial = false}) async {
    final result = _writeResult();
    value = '1';
    return result;
  }

  @override
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    final result = _writeResult();
    value = '1';
    return result;
  }

  @override
  bool get isAuthenticated => true;

  @override
  String? get sessionToken => 'token';

  @override
  Future<void> login(String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshToken({String? token}) async {}

  @override
  Future<List<Map<String, dynamic>>> listSubscriptions() async => const [];

  @override
  void dispose() {}
}

const _leaf = 'Device.UPnP.Device.Enable';

void main() {
  late _OneLeafRouter router;
  late UspClient client;

  setUp(() {
    router = _OneLeafRouter();
    client = UspClient.withTransport(router, baseUrl: 'https://router')
      // The production cache window, so the test fails the way the bench did.
      ..throttler = BridgeRequestThrottler();
  });

  Future<Object?> read() async => (await client.get([_leaf]))[_leaf];

  group('UspClient - a write drops the GET cache', () {
    test('the premise: without a write, a second read inside 5 s is cached',
        () async {
      await read();
      await read();

      expect(router.gets, 1,
          reason: 'if this fails the cache is gone, and every other test here '
              'passes without the fix');
    });

    test('set: the read after it reaches the router (the bench sequence)',
        () async {
      expect(await read(), false);

      await client.set({_leaf: true});

      expect(await read(), true,
          reason: 'the Set landed; a re-read must not answer from before it');
      expect(router.gets, 2);
    });

    test('a single-path set drops it too', () async {
      await read();
      await client.set(_leaf, singleValue: true);

      expect(await read(), true);
    });

    test('setOrdered, add, delete and operate drop it too', () async {
      final writes = <String, Future<void> Function()>{
        'setOrdered': () => client.setOrdered([
              [
                {'path': _leaf, 'value': '1'}
              ]
            ]),
        'add': () => client.add([
              {'path': 'Device.Firewall.DMZ.', 'params': <String, dynamic>{}}
            ]),
        'delete': () => client.delete(['Device.Firewall.DMZ.1.']),
        'operate': () => client.operate('Device.Reboot()'),
      };
      for (final entry in writes.entries) {
        router.value = '0';
        client.throttler!.clearCache();
        expect(await read(), false, reason: entry.key);

        await entry.value();

        expect(await read(), true, reason: '${entry.key} must drop the cache');
      }
    });

    test('a write that throws still drops it — it may have changed the router',
        () async {
      await read();
      router
        ..value = '1'
        ..failWrites = true;

      await expectLater(client.set({_leaf: true}), throwsA(anything));

      expect(await read(), true);
    });
  });
}
