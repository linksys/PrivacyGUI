import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/simple_wifi_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/connectivity/mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main Riverpod provider for the PnP feature.
final pnpProvider =
    NotifierProvider<BasePnpNotifier, PnpState>(() => PnpNotifier());

/// Abstract base class for the PnP Notifier.
/// Defines the contract for all actions that can be performed during the PnP flow.
abstract class BasePnpNotifier extends Notifier<PnpState> {
  @override
  PnpState build() => const PnpState(
        deviceInfo: null,
        attachedPassword: '',
      );

  //region Step State Management
  //----------------------------------------------------------------------------

  /// Gets the state for a specific step by its ID.
  PnpStepState getStepState(PnpStepId stepId) {
    return state.stepStateList[stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
  }

  /// Sets the entire state for a specific step.
  void setStepState(PnpStepId stepId, PnpStepState stepState) {
    final stepStateData = Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    stepStateData[stepId] = stepState;
    state = state.copyWith(stepStateList: stepStateData);
  }

  /// Updates the status of a specific step.
  void setStepStatus(PnpStepId stepId, {required StepViewStatus status}) {
    final stepStateData = Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(status: status);
    state = state.copyWith(stepStateList: stepStateData);
  }

  /// Merges new data into a specific step's state.
  void setStepData(PnpStepId stepId, {required Map<String, dynamic> data}) {
    final stepStateData = Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(
        data: Map.fromEntries(target.data.entries)..addAll(data));
    state = state.copyWith(stepStateList: stepStateData);
    logger.d('[PnP]: Set step <$stepId> data - ${state.stepStateList[stepId]}');
  }

  /// Sets an error object for a specific step.
  void setStepError(PnpStepId stepId, {Object? error}) {
    final stepStateData = Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(error: error);
    state = state.copyWith(stepStateList: stepStateData);
  }

  /// A helper to get the output from a cached JNAP success result.
  Map<String, dynamic>? getData(JNAPAction action) {
    return (state.data[action] as JNAPSuccess?)?.output;
  }

  //endregion

  //region Abstract Methods
  //----------------------------------------------------------------------------

  /// Orchestrates the initial checks when the PnP flow begins.
  Future<void> runInitialChecks(String? password);

  /// Fetches basic device information.
  Future fetchDeviceInfo([bool clearCurrentSN = true]);

  /// Validates the admin password against the router.
  Future checkAdminPassword(String? password);

  /// Checks for a live internet connection.
  Future checkInternetConnection([int retries = 1]);

  /// Checks if the router is in an unconfigured (factory default) state.
  Future checkRouterConfigured();

  /// Checks the auto-configuration status of the router.
  Future<AutoConfigurationSettings?> autoConfigurationCheck();

  /// Checks if the admin password has been set by the user.
  Future<bool> isRouterPasswordSet();

  /// Fetches all necessary data for the PnP wizard steps.
  Future fetchData();

  /// Saves all collected settings from the wizard to the router.
  Future save();

  /// Tests if the connection to the router has been re-established after a change.
  Future testConnectionReconnected();

  /// Fetches the list of connected child nodes.
  Future fetchDevices();

  /// Forces the PnP flow to require a login.
  void setForceLogin(bool force);

  /// Stores a password provided from an external source (e.g., URL).
  void setAttachedPassword(String? password);

  /// Gets the default Wi-Fi credentials from the device.
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase();

  /// Gets the default Guest Wi-Fi credentials from the device.
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase();

  //endregion
}

/// A mock implementation of the PnP Notifier for testing and UI development.
class MockPnpNotifier extends BasePnpNotifier {
  @override
  Future checkAdminPassword(String? password) {
    if (password == 'Linksys123!') {
      return Future.delayed(const Duration(seconds: 1));
    }
    return Future.delayed(const Duration(seconds: 3))
        .then((value) => throw ExceptionInvalidAdminPassword());
  }

