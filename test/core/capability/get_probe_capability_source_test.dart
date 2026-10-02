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

  group('GetProbeCapabilitySource — batching', () {
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
