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
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';
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
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/connectivity/mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pnpProvider =
    NotifierProvider<BasePnpNotifier, PnpState>(() => PnpNotifier());

abstract class BasePnpNotifier extends Notifier<PnpState> {
  @override
  PnpState build() => const PnpState(
        deviceInfo: null,
        attachedPassword: '',
      );

  ///
  PnpStepState getStepState(int index) {
    return state.stepStateList[index] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
  }

  void setStepState(int index, PnpStepState stepState) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    stepStateData[index] = stepState;
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepStatus(int index, {required StepViewStatus status}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(status: status);
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepData(int index, {required Map<String, dynamic> data}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(
        data: Map.fromEntries(target.data.entries)..addAll(data));
    state = state.copyWith(stepStateList: stepStateData);
    logger.d('[PnP]: Set step <$index> data - ${state.stepStateList[index]}');
  }

  void setStepError(int index, {Object? error}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(error: error);
    state = state.copyWith(stepStateList: stepStateData);
  }

  Map<String, dynamic>? getData(JNAPAction action) {
    return (state.data[action] as JNAPSuccess?)?.output;
  }
  // abstract functions

  Future fetchDeviceInfo([bool clearCurrentSN = true]);
  Future checkAdminPassword(String? password);
  Future checkInternetConnection([int retries = 1]);
  Future checkRouterConfigured();
  Future<AutoConfigurationSettings?> autoConfigurationCheck();
  Future<bool> isRouterPasswordSet();
  Future fetchData();
  Future save();
  Future testConnectionReconnected();
  Future fetchDevices();
  void setForceLogin(bool force);
  void setAttachedPassword(String? password);

  // Personal WiFi
  PnpWiFiSettings getDefaultWiFiSettings();
  // Guest WiFi
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase();
  // Auto Master
  Future<AutoMasterStatus?> checkAutoMasterStatus();
  Stream<AutoMasterStatus?> pollAutoMasterStatus();
  void setAutoMasterStatusOnEntry(AutoMasterStatus? status);
}

class MockPnpNotifier extends BasePnpNotifier {
  // Simulate Auto Parent case:
  // - Router is already Master (isUnconfigured = false)
  // - Not pre-paired (isPrePaired = false)
  // - Should show YourNetworkStep for adding nodes

  @override
  Future checkAdminPassword(String? password) {
    if (password == 'Linksys123!') {
      return Future.delayed(const Duration(seconds: 1));
    }
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => throw ExceptionInvalidAdminPassword());
  }