  @override
  Future checkInternetConnection([int retries = 1]) {
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => throw ExceptionNoInternetConnection());
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) {
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => AutoConfigurationSettings(
              isAutoConfigurationSupported: true,
              userAcknowledgedAutoConfiguration: false,
              autoConfigurationMethod: AutoConfigurationMethod.preConfigured,
            ));
  }

  @override
  Future<bool> isRouterPasswordSet() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => true);
  }

  @override
  Future fetchData() {
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    return (
      name: 'Linksys1234567',
      password: 'Linksys123456@',
      security: 'WPA2/WPA3-Mixed-Personal'
    );
  }

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    return (
      name: 'Guest-Linksys1234567',
      password: 'GuestLinksys123456@',
    );
  }

  @override
  Future save() {
    return Future.delayed(const Duration(seconds: 5));
    // .then((value) => throw ErrorNeedToReconnect());
  }

  @override
  Future checkRouterConfigured() {
    state = state.copyWith(isUnconfigured: true);

    return Future.delayed(const Duration(seconds: 1))
        .then((value) => throw ExceptionRouterUnconfigured());
  }

  @override
  Future testConnectionReconnected() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => true);
  }

  @override
  Future fetchDevices() {
    return Future.delayed(const Duration(seconds: 1)).then((_) {});
  }

  @override
  void setAttachedPassword(String? password) {
    state = state.copyWith(attachedPassword: password);
  }

  @override
  void setForceLogin(bool force) {
    state = state.copyWith(forceLogin: force);
  }

  @override
  Future<void> runInitialChecks(String? password) {
    return Future.delayed(const Duration(seconds: 1));
  }
}

