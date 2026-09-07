import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUspClient extends Mock implements UspClient {}

class MockPnpService extends Mock implements PnpService {}

class MockPnpStatusService extends Mock implements PnpStatusService {}

class MockSessionNotifier extends Mock implements SessionNotifier {}

/// Mountable session notifier that records [saveSelectedNetwork] calls.
///
/// A plain mocktail mock cannot be mounted by Riverpod (it lacks the internal
/// `_setElement` hook), so tests that actually invoke `sessionProvider.notifier`
/// use this spy instead of [MockSessionNotifier].
class SpySessionNotifier extends Notifier<SessionState>
    implements SessionNotifier {
  final List<({String sn, String networkId})> savedNetworks = [];

  @override
  SessionState build() => const SessionState();

  @override
  Future<void> saveSelectedNetwork(String sn, String networkId) async {
    savedNetworks.add((sn: sn, networkId: networkId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePnpWifiConfig extends Fake implements PnpWifiConfig {}

class FakePnpIspConfig extends Fake implements PnpIspConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePnpWifiConfig());
    registerFallbackValue(FakePnpIspConfig());
  });
  late MockUspClient mockUsp;
  late MockPnpService mockPnpService;
  late MockPnpStatusService mockPnpStatusService;
  late MockSessionNotifier mockSessionNotifier;

  const testFactoryResult = FactoryDefaultCheckResult(
    isFactoryDefault: false,
    serialNumber: 'SN123',
    modelName: 'M60TB',
  );

  const testWifiConfig = PnpWifiConfig(
    ssid: 'TestSSID',
    password: 'TestPass123',
    originalSsid: 'TestSSID',
    originalPassword: 'TestPass123',
    ssidInstancePaths: ['Device.WiFi.SSID.1.'],
    accessPointInstancePaths: ['Device.WiFi.AccessPoint.1.'],
  );

  final testWizardResult = PnpWizardFetchResult(wifiConfig: testWifiConfig);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUsp = MockUspClient();
    mockPnpService = MockPnpService();
    mockPnpStatusService = MockPnpStatusService();
    mockSessionNotifier = MockSessionNotifier();

    when(() => mockUsp.isAuthenticated).thenReturn(true);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        pnpServiceProvider.overrideWithValue(mockPnpService),
        pnpStatusServiceProvider.overrideWithValue(mockPnpStatusService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        sessionProvider.overrideWith(() => mockSessionNotifier),
      ],
    );
  }

  group('PnpNotifier — startPostLoginFlow', () {
    test('initial state is AdminCheckingInternet', () {
      final container = createContainer();

      final state = container.read(pnpProvider);

      expect(state.phase, isA<AdminCheckingInternet>());
      container.dispose();
    });

    test('successful flow transitions to WizardConfiguring', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();
      await Future.delayed(Duration.zero);

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardConfiguring>());
      expect(state.serialNumber, 'SN123');
      expect(state.modelName, 'M60TB');
      container.dispose();
    });

    test('no internet transitions to NoInternet phase', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => false);
      when(() => mockPnpService.fetchCurrentSsid())
          .thenAnswer((_) async => 'CurrentSSID');

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();

      final state = container.read(pnpProvider);
      expect(state.phase, isA<NoInternet>());
      expect((state.phase as NoInternet).ssid, 'CurrentSSID');
      container.dispose();
    });

    test('device info read failure transitions to AdminReadFailure phase',
        () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenThrow(const NetworkError(detail: 'Network error'));

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();

      final state = container.read(pnpProvider);
      expect(state.phase, isA<AdminReadFailure>());
      expect(
          (state.phase as AdminReadFailure).detail, contains('Network error'));
      container.dispose();
    });

    // Regression for #1098: a WAN read FAILURE (USP GET returned empty →
    // WanStatus.fetch throws) must NOT collapse into NoInternet. That state is
    // reserved for the router *confirming* no internet (returns false, no throw).
    test('WAN read failure transitions to AdminReadFailure, not NoInternet',
        () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenThrow(const InvalidInputError(code: 9998, detail: 'missing'));

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();

      final state = container.read(pnpProvider);
      expect(state.phase, isA<AdminReadFailure>());
      expect((state.phase as AdminReadFailure).code, 9998);
      container.dispose();
    });
  });

  group('PnpNotifier — WiFi form updates', () {
    test('updateWifiSsid updates ssid in WizardConfiguring', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();
      notifier.updateWifiSsid('NewSSID');

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardConfiguring>());
      final config = (state.phase as WizardConfiguring).wifiConfig;
      expect(config.ssid, 'NewSSID');
      expect(config.isSsidChanged, isTrue);
      container.dispose();
    });

    test('updateWifiPassword updates password in WizardConfiguring', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();
      notifier.updateWifiPassword('NewPassword');

      final state = container.read(pnpProvider);
      final config = (state.phase as WizardConfiguring).wifiConfig;
      expect(config.password, 'NewPassword');
      expect(config.isPasswordChanged, isTrue);
      container.dispose();
    });
  });

  // Note: saveChanges tests require complex SessionNotifier mocking.
  // The core logic is tested via integration tests.
  // Here we test the acknowledge call is made correctly via PnpStatusService unit tests.;

  group('PnpNotifier — retryInternetCheck', () {
    test('retryInternetCheck re-checks internet and transitions accordingly',
        () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      // Manually set to NoInternet phase
      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      await notifier.retryInternetCheck();

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardConfiguring>());
      container.dispose();
    });
  });

  group('PnpNotifier — bypassToDashboard', () {
    test('acknowledges PnP and saves selected network when SN is present',
        () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => false);
      when(() => mockPnpService.fetchCurrentSsid())
          .thenAnswer((_) async => 'Test');
      when(() => mockPnpStatusService.acknowledge(any()))
          .thenAnswer((_) async {});

      // Use the mountable spy so sessionProvider.notifier can be read.
      final spySession = SpySessionNotifier();
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          pnpServiceProvider.overrideWithValue(mockPnpService),
          pnpStatusServiceProvider.overrideWithValue(mockPnpStatusService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sessionProvider.overrideWith(() => spySession),
        ],
      );
      final notifier = container.read(pnpProvider.notifier);

      // Populate serialNumber via the normal entry flow (lands on NoInternet).
      await notifier.startPostLoginFlow();
      expect(container.read(pnpProvider).phase, isA<NoInternet>());

      await notifier.bypassToDashboard();

      verify(() => mockPnpStatusService.acknowledge('SN123')).called(1);
      expect(spySession.savedNetworks, [(sn: 'SN123', networkId: '')]);
      container.dispose();
    });

    test('skips acknowledge when serial number is missing', () async {
      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      // No startPostLoginFlow → serialNumber stays null.
      await notifier.bypassToDashboard();

      verifyNever(() => mockPnpStatusService.acknowledge(any()));
      container.dispose();
    });

    // The escape hatch must never throw — a failed acknowledge/save must not
    // trap the user on the no-internet page. The view navigates regardless.
    test('does not throw when acknowledge fails', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenAnswer((_) async => testFactoryResult);
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => false);
      when(() => mockPnpService.fetchCurrentSsid())
          .thenAnswer((_) async => 'Test');
      when(() => mockPnpStatusService.acknowledge(any()))
          .thenThrow(Exception('TR-181 write failed'));

      final spySession = SpySessionNotifier();
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          pnpServiceProvider.overrideWithValue(mockPnpService),
          pnpStatusServiceProvider.overrideWithValue(mockPnpStatusService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sessionProvider.overrideWith(() => spySession),
        ],
      );
      final notifier = container.read(pnpProvider.notifier);
      await notifier.startPostLoginFlow();

      // Must complete normally (no throw) despite acknowledge failing.
      await expectLater(notifier.bypassToDashboard(), completes);
      container.dispose();
    });
  });

  group('PnpNotifier — saveIspWithProgress', () {
    test(
        'successful ISP save transitions through IspSaving then checks internet',
        () async {
      when(() => mockPnpService.saveIspSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.50',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockPnpService.saveIspSettings(any())).called(1);
      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardConfiguring>());
      container.dispose();
    });

    test('ISP save failure transitions back to NoInternet with error',
        () async {
      when(() => mockPnpService.saveIspSettings(any()))
          .thenThrow(Exception('WAN save failed'));

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );

      await notifier.saveIspWithProgress(config);

      final state = container.read(pnpProvider);
      expect(state.phase, isA<NoInternet>());
      expect(state.errorMessage, contains('WAN save failed'));
      container.dispose();
    });

    test('DHCP ISP save calls saveIspSettings with dhcp type', () async {
      when(() => mockPnpService.saveIspSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => true);
      when(() => mockPnpService.fetchWizardData())
          .thenAnswer((_) async => testWizardResult);
      when(() => mockPnpService.fetchMeshTopology())
          .thenAnswer((_) async => MeshTopologyInfo.empty);

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      const config = PnpIspConfig(type: IspConnectionType.dhcp);

      await notifier.saveIspWithProgress(config);

      verify(() => mockPnpService.saveIspSettings(any())).called(1);
      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardConfiguring>());
      container.dispose();
    });

    test('ISP save success but no internet transitions to NoInternet',
        () async {
      when(() => mockPnpService.saveIspSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockPnpService.checkInternetConnected())
          .thenAnswer((_) async => false);
      when(() => mockPnpService.fetchCurrentSsid())
          .thenAnswer((_) async => 'MyWiFi');

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '10.0.0.5',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.1',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockPnpService.saveIspSettings(any())).called(1);
      final state = container.read(pnpProvider);
      expect(state.phase, isA<NoInternet>());
      container.dispose();
    });

    // Regression for #1098: the ISP save WRITE succeeds, but the trailing
    // internet check READ fails (USP GET returned empty). This must land in
    // AdminReadFailure (read failure), NOT NoInternet — distinct from a genuine
    // no-internet (checkInternetConnected returns false) and from a save write
    // failure (which stays on NoInternet + errorMessage, tested above).
    test('ISP save success but check read failure → AdminReadFailure',
        () async {
      when(() => mockPnpService.saveIspSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockPnpService.checkInternetConnected())
          .thenThrow(const InvalidInputError(code: 9998, detail: 'missing'));

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      notifier.setDemoPhase(const NoInternet(ssid: 'Test'));

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '10.0.0.5',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.1',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockPnpService.saveIspSettings(any())).called(1);
      final state = container.read(pnpProvider);
      expect(state.phase, isA<AdminReadFailure>());
      expect((state.phase as AdminReadFailure).code, 9998);
      container.dispose();
    });
  });
}
