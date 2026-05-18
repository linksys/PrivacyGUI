import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
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

class FakePnpWifiConfig extends Fake implements PnpWifiConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePnpWifiConfig());
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

    test('error transitions to AdminError phase', () async {
      when(() => mockPnpService.checkFactoryDefault())
          .thenThrow(Exception('Network error'));

      final container = createContainer();
      final notifier = container.read(pnpProvider.notifier);

      await notifier.startPostLoginFlow();

      final state = container.read(pnpProvider);
      expect(state.phase, isA<AdminError>());
      expect((state.phase as AdminError).message, contains('Network error'));
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
}