  @override
  Future checkInternetConnection([int retries = 1]) {
    // Auto Parent: internet connected
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) {
    // Set mock device info to allow navigation to pnpConfig
    // Delay state modification to avoid "modify provider while building" error
    return Future.delayed(const Duration(seconds: 1)).then((_) {
      state = state.copyWith(
        deviceInfo: const NodeDeviceInfo(
          manufacturer: 'Linksys',
          modelNumber: 'MBE70',
          hardwareVersion: '1',
          description: 'Linksys Velop',
          serialNumber: 'Mock12345678',
          firmwareVersion: '1.0.0',
          firmwareDate: '2024-01-01T00:00:00Z',
          services: [
            'http://linksys.com/jnap/guestnetwork/GuestNetwork',
            'http://linksys.com/jnap/routerleds/RouterLEDs4',
          ],
        ),
      );
    });
  }

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => AutoConfigurationSettings(
              isAutoConfigurationSupported: true,
              userAcknowledgedAutoConfiguration: false,
              autoConfigurationMethod: AutoConfigurationMethod.autoParent,
            ));
  }

  @override
  Future<bool> isRouterPasswordSet() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => true);
  }

  @override
  Future fetchData() {
    // Simulate AutoParent case (not pre-paired)
    return Future.delayed(const Duration(seconds: 1)).then((_) {
      state = state.copyWith(isPrePaired: false);
      logger.d('[PnP Mock]: fetchData - isPrePaired=${state.isPrePaired}');
    });
  }

  @override
  PnpWiFiSettings getDefaultWiFiSettings() {
    return const PnpWiFiSettings(
      isSplitMode: false,
      radios: [
        PnpWiFiRadio(
          radioId: 'RADIO_2.4GHz',
          band: 'RADIO_2.4GHz',
          ssid: 'Linksys1234567',
          password: 'Linksys123456@',
          security: 'WPA2/WPA3-Mixed-Personal',
          isEnabled: true,
        ),
      ],
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
  }

  @override
  Future checkRouterConfigured() {
    // Auto Parent: already configured as Master
    state = state.copyWith(isUnconfigured: false);
    return Future.delayed(const Duration(seconds: 1));
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
  Future<AutoMasterStatus?> checkAutoMasterStatus() {
    return Future.value(AutoMasterStatus.idle);
  }

  @override
  Stream<AutoMasterStatus?> pollAutoMasterStatus() async* {
    yield AutoMasterStatus.idle;
  }

  @override
  void setAutoMasterStatusOnEntry(AutoMasterStatus? status) {
    state = state.copyWith(autoMasterStatusOnEntry: () => status);
  }
}

class PnpNotifier extends BasePnpNotifier with AvailabilityChecker {
  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {
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
      logger.i('[PnP]: Failed to fetch device info');
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
  }

  @override
  Future checkAdminPassword(String? password) async {
    if (password == null) {
      throw ExceptionInvalidAdminPassword();
    }
    await ref
        .read(authProvider.notifier)
        .localLogin(password, pnp: true, guardError: false)
        .then((value) {
      // Clear the password in pnp state once logging in successfully
      setAttachedPassword(null);
    }).catchError((error) => throw ExceptionInvalidAdminPassword(),
            test: (error) =>
                error is JNAPError && error.result == errorJNAPUnauthorized);
  }

  /// check internet connection within 30 seconds
  @override
  Future checkInternetConnection([int retries = 1]) async {
    Future<bool> isInternetConnected() async {
      bool isConnected = false;
      for (int i = 0; i < retries; i++) {
        logger.i(
            '[PnP]: Check internet connections MAX retries <$retries>, i=$i');
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
          break;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      return isConnected;
    }

    Future<bool> testPing() => ref.read(cloudRepositoryProvider).testPingPng();
    final isOnline = await isInternetConnected();
    // final isOnline = await testPing();
    if (!isOnline) {
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
          '[PnP]: Admin changed? isAdminPasswordDefault=$isAdminPasswordDefault, isAdminPasswordSetByUser=$isAdminPasswordSetByUser');
      return !isAdminPasswordDefault || isAdminPasswordSetByUser;
    }).onError((error, stackTrace) =>
            true); // error handling - set configured to prevent go to pnp
  }

  @override
  Future fetchData() async {
    // if (state.deviceInfo == null) {
    //   await fetchDeviceInfo();
    // }
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
      final dataMap = Map.fromEntries(response.data);
      state = state.copyWith(data: dataMap);
      // Check if the device is pre-paired
      final autoConfigResult =
          (dataMap[JNAPAction.getAutoConfigurationSettings] as JNAPSuccess?)
              ?.output;
      if (autoConfigResult != null) {
        final autoConfig = AutoConfigurationSettings.fromMap(autoConfigResult);
        final isPrePaired = autoConfig.autoConfigurationMethod ==
            AutoConfigurationMethod.preConfigured;
        state = state.copyWith(isPrePaired: isPrePaired);
        logger.d('[PnP]: isPrePaired=$isPrePaired');
      }
    });
  }

  @override
  PnpWiFiSettings getDefaultWiFiSettings() {
    final getRadioInfoJson = getData(JNAPAction.getRadioInfo);
    if (getRadioInfoJson == null) {
      return const PnpWiFiSettings(isSplitMode: false, radios: []);
    }

    final getRadioInfo = GetRadioInfo.fromMap(getRadioInfoJson);
    // Note: RouterRadio.band is already in the same format as
    // getSimpleWiFiSettings (e.g. '2.4GHz', no 'RADIO_' prefix), so it can be
    // used directly as the per-band key in save().
    final pnpRadios = getRadioInfo.radios
        .map((r) => PnpWiFiRadio(
              radioId: r.radioID,
              band: r.band,
              ssid: r.settings.ssid,
              password: r.settings.wpaPersonalSettings?.passphrase ?? '',
              security: r.settings.security,
              isEnabled: r.settings.isEnabled,
            ))
        .toList();

    // Determine split mode: check if any radio has different SSID or password
    final firstRadio = pnpRadios.firstOrNull;
    final isSplitMode = firstRadio != null &&
        pnpRadios.any((r) =>
            r.ssid != firstRadio.ssid || r.password != firstRadio.password);

    return PnpWiFiSettings(isSplitMode: isSplitMode, radios: pnpRadios);
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

  @override
  Future save() async {
    // store current configured SN
    final deviceInfo = state.deviceInfo;
    final prefs = await SharedPreferences.getInstance();
    if (deviceInfo != null) {
      prefs.setString(pPnpConfiguredSN, deviceInfo.serialNumber);
    }
    final isGuestWiFiSupport =
        serviceHelper.isSupportGuestNetwork(deviceInfo?.services);
    final isNightModeSupport =
        serviceHelper.isSupportLedMode(deviceInfo?.services);

    // processing data
    final defaultWiFiSettings = getDefaultWiFiSettings();
    final defaultGuestWiFi = getDefaultGuestWiFiNameAndPassPhrase();
    // if configured call setUserAcknowledgedAutoConfiguration else call setAdminPassword
    final closeCommand = state.isRouterUnConfigured
        ? JNAPAction.pnpSetAdminPassword
        : JNAPAction.setUserAcknowledgedAutoConfiguration;
    final closeData = state.isRouterUnConfigured
        ? {'adminPassword': defaultWiFiSettings.primaryRadio?.password ?? ''}
        : <String, dynamic>{};
    // personal wifi
    final wifiStateData = getStepState(PersonalWiFiStep.id).data;
    final isSplitMode = wifiStateData['isSplitMode'] as bool? ?? false;
    final getRadioInfoJson = getData(JNAPAction.getRadioInfo) ?? {};
    final getRadioInfo = GetRadioInfo.fromMap(getRadioInfoJson);

    // Resolve the new (ssid, password) for a given band.
    //  - split mode: from wifiStateData['perBandSettings'][band]
    //  - unified mode: the same ssid/password for every band
    // Returns null when there is no override for this band (leave it as-is).
    ({String ssid, String password})? resolveBandCredential(String band) {
      if (isSplitMode) {
        final perBandSettings =
            wifiStateData['perBandSettings'] as Map<String, dynamic>? ?? {};
        final bandSettings = perBandSettings[band] as Map<String, dynamic>?;
        if (bandSettings == null) {
          return null;
        }
        return (
          ssid: bandSettings['ssid'] as String? ?? '',
          password: bandSettings['password'] as String? ?? '',
        );
      }
      final primaryRadio = defaultWiFiSettings.primaryRadio;
      return (
        ssid: wifiStateData['ssid'] as String? ?? primaryRadio?.ssid ?? '',
        password:
            wifiStateData['password'] as String? ?? primaryRadio?.password ?? '',
      );
    }

    // Build SetRadioSettings from the current radio info, overriding only the
    // ssid and passphrase per band. Every other field (mode/channel/
    // channelWidth/broadcastSSID/security) is preserved straight from the
    // device, which avoids the security-downgrade problem that
    // SetSimpleWiFiSettings had (getSimpleWiFiSettings could report 'None').
    final newRadios = getRadioInfo.radios.map((r) {
      final credential = resolveBandCredential(r.band);
      if (credential == null) {
        return NewRadioSettings(radioID: r.radioID, settings: r.settings);
      }
      return NewRadioSettings(
        radioID: r.radioID,
        settings: r.settings.copyWith(
          ssid: credential.ssid,
          // copyWith uses `x ?? this.x`, so passing null keeps the existing
          // value. Only update the passphrase when the band actually uses a
          // WPA personal key (open networks have no wpaPersonalSettings).
          wpaPersonalSettings: r.settings.wpaPersonalSettings
              ?.copyWith(passphrase: credential.password),
        ),
      );
    }).toList();
    final setRadioSettings = SetRadioSettings(radios: newRadios);

    // Only write if a band's ssid/password actually differs from the current
    // router values (applies to both unified and split modes).
    final isWiFiChanged = getRadioInfo.radios.any((r) {
      final credential = resolveBandCredential(r.band);
      if (credential == null) {
        return false;
      }
      return credential.ssid != r.settings.ssid ||
          credential.password !=
              (r.settings.wpaPersonalSettings?.passphrase ?? '');
    });
    // guest wifi
    final guestWifiStateData = getStepState(GuestWiFiStep.id).data;
    final isGuestEnabled = guestWifiStateData['isEnabled'] as bool? ?? false;
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
      setGuestRadioSettings =
          setGuestRadioSettings.copyWith(isGuestNetworkEnabled: isGuestEnabled);
      var radios = setGuestRadioSettings.radios
          .map((e) => e.copyWith(
              guestSSID: guestWiFiName, guestWPAPassphrase: guestWiFiPassphase))
          .toList();
      setGuestRadioSettings = setGuestRadioSettings.copyWith(radios: radios);
    }
    // Night mode
    final nightModeStateData = getStepState(NightModeStep.id).data;
    final isNightModeEnabled =
        nightModeStateData['isEnabled'] as bool? ?? false;
    var nightModeSettings =
        NodeLightSettings(isNightModeEnable: isNightModeEnabled);
    if (isNightModeEnabled) {
      nightModeSettings = nightModeSettings.copyWith(startHour: 20, endHour: 8);
    }
    // enable auto firmware update
    final firmwareUpdateSettingsJson =
        getData(JNAPAction.getFirmwareUpdateSettings);
    final firmwareUpdateSettings = firmwareUpdateSettingsJson != null
        ? FirmwareUpdateSettings.fromMap(firmwareUpdateSettingsJson)
            .copyWith(
                updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto)
            .toMap()
        : <String, dynamic>{};
    // set device mode to master if router is unconfigured

    // Build transaction commands
    final transaction = JNAPTransactionBuilder(commands: [
      if (isWiFiChanged)
        MapEntry(JNAPAction.setRadioSettings, setRadioSettings.toMap()),
      if (isGuestWiFiSupport)
        MapEntry(
            JNAPAction.setGuestRadioSettings, setGuestRadioSettings.toMap()),
      if (isNightModeSupport && isNightModeEnabled)
        MapEntry(JNAPAction.setLedNightModeSetting, nightModeSettings.toMap()),
      MapEntry(JNAPAction.setFirmwareUpdateSettings, firmwareUpdateSettings),
      if (state.isRouterUnConfigured)
        const MapEntry(JNAPAction.setDeviceMode, {'mode': 'Master'}),
      MapEntry(closeCommand, closeData),
    ], auth: true);

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
          logger.d('[PnP]: Connection changed. Need to reconnect to the WiFi');
          throw ExceptionNeedToReconnect();
        },
            test: (error) =>
                error is ClientException || error is JNAPSideEffectError)
        .onError((error, stackTrace) {
          if (error is ExceptionNeedToReconnect) {
            throw error;
          }
          // Saving error
          throw ExceptionSavingChanges(error);
        })
        .then((_) async => await Future.delayed(const Duration(seconds: 3)))
        .then((_) => testConnectionReconnected())
        .then((_) => checkAdminPassword(defaultWiFiSettings.primaryRadio?.password))
        .whenComplete(() => prefs.remove(pPnpConfiguredSN));
    // return Future.delayed(Duration(seconds: 5));
  }

  @override
  Future testConnectionReconnected() async {
    // Test connect to the propor router
    final result = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDeviceInfo,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            retries: 0,
            timeoutMs: 3000)
        .onError((error, stackTrace) {
      // Can't get device info
      throw ExceptionNeedToReconnect();
    });
    final deviceInfo = NodeDeviceInfo.fromJson(result.output);
    final isConnected =
        state.deviceInfo?.serialNumber == deviceInfo.serialNumber;
    if (!isConnected) {
      throw ExceptionNeedToReconnect();
    }
    return;
  }

  @override
  Future<void> checkRouterConfigured() async {
    final isFirstFetch = state.isUnconfigured == null;
    final repo = ref.read(routerRepositoryProvider);
    final isUnconfigured = await repo
        .send(JNAPAction.getDeviceMode, fetchRemote: true)
        .then((value) =>
            (value.output['mode'] ?? 'Unconfigured') == 'Unconfigured');
    state = state.copyWith(isUnconfigured: isUnconfigured);
    if (isUnconfigured && isFirstFetch) {
      throw ExceptionRouterUnconfigured();
    }
  }

  @override
  Future fetchDevices() {
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
      state = state.copyWith(childNodes: deviceList);
    });
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
  Future<AutoMasterStatus?> checkAutoMasterStatus() async {
    try {
      final result = await ref.read(routerRepositoryProvider).send(
            JNAPAction.getAutoMasterStatus,
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            retries: 0,
            timeoutMs: 5000,
          );
      final response = GetAutoMasterStatusResponse.fromMap(result.output);
      logger.d('[PnP]: Auto Master status: ${response.autoMasterStatus}');
      return response.autoMasterStatus;
    } on JNAPError catch (e) {
      if (e.result == errorJNAPUnauthorized) {
        logger.w('[PnP]: Auto Master status check unauthorized');
        throw ExceptionAutoMasterUnauthorized();
      }
      logger.d('[PnP]: GetAutoMasterStatus not supported or failed: $e');
      return null;
    } catch (e) {
      logger.d('[PnP]: GetAutoMasterStatus not supported or failed: $e');
      return null;
    }
  }

  @override
  Stream<AutoMasterStatus?> pollAutoMasterStatus() {
    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
          action: JNAPAction.getAutoMasterStatus,
          auth: true,
          maxRetry: 60,
          retryDelayInMilliSec: 5000,
          firstDelayInMilliSec: 1000,
          condition: (result) {
            if (result is JNAPSuccess) {
              final status = AutoMasterStatus.fromValue(
                  result.output['autoMasterStatus'] as String?);
              return status == AutoMasterStatus.complete ||
                  status == AutoMasterStatus.idle;
            }
            return false;
          },
          onCompleted: (exceedMaxRetry) {
            logger.d(
                '[PnP]: Auto Master polling done, exceeded max: $exceedMaxRetry');
          },
        )
        .map((result) {
      if (result is JNAPSuccess) {
        final status = AutoMasterStatus.fromValue(
            result.output['autoMasterStatus'] as String?);
        logger.d('[PnP]: Auto Master polling status: $status');
        return status;
      }
      return null;
    });
  }

  @override
  void setAutoMasterStatusOnEntry(AutoMasterStatus? status) {
    state = state.copyWith(autoMasterStatusOnEntry: () => status);
  }
}
