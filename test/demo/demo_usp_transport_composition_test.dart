/// Composition acceptance tests for the P3/P4 demo transport migration.
///
/// These tests exercise the FULL production path that demo mode now uses:
///
///     DemoUspTransport  →  real UspClient (via withTransport)  →  UspResultParser
///
/// This is only possible because `UspClient.withTransport` has no `!kIsWeb`
/// guard (the production `UspClient(baseUrl)` ctor does), so demo composition
/// is VM-testable for the first time. They assert that demo data flows through
/// UspClient's real coercion / wildcard back-fill and that demo's SET/ADD/
/// DELETE return the WASM-unified shape the real parser expects — i.e. the
/// behaviour the old `DemoUspClient` subclass could only approximate.
import 'package:flutter_test/flutter_test.dart';
// UspResultParser / UspOperationResult are re-exported by usp_client.dart.
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';
import 'package:privacy_gui/demo/usp/demo_usp_service.dart';

void main() {
  late UspClient client;
  final loader = DemoUspDataLoader.instance;

  setUp(() {
    // Clean the singleton store (removeByPrefix('') matches all keys).
    loader.removeByPrefix('');
    loader.setValue('Device.DeviceInfo.Manufacturer', 'Linksys');
    loader.setValue('Device.DeviceInfo.ProductClass', 'MR7500');
    loader.setValue('Device.WiFi.Radio.1.Enable', 'true');
    loader.setValue('Device.WiFi.Radio.2.Enable', 'false');
    loader.setValue('Device.WiFi.Radio.1.Channel', '36');
    loader.setValue('Device.NAT.PortMapping.1.Description', 'Web');
    loader.setValue('Device.NAT.PortMapping.1.Enable', '1');

    client = UspClient.withTransport(DemoUspTransport(loader));
  });

  group('composition: auth', () {
    test('demo transport reports always-authenticated through UspClient', () {
      expect(client.isAuthenticated, isTrue);
      expect(client.sessionToken, 'demo-session-token');
    });
  });

  group('composition: get + UspClient coercion', () {
    test('exact string path is returned as-is', () async {
      final r = await client.get(['Device.DeviceInfo.Manufacturer']);
      expect(r['Device.DeviceInfo.Manufacturer'], 'Linksys');
    });

    test('UspClient coerces "true"/"false" to bool (not demo transport)',
        () async {
      final r = await client.get([
        'Device.WiFi.Radio.1.Enable',
        'Device.WiFi.Radio.2.Enable',
      ]);
      // Coercion is done by the REAL UspClient — proves demo data flows through
      // production logic rather than demo re-implementing _coerce.
      expect(r['Device.WiFi.Radio.1.Enable'], isA<bool>());
      expect(r['Device.WiFi.Radio.1.Enable'], true);
      expect(r['Device.WiFi.Radio.2.Enable'], false);
    });

    test('"1"/"0" coerced to bool for Enable-suffixed paths', () async {
      final r = await client.get(['Device.NAT.PortMapping.1.Enable']);
      expect(r['Device.NAT.PortMapping.1.Enable'], true);
    });

    test('wildcard query expands to concrete instances', () async {
      final r = await client.get(['Device.WiFi.Radio.*.Enable']);
      expect(r.containsKey('Device.WiFi.Radio.1.Enable'), isTrue);
      expect(r.containsKey('Device.WiFi.Radio.2.Enable'), isTrue);
    });

    test('UspClient omits a missing non-wildcard path (no back-fill, #1184)',
        () async {
      final r = await client.get(['Device.DeviceInfo.DoesNotExist']);
      // #1184 removed the null back-fill: an absent concrete path is NOT added
      // to the result (it emits an onMissingPath warning instead). Back-filling
      // made containsKey() true and silently defeated the codegen 9998
      // required-leaf check, so the path must now be absent from the map.
      expect(r.containsKey('Device.DeviceInfo.DoesNotExist'), isFalse);
    });
  });

  group('composition: set → read-after-write + unified parse', () {
    test('set persists and the parser sees success', () async {
      final raw = await client.set({'Device.WiFi.Radio.1.Channel': '149'});
      final parsed = UspResultParser.parseSetResult(raw);
      expect(parsed.isCompleteSuccess, isTrue,
          reason:
              'demo SET must return the WASM-unified {success,result} shape '
              'the real parser reads via map[\'success\']');

      // Read-after-write through the same client.
      final r = await client.get(['Device.WiFi.Radio.1.Channel']);
      expect(r['Device.WiFi.Radio.1.Channel'], '149');
    });

    test('single-value set form also persists', () async {
      final raw = await client.set('Device.DeviceInfo.ProductClass',
          singleValue: 'MR9600');
      expect(UspResultParser.parseSetResult(raw).isCompleteSuccess, isTrue);
      final r = await client.get(['Device.DeviceInfo.ProductClass']);
      expect(r['Device.DeviceInfo.ProductClass'], 'MR9600');
    });
  });

  group('composition: add → parser extracts created instance', () {
    test('add creates a new instance and parser reads its path', () async {
      final raw = await client.add([
        {
          'path': 'Device.NAT.PortMapping.',
          'params': {'Description': 'SSH', 'Enable': '1'},
        }
      ]);
      final parsed = UspResultParser.parseAddResult(raw);
      expect(parsed.isCompleteSuccess, isTrue);

      // The new instance (id 2, since .1. existed) is readable.
      final r = await client.get(['Device.NAT.PortMapping.']);
      expect(r['Device.NAT.PortMapping.2.Description'], 'SSH');
    });
  });

  group('composition: delete → parser success + gone from store', () {
    test('delete removes the instance and parser sees success', () async {
      final raw = await client.delete(['Device.NAT.PortMapping.1.']);
      expect(UspResultParser.parseDeleteResult(raw).isCompleteSuccess, isTrue);

      final r = await client.get(['Device.NAT.PortMapping.']);
      expect(r.containsKey('Device.NAT.PortMapping.1.Description'), isFalse);
    });
  });

  group('composition: operate → flattened output', () {
    test('IPPing operate returns commandKey + flattened output args', () async {
      final r = await client.operate('Device.IP.Diagnostics.IPPing()',
          args: {'NumberOfRepetitions': '4'});
      // UspClient._extractOperateResult flattens the unified shape demo returns.
      expect(r['commandKey'], isNotNull);
      expect(r['Status'], 'Complete');
      expect(r['SuccessCount'], '4');
    });
  });
}
