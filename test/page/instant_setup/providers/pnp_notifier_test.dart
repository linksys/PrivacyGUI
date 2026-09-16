import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/provider_overrides/mock_firmware_update.dart';

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

// ─── Firmware stage doubles (#1553) ──────────────────────────────────────────

/// A [FirmwareUpdateNotifier] that answers instead of asking the router.
///
/// Not `FixedFirmwareUpdateNotifier` from `mock_firmware_update.dart`: that one
/// pins one state and hard-codes `abandoned` for both the check and the install,
/// which is the single outcome REQ-B1 does *not* need — every branch here is a
/// different verdict, and two of them have to throw.
class SpyFirmwareUpdateNotifier extends FirmwareUpdateNotifier {
  SpyFirmwareUpdateNotifier({
    this.checkResult = const FirmwareOtaCheckResult.noUpdateFound(),
    this.checkError,
    this.checkDelay,
    this.installResult = const FirmwareOtaInstallResult(
      verdict: FirmwareOtaInstallVerdict.flashing,
    ),
    this.installLeavesPhase = FirmwareUpdatePhase.installing,
    this.cancelError,
    this.readsBanksOnCheck = true,
    this.onEnterRecovery,
  });

  final FirmwareOtaCheckResult checkResult;
  final Object? checkError;
  final Duration? checkDelay;
  final FirmwareOtaInstallResult installResult;

  /// The phase the install leaves behind, which is what the stage's cleanup has to
  /// deal with. `installing` on the happy path; `failed` is the state the real
  /// notifier reaches on `fwup_state=5`, and the one `isUpdating` cannot see.
  final FirmwareUpdatePhase installLeavesPhase;

  /// Thrown from [cancel], to reach the cleanup path from outside the stage.
  final Object? cancelError;
  final bool readsBanksOnCheck;
  final void Function()? onEnterRecovery;

  int checkCalls = 0;
  int recoveryCalls = 0;
  int cancelCalls = 0;
  final List<int> installedOtaInstances = [];

  @override
  FirmwareUpdateState build() => const FirmwareUpdateState();

  @override
  Future<void> loadBanks({bool refresh = false}) async {}

  @override
  Future<FirmwareOtaCheckResult> checkForUpdate() async {
    checkCalls++;
    // The real method awaits the L1 banks future before it answers anything, and
    // `_runFirmwareStage` reads that same provider *synchronously* afterwards. A
    // spy that skipped the await would leave it `AsyncLoading` and so test an
    // ordering production never has.
    if (readsBanksOnCheck) await ref.read(firmwareBanksDataProvider.future);
    if (checkDelay != null) await Future<void>.delayed(checkDelay!);
    if (checkError != null) throw checkError!;
    return checkResult;
  }

  @override
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async {
    installedOtaInstances.add(otaInstance);
    // The real one leaves the phase set, which is what the stage's `finally` has
    // to undo — pinned by [cancelCalls].
    state = state.copyWith(phase: installLeavesPhase);
    return installResult;
  }

  @override
  void enterRecoveryWaiting({Duration cooldown = const Duration(seconds: 60)}) {
    recoveryCalls++;
    onEnterRecovery?.call();
  }

  @override
  void cancel() {
    cancelCalls++;
    if (cancelError != null) throw cancelError!;
    super.cancel();
  }
}

