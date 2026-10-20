import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_resolver.dart';
import 'package:privacy_gui/core/capability/capability_source.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient usp;
  const source = GetProbeCapabilitySource();
  final macFilterPath = capabilityProbePath(DeviceCapability.wifiMacFilter);

  setUp(() {
    usp = MockUspClient();
  });

  group('GetProbeCapabilitySource — fail closed', () {
    test('present, non-empty value → supported', () async {
      when(() => usp.get(any()))
          .thenAnswer((_) async => {macFilterPath: 'Disabled'});

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isTrue);
    });

    test('key absent from response (silently omitted) → unsupported', () async {
      // The firmware answered the Get but did not include the path — the
      // `usp_transport` contract: missing paths are simply absent.
      when(() => usp.get(any())).thenAnswer((_) async => <String, dynamic>{});

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isFalse);
    });

    test('present but empty string → unsupported', () async {
      when(() => usp.get(any())).thenAnswer((_) async => {macFilterPath: ''});

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isFalse);
    });

    test('get throws ResourceNotFoundError (path faulted) → unsupported',
        () async {
      when(() => usp.get(any())).thenThrow(
          const ResourceNotFoundError(code: 7026, detail: 'path 404'));

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isFalse);
    });

    test('get throws some other ServiceError → unsupported', () async {
      when(() => usp.get(any()))
          .thenThrow(const ConnectivityError(detail: 'boom'));

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isFalse);
    });

    test('get throws a non-ServiceError → unsupported (never rethrows)',
        () async {
      when(() => usp.get(any())).thenThrow(Exception('unexpected'));

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMacFilter), isFalse);
    });

    test('a throwing probe resolves to empty, not a thrown error', () async {
      when(() => usp.get(any())).thenThrow(Exception('boom'));

      final caps = await source.resolveAll(usp);

      expect(caps, DeviceCapabilities.empty);
    });
  });

  group('GetProbeCapabilitySource — Auto-IPoE', () {
    const autoIPoEPath = 'Device.X_LINKSYS_AutoIPoE.APIVersion';

    test('nonempty APIVersion enables Auto-IPoE and preserves other support',
        () async {
      expect(capabilityProbePath(DeviceCapability.autoIPoE), autoIPoEPath);
      when(() => usp.get(any())).thenAnswer((_) async => {
            autoIPoEPath: '1',
            macFilterPath: 'Disabled',
          });

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.autoIPoE), isTrue);
      expect(caps.has(DeviceCapability.wifiMacFilter), isTrue);
    });

    for (final response in <String, Map<String, dynamic>>{
      'absent': {},
      'empty': {autoIPoEPath: ''},
      'whitespace': {autoIPoEPath: '   '},
      'null': {autoIPoEPath: null},
    }.entries) {
      test('${response.key} APIVersion leaves other capabilities intact',
          () async {
        when(() => usp.get(any())).thenAnswer((_) async => {
              ...response.value,
              macFilterPath: 'Disabled',
            });

        final caps = await source.resolveAll(usp);

        expect(caps.has(DeviceCapability.autoIPoE), isFalse);
        expect(caps.has(DeviceCapability.wifiMacFilter), isTrue);
      });
    }
  });

  group('GetProbeCapabilitySource — MLO (#1692)', () {
    const mloPath = 'Device.X_LINKSYS_Mesh.MLOStatus';

    test('a status read off the router means MLO is offered', () async {
      expect(capabilityProbePath(DeviceCapability.wifiMlo), mloPath);
      // What FW 2.0.3.26101472 reads with the switch off (bench 2026-10-15).
      when(() => usp.get(any())).thenAnswer((_) async => {
            mloPath: 'Disabled',
            macFilterPath: 'Disabled',
          });

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMlo), isTrue);
      expect(caps.has(DeviceCapability.wifiMacFilter), isTrue);
    });

    test('firmware without the leaf hides MLO and nothing else', () async {
      // A GET naming a path missing from the schema answers the other paths
      // and leaves that one out (bench 2026-10-13, 7026 per path).
      when(() => usp.get(any())).thenAnswer((_) async => {
            macFilterPath: 'Disabled',
          });

      final caps = await source.resolveAll(usp);

      expect(caps.has(DeviceCapability.wifiMlo), isFalse);
      expect(caps.has(DeviceCapability.wifiMacFilter), isTrue);
    });
  });

  group('GetProbeCapabilitySource — batching', () {
    for (final failure in <String, Object>{
      'unknown path': const ResourceNotFoundError(code: 7026),
      'expired session': const SessionTokenExpiredError(),
      'network failure': const ConnectivityError(),
      'unexpected error': Exception('unexpected'),
    }.entries) {
      test('${failure.key} fails closed without individual retries', () async {
        when(() => usp.get(any())).thenThrow(failure.value);

        final caps = await source.resolveAll(usp);

        expect(caps, DeviceCapabilities.empty);
        final requests =
            verify(() => usp.get(captureAny())).captured.cast<List<String>>();
        expect(requests, [
          [
            for (final capability in DeviceCapability.values)
              capabilityProbePath(capability)
          ],
        ]);
        verifyNoMoreInteractions(usp);
      });
    }

    test('probes every declared capability path in one Get', () async {
      when(() => usp.get(any())).thenAnswer((_) async => <String, dynamic>{});

      await source.resolveAll(usp);

      final captured =
          verify(() => usp.get(captureAny())).captured.single as List<String>;
      for (final c in DeviceCapability.values) {
        expect(captured, contains(capabilityProbePath(c)));
      }
    });
  });
}
