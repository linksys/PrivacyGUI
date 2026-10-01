import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/capability_source.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/session/services/session_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSessionService extends Mock implements SessionService {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

class MockUspClient extends Mock implements UspClient {}

/// A [CapabilitySource] that returns a fixed set — lets the lifecycle tests
/// assert login-populates / logout-clears without a live router or a real probe.
class StubCapabilitySource implements CapabilitySource {
  const StubCapabilitySource(this._result);
  final DeviceCapabilities _result;

  @override
  Future<DeviceCapabilities> resolveAll(UspClient usp) async => _result;
}

const _testDeviceInfo = NodeDeviceInfo(
  modelNumber: 'M60TB',
  firmwareVersion: '1.0.16',
  description: '',
  firmwareDate: '',
  manufacturer: 'Linksys',
  serialNumber: 'ABC123',
  hardwareVersion: '1.0',
);

const _testDeviceInfo2 = NodeDeviceInfo(
  modelNumber: 'MR7500',
  firmwareVersion: '2.0.0',
  description: '',
  firmwareDate: '',
  manufacturer: 'Linksys',
  serialNumber: 'XYZ789',
  hardwareVersion: '2.0',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSessionService mockService;
  late MockRouterFingerprintService mockFingerprint;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockSessionService();
    mockFingerprint = MockRouterFingerprintService();
    when(() => mockFingerprint.store(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sessionServiceProvider.overrideWithValue(mockService),
        routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  group('SessionNotifier — build', () {
    test('initial state has null deviceInfo', () {
      final container = createContainer();

      final state = container.read(sessionProvider);

      expect(state.deviceInfo, isNull);
      expect(state.modelNumber, '');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // checkRouterIsBack
  // ---------------------------------------------------------------------------

  group('SessionNotifier — checkRouterIsBack', () {
    test('returns device info when router matches', () async {
      when(() => mockService.checkRouterIsBack(any()))
          .thenAnswer((_) async => _testDeviceInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      final result = await notifier.checkRouterIsBack();

      expect(result.serialNumber, 'ABC123');
      container.dispose();
    });

    test('throws SerialNumberMismatchError when SN differs', () async {
      when(() => mockService.checkRouterIsBack(any()))
          .thenThrow(SerialNumberMismatchError(
        expected: 'ABC123',
        actual: 'DIFFERENT',
      ));

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      expect(
        () => notifier.checkRouterIsBack(),
        throwsA(isA<SerialNumberMismatchError>()),
      );
      container.dispose();
    });

    test('throws ConnectivityError when router is unreachable', () async {
      when(() => mockService.checkRouterIsBack(any()))
          .thenThrow(const ConnectivityError(detail: 'unreachable'));

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      expect(
        () => notifier.checkRouterIsBack(),
        throwsA(isA<ConnectivityError>()),
      );
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // checkDeviceInfo
  // ---------------------------------------------------------------------------

  group('SessionNotifier — checkDeviceInfo', () {
    test('fetches device info and updates state', () async {
      when(() => mockService.checkDeviceInfo(any()))
          .thenAnswer((_) async => _testDeviceInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      final result = await notifier.checkDeviceInfo(null);

      expect(result.modelNumber, 'M60TB');
      expect(container.read(sessionProvider).deviceInfo, _testDeviceInfo);
      container.dispose();
    });

    test('returns cached device info without fetching', () async {
      when(() => mockService.checkDeviceInfo(_testDeviceInfo))
          .thenAnswer((_) async => _testDeviceInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      // First fetch to populate state
      when(() => mockService.checkDeviceInfo(null))
          .thenAnswer((_) async => _testDeviceInfo);
      await notifier.checkDeviceInfo(null);

      // Second call with cached info
      final result = await notifier.checkDeviceInfo('ABC123');
      expect(result.modelNumber, 'M60TB');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // forceFetchDeviceInfo
  // ---------------------------------------------------------------------------

  group('SessionNotifier — forceFetchDeviceInfo', () {
    test('fetches fresh device info and updates state', () async {
      when(() => mockService.forceFetchDeviceInfo())
          .thenAnswer((_) async => _testDeviceInfo2);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      final result = await notifier.forceFetchDeviceInfo();

      expect(result.modelNumber, 'MR7500');
      expect(container.read(sessionProvider).modelNumber, 'MR7500');
      container.dispose();
    });

    test('throws on API failure', () async {
      when(() => mockService.forceFetchDeviceInfo())
          .thenThrow(const ConnectivityError(detail: 'timeout'));

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      expect(
        () => notifier.forceFetchDeviceInfo(),
        throwsA(isA<ConnectivityError>()),
      );
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // fetchDeviceInfoAndInitializeServices
  // ---------------------------------------------------------------------------

  group('SessionNotifier — fetchDeviceInfoAndInitializeServices', () {
    test('fetches device info and stores fingerprint', () async {
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenAnswer((_) async => _testDeviceInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      final result = await notifier.fetchDeviceInfoAndInitializeServices();

      expect(result.serialNumber, 'ABC123');
      expect(container.read(sessionProvider).deviceInfo, _testDeviceInfo);
      verify(() => mockFingerprint.store('ABC123')).called(1);
      container.dispose();
    });

    test('does not store fingerprint when serial is empty', () async {
      const emptySerialInfo = NodeDeviceInfo(
        modelNumber: 'M60TB',
        firmwareVersion: '1.0.16',
        description: '',
        firmwareDate: '',
        manufacturer: 'Linksys',
        serialNumber: '',
        hardwareVersion: '1.0',
      );
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenAnswer((_) async => emptySerialInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      await notifier.fetchDeviceInfoAndInitializeServices();

      verifyNever(() => mockFingerprint.store(any()));
      container.dispose();
    });

    test('throws on service failure', () async {
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenThrow(const ConnectivityError(detail: 'network down'));

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      expect(
        () => notifier.fetchDeviceInfoAndInitializeServices(),
        throwsA(isA<ConnectivityError>()),
      );
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // saveSelectedNetwork
  // ---------------------------------------------------------------------------

  group('SessionNotifier — saveSelectedNetwork', () {
    test('persists SN and networkId and updates provider state', () async {
      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      await notifier.saveSelectedNetwork('ABC123', 'net-001');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('LinksysCurrentSN'), 'ABC123');
      expect(prefs.getString('LinksysSelectedNetworkId'), 'net-001');
      expect(container.read(selectedNetworkIdProvider), 'net-001');
      container.dispose();
    });

    test('handles empty networkId for local sessions', () async {
      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      await notifier.saveSelectedNetwork('ABC123', '');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('LinksysCurrentSN'), 'ABC123');
      expect(prefs.getString('LinksysSelectedNetworkId'), '');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // clear
  // ---------------------------------------------------------------------------

  group('SessionNotifier — clear', () {
    test('resets state to empty', () async {
      when(() => mockService.forceFetchDeviceInfo())
          .thenAnswer((_) async => _testDeviceInfo);

      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      // Populate state
      await notifier.forceFetchDeviceInfo();
      expect(container.read(sessionProvider).deviceInfo, isNotNull);

      // Clear
      notifier.clear();

      expect(container.read(sessionProvider).deviceInfo, isNull);
      expect(container.read(sessionProvider).modelNumber, '');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // capabilities lifecycle (#1635)
  // ---------------------------------------------------------------------------

  group('SessionNotifier — capabilities', () {
    /// Container whose USP client is non-null and whose capability source is a
    /// stub — so `_resolveCapabilities` runs (it early-returns on a null client)
    /// and returns a known set.
    ProviderContainer createContainerWithCapabilities(
        DeviceCapabilities resolved) {
      return ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
          uspClientProvider.overrideWithValue(MockUspClient()),
          capabilitySourceProvider
              .overrideWithValue(StubCapabilitySource(resolved)),
        ],
      );
    }

    test('initial state is empty (fail-closed before login)', () {
      final container = createContainer();

      expect(container.read(sessionProvider).capabilities,
          DeviceCapabilities.empty);
      container.dispose();
    });

    test('login resolves capabilities into session state', () async {
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenAnswer((_) async => _testDeviceInfo);
      final resolved =
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter});

      final container = createContainerWithCapabilities(resolved);
      final notifier = container.read(sessionProvider.notifier);

      await notifier.fetchDeviceInfoAndInitializeServices();

      expect(
          container
              .read(sessionProvider)
              .capabilities
              .has(DeviceCapability.wifiMacFilter),
          isTrue);
      expect(
          container
              .read(deviceCapabilitiesProvider)
              .has(DeviceCapability.wifiMacFilter),
          isTrue);
      container.dispose();
    });

    test('logout (clear) empties resolved capabilities', () async {
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenAnswer((_) async => _testDeviceInfo);
      final resolved =
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter});

      final container = createContainerWithCapabilities(resolved);
      final notifier = container.read(sessionProvider.notifier);

      await notifier.fetchDeviceInfoAndInitializeServices();
      expect(
          container
              .read(sessionProvider)
              .capabilities
              .has(DeviceCapability.wifiMacFilter),
          isTrue);

      notifier.clear();

      expect(container.read(sessionProvider).capabilities,
          DeviceCapabilities.empty);
      container.dispose();
    });

    test('login does not resolve when USP client is null (stays empty)',
        () async {
      when(() => mockService.fetchDeviceInfoAndInitializeServices())
          .thenAnswer((_) async => _testDeviceInfo);

      // Default container: uspClientProvider is null → _resolveCapabilities
      // early-returns, capabilities stay empty, login still succeeds.
      final container = createContainer();
      final notifier = container.read(sessionProvider.notifier);

      await notifier.fetchDeviceInfoAndInitializeServices();

      expect(container.read(sessionProvider).deviceInfo, isNotNull);
      expect(container.read(sessionProvider).capabilities,
          DeviceCapabilities.empty);
      container.dispose();
    });
  });
}