/// The concrete implementation of the PnP Notifier.
/// This class contains the core business logic for the PnP setup flow.
class PnpNotifier extends BasePnpNotifier with AvailabilityChecker {
  @override
  Future<void> runInitialChecks(String? password) async {
    logger.i('[PnP]: Running initial checks...');
    // The UI will show a generic "loading" spinner while this runs.
    await fetchDeviceInfo();
    if (password != null) {
      setAttachedPassword(password);
    }
    // This will throw ExceptionRouterUnconfigured on purpose if the router is unconfigured.
    await checkRouterConfigured();

    final isLoggedIn = ref.read(routerRepositoryProvider).isLoggedIn();
    if (!isLoggedIn) {
      logger.i('[PnP]: Not logged in, checking admin password.');
      // This will throw ExceptionInvalidAdminPassword on purpose if the password is wrong.
      await checkAdminPassword(state.attachedPassword);
    }

    logger.i('[PnP]: Checking for internet connection.');
    // This will throw ExceptionNoInternetConnection on purpose if there is no internet.
    await checkInternetConnection();

    // If all checks pass, the method completes successfully.
    logger.i('[PnP]: Initial checks completed successfully.');
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {
    logger.i('[PnP]: Fetching device info...');
    final deviceInfo = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getDeviceInfo,
          type: CommandType.local,
          fetchRemote: true,
          retries: 10,
          timeoutMs: 3000,
        )
        .then((result) => NodeDeviceInfo.fromJson(result.output))
        .catchError((e) {
      logger.e('[PnP]: Failed to fetch device info.', error: e);
      throw ExceptionFetchDeviceInfo();
    });
    // check current sn and clear it
    final prefs = await SharedPreferences.getInstance();
    if (clearCurrentSN) {
      await prefs.remove(pCurrentSN);
    }
    await prefs.setString(pPnpConfiguredSN, deviceInfo.serialNumber);
    // Pause polling
    ref.read(pollingProvider.notifier).paused = true;
    // Build/Update better actions
    buildBetterActions(deviceInfo.services);
    ref.read(routerRepositoryProvider).send(JNAPAction.getDeviceMode,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
    state = state.copyWith(deviceInfo: deviceInfo);
    logger.i('[PnP]: Fetched device info successfully for ${deviceInfo.modelNumber}.');
  }

  @override
  Future checkAdminPassword(String? password) async {
    logger.i('[PnP]: Checking admin password.');
    if (password == null) {
      logger.w('[PnP]: Admin password is null.');
      throw ExceptionInvalidAdminPassword();
    }
    await ref
        .read(authProvider.notifier)
        .localLogin(password, pnp: true, guardError: false)
        .then((value) {
      logger.i('[PnP]: Admin password accepted.');
      // Clear the password in pnp state once logging in successfully
      setAttachedPassword(null);
    }).catchError((error) {
      logger.e('[PnP]: Admin password check failed.', error: error);
      throw ExceptionInvalidAdminPassword();
    }, test: (error) => error is JNAPError && error.result == errorJNAPUnauthorized);
  }

  /// check internet connection within 30 seconds
  @override
  Future checkInternetConnection([int retries = 1]) async {
    Future<bool> isInternetConnected() async {
      bool isConnected = false;
      for (int i = 0; i < retries; i++) {
        logger.d(
            '[PnP]: Checking internet connection (Attempt ${i + 1}/$retries)');
        isConnected = await ref
            .read(routerRepositoryProvider)
            .send(
              JNAPAction.getInternetConnectionStatus,
              fetchRemote: true,
              auth: true,
              retries: 0,
              cacheLevel: CacheLevel.noCache,
            )
            .then((result) {
          return result.output['connectionStatus'] == 'InternetConnected';
        }).onError((error, stackTrece) {
          return false;
        });
        if (isConnected) {
          logger.i('[PnP]: Internet connection detected.');
          break;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      return isConnected;
    }

    final isOnline = await isInternetConnected();
    if (!isOnline) {
      logger.e('[PnP]: No internet connection after all retries.');
      throw ExceptionNoInternetConnection();
    }
    return true;
  }

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() async {
    if (!serviceHelper.isSupportPnP(state.deviceInfo?.services)) {
      logger.i('[PnP]: The router does NOT support PNP!');
      return null;
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
          JNAPAction.getAutoConfigurationSettings,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then<AutoConfigurationSettings?>(
            (data) => AutoConfigurationSettings.fromMap(data.output))
        .onError((error, stackTrace) => null);
    logger.d('[PnP]: Auto Configuration Check result: $result');
    return result;
  }

  @override
  Future<bool> isRouterPasswordSet() {
    final transaction = JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.isAdminPasswordDefault, {}),
        const MapEntry(JNAPAction.isAdminPasswordSetByUser, {}),
      ],
      auth: true,
    );
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .transaction(
      transaction,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    )
        .then((response) {
      bool isAdminPasswordDefault = (response.data
                  .firstWhereOrNull((element) =>
                      element.key == JNAPAction.isAdminPasswordDefault)
                  ?.value as JNAPSuccess?)
              ?.output['isAdminPasswordDefault'] ??
          false;
      bool isAdminPasswordSetByUser = (response.data
                  .firstWhereOrNull((element) =>
                      element.key == JNAPAction.isAdminPasswordSetByUser)
                  ?.value as JNAPSuccess?)
              ?.output['isAdminPasswordSetByUser'] ??
          true;
      logger.d(
          '[PnP]: Admin password status: isAdminPasswordDefault=$isAdminPasswordDefault, isAdminPasswordSetByUser=$isAdminPasswordSetByUser');
      return !isAdminPasswordDefault || isAdminPasswordSetByUser;
    }).onError((error, stackTrace) {
      logger.e('[PnP]: Error checking if password is set. Assuming true.', error: error);
      return true; // error handling - set configured to prevent go to pnp
    });
  }

  @override
  Future fetchData() async {
    logger.i('[PnP]: Fetching initial data for wizard steps...');
    bool isSupportNodeLight =
        serviceHelper.isSupportLedMode(state.deviceInfo?.services);
    final transaction = JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.getSimpleWiFiSettings, {}),
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
        if (isSupportNodeLight)
          const MapEntry(JNAPAction.getLedNightModeSetting, {}),
        const MapEntry(JNAPAction.getAutoConfigurationSettings, {}),
        const MapEntry(JNAPAction.getBluetoothAutoOnboardingSettings, {}),
        const MapEntry(JNAPAction.getRadioInfo, {}),
        const MapEntry(JNAPAction.getWANSettings, {}),
        const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      ],
      auth: true,
    );
    return ref
        .read(routerRepositoryProvider)
        .transaction(transaction, fetchRemote: true, retries: 10)
        .then((response) {
      logger.i('[PnP]: Successfully fetched initial data.');
      state = state.copyWith(data: Map.fromEntries(response.data));
    });
  }

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    String? name, passphrase, security;
    final getRadioInfoJson = getData(JNAPAction.getRadioInfo);
    if (getRadioInfoJson != null) {
      final getRadioInfo = GetRadioInfo.fromMap(getRadioInfoJson);
      final radios = getRadioInfo.radios;
      name = radios.firstOrNull?.settings.ssid;
      passphrase = radios.firstOrNull?.settings.wpaPersonalSettings?.passphrase;
      security = radios.firstOrNull?.settings.security;
    }

    return (
      name: name ?? '',
      password: passphrase ?? '',
      security: security ?? 'None'
    );
  }

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    String? name, passphrase;
    final guestRadioSettingsJson = getData(JNAPAction.getGuestRadioSettings);
    if (guestRadioSettingsJson != null) {
      final guestRadioSettings =
          GuestRadioSettings.fromMap(guestRadioSettingsJson);
      final radios = guestRadioSettings.radios;
      name = radios.firstOrNull?.guestSSID;
      passphrase = radios.firstOrNull?.guestWPAPassphrase;
    }
    return (name: name ?? '', password: passphrase ?? '');
  }

  //region Save Logic Refactoring
  //----------------------------------------------------------------------------

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildPersonalWiFiPayload() {
    final defaultWiFi = getDefaultWiFiNameAndPassphrase();
    final wifiStateData = getStepState(PnpStepId.personalWifi).data;
    final wifiName = wifiStateData['ssid'] as String? ?? defaultWiFi.name;
    final wifiPassphase =
        wifiStateData['password'] as String? ?? defaultWiFi.password;

    final isWiFiChanged =
        wifiName != defaultWiFi.name || wifiPassphase != defaultWiFi.password;
    logger.d('[PnP]: Wi-Fi changed: $isWiFiChanged');

    if (!isWiFiChanged) return null;

    final simpleWiFiSettingsJson =
        getData(JNAPAction.getSimpleWiFiSettings) ?? {};
    final simpleWiFiSettings =
        List.from(simpleWiFiSettingsJson['simpleWiFiSettings'])
            .map((e) => SimpleWiFiSettings.fromMap(e).copyWith(
                ssid: wifiName,
                passphrase: wifiPassphase,
                security: defaultWiFi.security))
            .toList();

    return MapEntry(JNAPAction.setSimpleWiFiSettings, {
      'simpleWiFiSettings':
          simpleWiFiSettings.map((e) => e.toMap()).toList()
    });
  }

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildGuestWiFiPayload() {
    final deviceInfo = state.deviceInfo;
    final isGuestWiFiSupport =
        serviceHelper.isSupportGuestNetwork(deviceInfo?.services);
    if (!isGuestWiFiSupport) return null;

    final defaultGuestWiFi = getDefaultGuestWiFiNameAndPassPhrase();
    final guestWifiStateData = getStepState(PnpStepId.guestWifi).data;
    final isGuestEnabled = guestWifiStateData['isEnabled'] as bool? ?? false;
    logger.d('[PnP]: Guest Wi-Fi will be enabled: $isGuestEnabled');

    final guestWiFiName =
        guestWifiStateData['ssid'] as String? ?? defaultGuestWiFi.name;
    final guestWiFiPassphase =
        guestWifiStateData['password'] as String? ?? defaultGuestWiFi.password;
    final guestWifiRadioSettingsJson =
        getData(JNAPAction.getGuestRadioSettings) ?? {};
    var guestRadioSettings =
        GuestRadioSettings.fromMap(guestWifiRadioSettingsJson);
    var setGuestRadioSettings =
        SetGuestRadioSettings.fromGuestRadioSettings(guestRadioSettings);
    setGuestRadioSettings =
        setGuestRadioSettings.copyWith(isGuestNetworkEnabled: isGuestEnabled);
    if (isGuestEnabled) {
      var radios = setGuestRadioSettings.radios
          .map((e) => e.copyWith(
              guestSSID: guestWiFiName, guestWPAPassphrase: guestWiFiPassphase))
          .toList();
      setGuestRadioSettings = setGuestRadioSettings.copyWith(radios: radios);
    }

    return MapEntry(
        JNAPAction.setGuestRadioSettings, setGuestRadioSettings.toMap());
  }

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildNightModePayload() {
    final deviceInfo = state.deviceInfo;
    final isNightModeSupport =
        serviceHelper.isSupportLedMode(deviceInfo?.services);
    final nightModeStateData = getStepState(PnpStepId.nightMode).data;
    final isNightModeEnabled =
        nightModeStateData['isEnabled'] as bool? ?? false;
    logger.d('[PnP]: Night mode will be enabled: $isNightModeEnabled');

    if (!isNightModeSupport || !isNightModeEnabled) return null;

    var nightModeSettings =
        NodeLightSettings(isNightModeEnable: isNightModeEnabled);
    if (isNightModeEnabled) {
      nightModeSettings = nightModeSettings.copyWith(startHour: 20, endHour: 8);
    }
    return MapEntry(JNAPAction.setLedNightModeSetting, nightModeSettings.toMap());
  }

  MapEntry<JNAPAction, Map<String, dynamic>> _buildFirmwareUpdatePayload() {
    final firmwareUpdateSettingsJson =
        getData(JNAPAction.getFirmwareUpdateSettings);
    final firmwareUpdateSettings = firmwareUpdateSettingsJson != null
        ? FirmwareUpdateSettings.fromMap(firmwareUpdateSettingsJson)
            .copyWith(
                updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto)
            .toMap()
        : <String, dynamic>{};
    return MapEntry(
        JNAPAction.setFirmwareUpdateSettings, firmwareUpdateSettings);
  }

  MapEntry<JNAPAction, Map<String, dynamic>> _buildCloseCommandPayload() {
    final defaultWiFi = getDefaultWiFiNameAndPassphrase();
    final closeCommand = state.isRouterUnConfigured
        ? JNAPAction.pnpSetAdminPassword
        : JNAPAction.setUserAcknowledgedAutoConfiguration;
    final closeData = state.isRouterUnConfigured
        ? {'adminPassword': defaultWiFi.password}
        : <String, dynamic>{};
    return MapEntry(closeCommand, closeData);
  }

  @override
  Future save() async {
    logger.i('[PnP]: Starting save process...');
    final prefs = await SharedPreferences.getInstance();
    if (state.deviceInfo != null) {
      prefs.setString(pPnpConfiguredSN, state.deviceInfo!.serialNumber);
    }

    // 1. Build payloads using helper methods
    final commands = [
      _buildPersonalWiFiPayload(),
      _buildGuestWiFiPayload(),
      _buildNightModePayload(),
      _buildFirmwareUpdatePayload(),
      if (state.isRouterUnConfigured)
        const MapEntry(JNAPAction.setDeviceMode, {'mode': 'Master'}),
      _buildCloseCommandPayload(),
    ].whereNotNull().toList(); // Filter out nulls (no changes needed)

    // 2. Build the transaction
    final transaction = JNAPTransactionBuilder(commands: commands, auth: true);
    logger.i('[PnP]: Sending save transaction with ${transaction.commands.length} commands.');

    // 3. Execute transaction and handle post-save flow
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          transaction,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          sideEffectOverrides:
              const JNAPSideEffectOverrides(maxRetry: 18, retryDelayInSec: 10),
        )
        .catchError((error) {
      // Connection error,
      logger.e('[PnP]: Connection changed during save. Need to reconnect.',
          error: error);
      throw ExceptionNeedToReconnect();
    }, test: (error) => error is ClientException || error is JNAPSideEffectError)
        .onError((error, stackTrace) {
      if (error is ExceptionNeedToReconnect) {
        throw error;
      }
      // Saving error
      logger.e('[PnP]: Save transaction failed.', error: error);
      throw ExceptionSavingChanges(error);
    }).then((_) async {
      logger.i('[PnP]: Save transaction successful. Waiting for reconnect test.');
      await Future.delayed(const Duration(seconds: 3));
    }).then((_) {
      final password = getDefaultWiFiNameAndPassphrase().password;
      return testConnectionReconnected()
          .then((_) => checkAdminPassword(password));
    }).whenComplete(() {
      logger.i('[PnP]: Save flow complete. Removing PnP SN.');
      prefs.remove(pPnpConfiguredSN);
    });
  }

  //endregion

  @override
  Future testConnectionReconnected() async {
    logger.i('[PnP]: Testing connection after settings change...');
    // Test connect to the proper router
    final result = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDeviceInfo,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            retries: 0,
            timeoutMs: 3000)
        .onError((error, stackTrace) {
      // Can't get device info
      logger.e('[PnP]: Could not get device info during reconnect test.',
          error: error);
      throw ExceptionNeedToReconnect();
    });
    final deviceInfo = NodeDeviceInfo.fromJson(result.output);
    final isConnected =
        state.deviceInfo?.serialNumber == deviceInfo.serialNumber;
    if (!isConnected) {
      logger.e('[PnP]: Reconnect test failed. Connected to a different router.');
      throw ExceptionNeedToReconnect();
    }
    logger.i('[PnP]: Reconnect test successful.');
    return;
  }

  @override
  Future<void> checkRouterConfigured() async {
    final isFirstFetch = state.isUnconfigured == null;
    final repo = ref.read(routerRepositoryProvider);
    logger.d('[PnP]: Checking if router is configured...');
    final isUnconfigured = await repo
        .send(JNAPAction.getDeviceMode, fetchRemote: true)
        .then((value) =>
            (value.output['mode'] ?? 'Unconfigured') == 'Unconfigured');
    state = state.copyWith(isUnconfigured: isUnconfigured);
    logger.i('[PnP]: Router is ${isUnconfigured ? 'UNCONFIGURED' : 'CONFIGURED'}.');
    if (isUnconfigured && isFirstFetch) {
      throw ExceptionRouterUnconfigured();
    }
  }

  @override
  Future fetchDevices() {
    logger.i('[PnP]: Fetching child nodes...');
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.getDevices,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    )
        .then((result) {
      final deviceList = List.from(
        result.output['devices'],
      )
          .map((e) => LinksysDevice.fromMap(e))
          .where((device) => device.nodeType != null || device.isAuthority)
          .toList();
      logger.i('[PnP]: Found ${deviceList.length} child nodes.');
      state = state.copyWith(childNodes: deviceList);
    });
  }

  @override
  void setAttachedPassword(String? password) {
    logger.d('[PnP]: Setting attached password.');
    state = state.copyWith(attachedPassword: password);
  }

  @override
  void setForceLogin(bool force) {
    logger.d('[PnP]: Setting forceLogin to $force.');
    state = state.copyWith(forceLogin: force);
  }
}
