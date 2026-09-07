import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/wan_interface_path_provider.dart';

import '../mocks.dart';

SessionState _sessionWithSerial(String? serialNumber) {
  if (serialNumber == null) return const SessionState();
  return SessionState(
    deviceInfo: NodeDeviceInfo(
      modelNumber: 'M60',
      firmwareVersion: '1.0.0',
      description: '',
      firmwareDate: '',
      manufacturer: 'Linksys',
      serialNumber: serialNumber,
      hardwareVersion: '1',
    ),
  );
}

/// Mountable session notifier whose state can be mutated by tests to simulate
/// switching to a different router (serial number change) or logout. Extends
/// the real [SessionNotifier] so all concrete methods are inherited; only
/// [build] and a test-only mutator are provided.
class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;

  void setSerialNumber(String? serialNumber) {
    state = _sessionWithSerial(serialNumber);
  }

  /// Replaces device info keeping the same serial but a different model, to
  /// prove non-serial field changes do not re-trigger resolution.
  void setModelKeepingSerial(String serialNumber, String modelNumber) {
    state = SessionState(
      deviceInfo: NodeDeviceInfo(
        modelNumber: modelNumber,
        firmwareVersion: '1.0.0',
        description: '',
        firmwareDate: '',
        manufacturer: 'Linksys',
        serialNumber: serialNumber,
        hardwareVersion: '1',
      ),
    );
  }
}

void main() {
  late MockUspClient mockUsp;

  setUp(() {
    mockUsp = MockUspClient();
  });

  /// Stubs the `Device.IP.Interface.*.Alias` query so the interface at
  /// [wanInstance] carries Alias 'wan'.
  void stubAliasResolvesWanTo(int wanInstance) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async => {
              'Device.IP.Interface.1.Alias': 'lan',
              'Device.IP.Interface.$wanInstance.Alias': 'wan',
            });
  }

  // ---------------------------------------------------------------------------
  // resolveWanInterfacePath (pure function)
  // ---------------------------------------------------------------------------
  group('resolveWanInterfacePath', () {
    test('returns the instance whose Alias is wan', () async {
      stubAliasResolvesWanTo(4);
      expect(
        await resolveWanInterfacePath(mockUsp),
        'Device.IP.Interface.4.',
      );
    });

    test('falls back when no interface has Alias wan', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.IP.Interface.1.Alias': 'lan',
                'Device.IP.Interface.2.Alias': 'guest',
              });
      expect(
        await resolveWanInterfacePath(mockUsp),
        kWanInterfaceFallbackPath,
      );
    });

    test('falls back when the query throws', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow(Exception('transport down'));
      expect(
        await resolveWanInterfacePath(mockUsp),
        kWanInterfaceFallbackPath,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // wanInterfacePathProvider
  // ---------------------------------------------------------------------------
  group('wanInterfacePathProvider', () {
    test('null client → fallback path', () async {
      final container = ProviderContainer(
        overrides: [uspClientProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(wanInterfacePathProvider.future),
        kWanInterfaceFallbackPath,
      );
    });

    test('resolves via the client on first read', () async {
      stubAliasResolvesWanTo(4);
      final container = ProviderContainer(
        overrides: [uspClientProvider.overrideWithValue(mockUsp)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(wanInterfacePathProvider.future),
        'Device.IP.Interface.4.',
      );
    });

    test('re-resolves when the connected router (serial) changes', () async {
      // Router A resolves WAN to Interface.2; router B to Interface.4.
      var currentWanInstance = 2;
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.IP.Interface.1.Alias': 'lan',
                'Device.IP.Interface.$currentWanInstance.Alias': 'wan',
              });

      final fakeSession = FakeSessionNotifier(_sessionWithSerial('ROUTER-A'));
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          sessionProvider.overrideWith(() => fakeSession),
        ],
      );
      addTearDown(container.dispose);

      // Router A.
      expect(
        await container.read(wanInterfacePathProvider.future),
        'Device.IP.Interface.2.',
      );

      // Switch to router B (different serial) whose WAN is on Interface.4.
      currentWanInstance = 4;
      fakeSession.setSerialNumber('ROUTER-B');

      expect(
        await container.read(wanInterfacePathProvider.future),
        'Device.IP.Interface.4.',
      );
    });

    test('does NOT re-resolve when a non-serial device-info field changes',
        () async {
      stubAliasResolvesWanTo(2);
      final fakeSession = FakeSessionNotifier(_sessionWithSerial('ROUTER-A'));
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          sessionProvider.overrideWith(() => fakeSession),
        ],
      );
      addTearDown(container.dispose);

      await container.read(wanInterfacePathProvider.future);
      // One resolve so far.
      verify(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .called(1);

      // Same serial, different model → select() narrows the dependency to the
      // serial, so no rebuild and no second resolve.
      fakeSession.setModelKeepingSerial('ROUTER-A', 'M70');
      await container.read(wanInterfacePathProvider.future);
      verifyNever(() => mockUsp.get(any(), priority: any(named: 'priority')));
    });
  });
}
