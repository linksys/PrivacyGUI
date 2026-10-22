import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
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

    test('no interface with Alias wan is "no such instance", not a guess',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {
                'Device.IP.Interface.1.Alias': 'lan',
                'Device.IP.Interface.2.Alias': 'guest',
              });
      await expectLater(
        resolveWanInterfacePath(mockUsp),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });

    test('a failed query surfaces as a ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error: Connection refused');
      await expectLater(
        resolveWanInterfacePath(mockUsp),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // wanInterfacePathProvider
  // ---------------------------------------------------------------------------
  group('wanInterfacePathProvider', () {
    test('null client → no WAN path', () async {
      final container = ProviderContainer(
        overrides: [uspClientProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(wanInterfacePathProvider.future), isNull);
    });

    test('a router with no WAN interface → no WAN path', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {'Device.IP.Interface.1.Alias': 'lan'});
      final container = ProviderContainer(
        overrides: [uspClientProvider.overrideWithValue(mockUsp)],
      );
      addTearDown(container.dispose);

      expect(await container.read(wanInterfacePathProvider.future), isNull);
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

  // ---------------------------------------------------------------------------
  // retryWanInterfacePathIfUnresolved
  // ---------------------------------------------------------------------------
  group('retryWanInterfacePathIfUnresolved', () {
    /// A container whose provider reads go through [mockUsp], with the retry
    /// interval set to [interval].
    ProviderContainer containerWith({Duration interval = Duration.zero}) {
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        wanInterfacePathRetryIntervalProvider.overrideWithValue(interval),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    /// Runs the retry against [container] the way a caller with a `Ref` does.
    void retry(ProviderContainer container) => container.read(
        Provider((ref) => () => retryWanInterfacePathIfUnresolved(ref)))();

    int aliasReads() =>
        verify(() => mockUsp.get(any(), priority: any(named: 'priority')))
            .callCount;

    test('a resolved WAN path is never re-read', () async {
      // The SSE-healthy case: a refresh must not touch a path that works.
      stubAliasResolvesWanTo(5);
      final container = containerWith();
      expect(await container.read(wanInterfacePathProvider.future),
          'Device.IP.Interface.5.');
      expect(aliasReads(), 1);

      retry(container);
      retry(container);

      expect(await container.read(wanInterfacePathProvider.future),
          'Device.IP.Interface.5.');
      verifyNever(() => mockUsp.get(any(), priority: any(named: 'priority')));
    });

    test('an unresolved WAN path is re-read and recovers', () async {
      var wanUp = false;
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async {
        if (!wanUp) throw 'Get failed: Transport error: Connection refused';
        return {'Device.IP.Interface.5.Alias': 'wan'};
      });
      final container = containerWith();
      expect(await container.read(wanInterfacePathProvider.future), isNull);
      expect(aliasReads(), 1, reason: 'the first, failed resolve');

      wanUp = true;
      retry(container);
      // The retry starts the read itself: nothing else reads the provider, so
      // a retry that only marked it stale would read nothing.
      expect(aliasReads(), 1, reason: 'one more alias read, from the retry');

      expect(container.read(wanInterfacePathProvider).isLoading, isTrue);
      await Future.delayed(Duration.zero);
      expect(container.read(wanInterfacePathProvider).valueOrNull,
          'Device.IP.Interface.5.');
    });

    test('retries of an unresolved path are spaced by the interval', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {'Device.IP.Interface.3.Alias': 'lan'});
      final container = containerWith(interval: const Duration(minutes: 5));
      expect(await container.read(wanInterfacePathProvider.future), isNull);
      expect(aliasReads(), 1);

      retry(container);
      await container.read(wanInterfacePathProvider.future);
      // `callCount` counts calls since the last verify: one more read.
      expect(aliasReads(), 1, reason: 'the first retry runs');

      retry(container);
      retry(container);
      await container.read(wanInterfacePathProvider.future);
      verifyNever(() => mockUsp.get(any(), priority: any(named: 'priority')));
    });

    test('a new router is retried without waiting for the old one\'s interval',
        () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) async => {'Device.IP.Interface.3.Alias': 'lan'});
      final fakeSession = FakeSessionNotifier(_sessionWithSerial('ROUTER-A'));
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        sessionProvider.overrideWith(() => fakeSession),
        wanInterfacePathRetryIntervalProvider
            .overrideWithValue(const Duration(minutes: 5)),
      ]);
      addTearDown(container.dispose);
      expect(await container.read(wanInterfacePathProvider.future), isNull);
      retry(container);
      await container.read(wanInterfacePathProvider.future);
      expect(aliasReads(), 2, reason: 'router A: first resolve and one retry');

      // Router B: its first resolve fails too; its retry must not wait for
      // the interval router A's retry started.
      fakeSession.setSerialNumber('ROUTER-B');
      expect(await container.read(wanInterfacePathProvider.future), isNull);
      expect(aliasReads(), 1, reason: "router B's first resolve");
      retry(container);
      await container.read(wanInterfacePathProvider.future);

      expect(aliasReads(), 1, reason: "router B's retry");
    });

    test('a resolve still in flight is left alone', () async {
      final pending = Completer<Map<String, dynamic>>();
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((_) => pending.future);
      final container = containerWith();
      final first = container.read(wanInterfacePathProvider.future);

      retry(container);

      pending.complete({'Device.IP.Interface.5.Alias': 'wan'});
      expect(await first, 'Device.IP.Interface.5.');
      expect(aliasReads(), 1);
    });
  });
}