/// The connection state, settable, without the real notifier's `build`.
///
/// [AppConnectionStateNotifier.build] wires an SSE manager and two listeners, so
/// the real one cannot be mounted in a plain `ProviderContainer` — and what the
/// firmware stage needs from it is exactly one thing: that the value it publishes
/// can be moved out of `waitingForRecovery` from the test.
class SpyAppConnectionStateNotifier extends Notifier<AppConnectionState>
    implements AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.authenticated;

  void publish(AppConnectionState next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A banks provider that read fine once and then failed, for the
/// `hasError`-before-`valueOrNull` guard.
///
/// A notifier whose `build` simply throws would **not** pin that guard: with no
/// previous value, `valueOrNull` is null anyway and the two orders agree. The
/// order only decides anything in the state `FirmwareBanksDataNotifier.refresh()`
/// actually produces — `AsyncError` with the last good value still attached —
/// which is what [failWhileKeepingValue] reproduces.
class StaleFirmwareBanksDataNotifier extends FirmwareBanksDataNotifier {
  @override
  Future<FirmwareBanksData> build() async => gateFirmwareBanksWithOta;

  void failWhileKeepingValue() {
    state = AsyncError<FirmwareBanksData>(
      const NetworkError(detail: 'banks refresh failed'),
      StackTrace.current,
    ).copyWithPrevious(state);
  }
}

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

  // ─── Firmware stage (#1553) ────────────────────────────────────────────────

  /// The stage that replaced the `TODO: Integrate FirmwareImages.fetch(usp)` stub.
  ///
  /// Driven through `saveChanges()` rather than by calling the private method,
  /// because REQ-B0's claim is about *where* the stage sits: after the write has
  /// been committed, as a flow phase rather than a fourth form step. Entering it
  /// any other way would assert nothing about that.
  ///
  /// Every case below ends in [WizardWifiReady] — that is REQ-B3, and it is why
  /// each one asserts the phase as well as the thing it is really about: a branch
  /// that reached the right verdict and then stranded the wizard would be a
  /// regression this feature exists to prevent.
  group('PnpNotifier — firmware stage (#1553)', () {
    late SpyAppConnectionStateNotifier connection;

    /// Saved with the main WiFi untouched, so `saveChanges()` takes the arm that
    /// goes straight to the firmware stage. The reconnect arm is the other entry
    /// point and has its own case; driving it here would mean five real
    /// `Future.delayed` backoffs — up to 62 seconds — per test.
    const savedConfig = PnpWifiConfig(
      ssid: 'ConfiguredSSID',
      password: 'ConfiguredPass123',
      originalSsid: 'ConfiguredSSID',
      originalPassword: 'ConfiguredPass123',
      ssidInstancePaths: ['Device.WiFi.SSID.1.'],
      accessPointInstancePaths: ['Device.WiFi.AccessPoint.1.'],
    );

    setUp(() {
      connection = SpyAppConnectionStateNotifier();

      when(() => mockPnpService.saveWifi(any())).thenAnswer((_) async {});
    });

    /// The reboot deadline defaults to 200 ms rather than the production six
    /// minutes; the check deadline stays at its real fifteen seconds unless a case
    /// is *about* the deadline, so a spy that hangs fails the test instead of
    /// passing a shortened one.
    ProviderContainer createFirmwareContainer(
      SpyFirmwareUpdateNotifier firmware, {
      Override? banks,
      Duration checkDeadline = const Duration(seconds: 15),
      Duration rebootDeadline = const Duration(milliseconds: 200),
    }) {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          pnpServiceProvider.overrideWithValue(mockPnpService),
          pnpStatusServiceProvider.overrideWithValue(mockPnpStatusService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sessionProvider.overrideWith(() => mockSessionNotifier),
          firmwareUpdateNotifierProvider.overrideWith(() => firmware),
          appConnectionStateProvider.overrideWith(() => connection),
          banks ??
              firmwareBanksDataProvider.overrideWith(() =>
                  FixedFirmwareBanksDataNotifier(gateFirmwareBanksWithOta)),
          pnpFirmwareCheckDeadlineProvider.overrideWithValue(checkDeadline),
          pnpFirmwareRebootDeadlineProvider.overrideWithValue(rebootDeadline),
        ],
      );
      // Mounts the connection notifier. [SpyAppConnectionStateNotifier.publish] is
      // a state write, and a `Notifier` nothing has read yet has no element to
      // write to — it throws `LateInitializationError`, which `_checkFirmware`
      // catches as "the stage did not complete". The tests still went green: the
      // install had already been dispatched, so every assertion about it held
      // while the reboot wait underneath was never entered. The timing assertions
      // below are what would now notice.
      container.read(appConnectionStateProvider);
      return container;
    }

    /// Enters the wizard at the form, saves, and returns every phase published on
    /// the way — the intermediate ones matter as much as the last.
    Future<List<PnpPhase>> runStage(
      ProviderContainer container, {
      PnpWifiConfig config = savedConfig,
    }) async {
      final published = <PnpPhase>[];
      container.listen(
        pnpProvider,
        (_, next) => published.add(next.phase),
        fireImmediately: false,
      );
      final notifier = container.read(pnpProvider.notifier);
      notifier.setDemoPhase(WizardConfiguring(wifiConfig: config));
      published.clear();
      await notifier.saveChanges();
      return published;
    }

    /// Brings the router back [after] the flash is dispatched, which is what the
    /// recovery framework does on the real path.
    ///
    /// The delay is not decoration: it is the only observable difference between a
    /// stage that waited for the router and one that fell out of the wait — the
    /// cases using this assert the elapsed time is at least this long.
    const comeBackDelay = Duration(milliseconds: 20);
    void Function() comesBack() => () {
          connection.publish(AppConnectionState.waitingForRecovery);
          Future<void>.delayed(comeBackDelay,
              () => connection.publish(AppConnectionState.authenticated));
        };

    test(
        'a router with no ota row finishes setup, and logs no error '
        '(REQ-B1 branches 1 and 2)', () async {
      // `notChecked` is what `checkForUpdate()` returns when the image table has
      // no `ota` instance — an OEM or rebadged build, which is a property of the
      // device rather than a fault.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.notChecked(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardWifiReady>());
      expect(state.errorMessage, isNull);
      expect(firmware.installedOtaInstances, isEmpty);
      expect(firmware.recoveryCalls, 0);
      container.dispose();
    });

    test('a check that found nothing finishes setup (REQ-B1 branch 3)',
        () async {
      // The requirement calls this `Available=false`. It is read through a
      // dispatched check rather than off the field, because the router publishes
      // `Available=false` both when a check found nothing *and* when no check has
      // ever run — which is every factory-fresh router at first connection.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.noUpdateFound(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardWifiReady>());
      expect(state.errorMessage, isNull);
      expect(firmware.checkCalls, 1);
      expect(firmware.installedOtaInstances, isEmpty);
      container.dispose();
    });

    test(
        'an available update is installed on the ota instance '
        '(REQ-B1 branch 4)', () async {
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult:
            const FirmwareOtaCheckResult.updateAvailable(version: '1.0.17.1'),
        onEnterRecovery: comesBack(),
      );
      final container = createFirmwareContainer(firmware);

      final stopwatch = Stopwatch()..start();
      final published = await runStage(container);
      stopwatch.stop();

      // Row 3 of `gateFirmwareBanksWithOta` is the `ota` alias; rows 1 and 2 are
      // the NAND banks, and dispatching at one of those would flash the wrong
      // thing.
      expect(firmware.installedOtaInstances, [3]);
      expect(firmware.recoveryCalls, 1);
      // It waited for the router to come back rather than falling out of the wait.
      expect(stopwatch.elapsed, greaterThanOrEqualTo(comeBackDelay),
          reason:
              'the stage returned before the router came back, so the reboot '
              'wait was skipped or threw');
      // The locked phase is published *before* the dispatch, carrying the version
      // the check named — that is the screen REQ-B2 asks for.
      expect(
        published.whereType<WizardUpdatingFirmware>().map((p) => p.version),
        ['1.0.17.1'],
      );
      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      container.dispose();
    });

    test(
        'an unreadable banks row cannot dispatch an install '
        '(REQ-B1 branch 4 guard)', () async {
      // `hasError` is read before `valueOrNull` because Riverpod keeps the
      // previous value on an `AsyncError`. Reading the value first would dispatch
      // a flash against a row from a read that has since failed.
      final banks = StaleFirmwareBanksDataNotifier();
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        // The spy must not re-await the future here: on an `AsyncError` that read
        // rethrows the cached error, which would land the stage in REQ-B3's
        // `catch` instead of in the guard this case is about.
        readsBanksOnCheck: false,
      );
      final container = createFirmwareContainer(
        firmware,
        banks: firmwareBanksDataProvider.overrideWith(() => banks),
      );
      // Read good, then fail — the state `refresh()` leaves behind, with the last
      // good `ota` row still attached to the error.
      await container.read(firmwareBanksDataProvider.future);
      banks.failWhileKeepingValue();
      expect(container.read(firmwareBanksDataProvider).valueOrNull, isNotNull);

      await runStage(container);

      expect(firmware.installedOtaInstances, isEmpty);
      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      container.dispose();
    });

    test('PnP still completes when the USP read throws (REQ-B3)', () async {
      final firmware = SpyFirmwareUpdateNotifier(
        checkError: const NetworkError(detail: 'no route to router'),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardWifiReady>());
      // Not recorded as an error: the firmware update is the bonus, a configured
      // network is the requirement, and the completion screen has no error slot.
      expect(state.errorMessage, isNull);
      expect(firmware.installedOtaInstances, isEmpty);
      container.dispose();
    });

    test('a check that never answers is abandoned at the deadline (REQ-B3)',
        () async {
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        checkDelay: const Duration(seconds: 30),
      );
      final container = createFirmwareContainer(
        firmware,
        checkDeadline: const Duration(milliseconds: 20),
      );

      await runStage(container);

      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      expect(firmware.installedOtaInstances, isEmpty);
      container.dispose();
    });

    test(
        'a router that does not come back still shows the credentials '
        '(REQ-B3)', () async {
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        // Enters recovery and stays there — the flash took the router with it.
        onEnterRecovery: () =>
            connection.publish(AppConnectionState.waitingForRecovery),
      );
      const deadline = Duration(milliseconds: 30);
      final container =
          createFirmwareContainer(firmware, rebootDeadline: deadline);

      final stopwatch = Stopwatch()..start();
      await runStage(container);
      stopwatch.stop();

      expect(firmware.installedOtaInstances, [3]);
      // It really waited, and it really stopped: the deadline is the behaviour
      // here, so a stage that gave up early would be a different requirement.
      expect(stopwatch.elapsed, greaterThanOrEqualTo(deadline));
      // The credentials are exactly what a user with an unreachable router needs.
      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      container.dispose();
    });

    test('recovery that declines is not waited out', () async {
      // `enterWaiting` can decline — the proximity strategy decides whether this
      // trigger needs recovery on this surface — and then the state never leaves
      // `authenticated`. Without the guard for that, the stage would sit out the
      // whole deadline waiting for a transition nobody is going to make.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        onEnterRecovery: () {},
      );
      final container = createFirmwareContainer(
        firmware,
        rebootDeadline: const Duration(seconds: 5),
      );

      final stopwatch = Stopwatch()..start();
      await runStage(container);
      stopwatch.stop();

      expect(firmware.recoveryCalls, 1);
      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)),
          reason:
              'the stage waited out the reboot deadline for a recovery that '
              'was never entered');
      container.dispose();
    });

    test('the shared firmware notifier is not left mid-install', () async {
      // `isUpdating` is what `_firmwareExitGuard` in `route_usp_dashboard.dart`
      // silently vetoes the back arrow on, so a phase left set here would follow
      // the user to the firmware page and trap them there.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        onEnterRecovery: comesBack(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      expect(firmware.cancelCalls, 1);
      expect(
          container.read(firmwareUpdateNotifierProvider).isUpdating, isFalse);
      container.dispose();
    });

    test('an install the router failed is also cleaned up', () async {
      // The discriminator for cleaning up unconditionally instead of
      // `if (isUpdating)`. That flag is `phase != idle && != done && != failed`,
      // so it is false for exactly the phase this case leaves behind — and a
      // `failed` left on the shared notifier is what shows the user "Update
      // Failed", with a Try Again, for an attempt PnP chose never to report.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        installResult: const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.timedOut,
          rawState: '4',
        ),
        installLeavesPhase: FirmwareUpdatePhase.failed,
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      expect(firmware.installedOtaInstances, [3]);
      expect(firmware.cancelCalls, 1,
          reason:
              'a failed install is a phase left set, the same as a busy one');
      expect(container.read(firmwareUpdateNotifierProvider).phase,
          FirmwareUpdatePhase.idle);
      // A verdict that is not `flashing` has no reboot behind it, so nothing is
      // waited for — and setup still finishes.
      expect(firmware.recoveryCalls, 0);
      expect(container.read(pnpProvider).phase, isA<WizardWifiReady>());
      container.dispose();
    });

    test('a failure in the stage\'s own cleanup still finishes setup (REQ-B3)',
        () async {
      // The discriminator for where the `try` starts. Everything the stage does —
      // the keep-alive, the `ref.read`, the cancel — is inside it, not just the
      // part that talks to the router. `cancel()` writes `state` on an autoDispose
      // notifier, so it can throw for reasons that have nothing to do with the
      // update; with the cleanup outside the `try` that throw would escape into
      // `saveChanges()`, which reverts to the form with an error banner over a
      // network that was configured and flashed successfully.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        onEnterRecovery: comesBack(),
        cancelError: StateError('notifier was disposed'),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      expect(firmware.cancelCalls, 1);
      final state = container.read(pnpProvider);
      expect(state.phase, isA<WizardWifiReady>());
      expect((state.phase as WizardWifiReady).ssid, 'ConfiguredSSID');
      expect(state.errorMessage, isNull);
      container.dispose();
    });

    test('exactly one reconnect is in flight for the firmware reboot (REQ-B5)',
        () async {
      // The recovery framework owns this reboot. PnP's own reconnect —
      // `testReconnect()`, with its backoff and `restoreSession` — must not also
      // be running: two loops on one reboot would race for the same WASM session.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        onEnterRecovery: comesBack(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      expect(firmware.recoveryCalls, 1);
      verifyNever(() => mockPnpService.checkRouterIsBack());
      container.dispose();
    });

    test(
        'a main-WiFi change reconnects first and does not start the firmware '
        'stage (REQ-B5)', () async {
      // The other half of "one reconnect path": when the SSID changed, the save
      // hands off to `WizardNeedsReconnect` and the firmware stage does not begin
      // until `testReconnect()` has returned. Sequential by construction.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(
        container,
        config: savedConfig.copyWith(ssid: 'RenamedSSID'),
      );

      expect(container.read(pnpProvider).phase, isA<WizardNeedsReconnect>());
      expect(firmware.checkCalls, 0);
      container.dispose();
    });

    test('the completion screen shows what was just configured (REQ-B4)',
        () async {
      // REQ-B4's acceptance criterion, and the whole of it since 2026-09-16: the
      // credentials survive the firmware stage — including the router reboot inside
      // it — and are the ones the user just set.
      //
      // They survive because `WizardWifiReady` is built before the stage runs and
      // the reboot is the *router's*: the SPA is not reloaded, `pnpProvider` is not
      // `autoDispose`, and there is one container. This used to also assert a
      // `FlutterSecureStorage` copy read back through a fresh store; that copy is
      // deleted — see `WizardWifiReady`'s doc for the two measurements that retired
      // it, one of which is that `read()` never had a production caller.
      final firmware = SpyFirmwareUpdateNotifier(
        checkResult: const FirmwareOtaCheckResult.updateAvailable(),
        onEnterRecovery: comesBack(),
      );
      final container = createFirmwareContainer(firmware);

      await runStage(container);

      final phase = container.read(pnpProvider).phase;
      expect(phase, isA<WizardWifiReady>());
      expect((phase as WizardWifiReady).ssid, 'ConfiguredSSID');
      expect(phase.password, 'ConfiguredPass123');
      container.dispose();
    });
  });
}
