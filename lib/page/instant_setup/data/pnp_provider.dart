import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/simple_wifi_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
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

  Future fetchDeviceInfo();
  Future checkAdminPassword(String? password);
  Future checkInternetConnection([int retries = 1]);
  Future checkRouterConfigured();
  Future<bool> pnpCheck();
  Future<bool> isRouterPasswordSet();
  Future fetchData();
  Future save();
  Future testConnectionReconnected();
  Future fetchDevices();
  void setForceLogin(bool force);
  void setAttachedPassword(String? password);

  // Personal WiFi
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase();
  // Guest WiFi
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase();
}

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
  Future fetchDeviceInfo() {
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> pnpCheck() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => true);
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
}

class PnpNotifier extends BasePnpNotifier with AvailabilityChecker {
  @override
  Future fetchDeviceInfo() async {
    final deviceInfo = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getDeviceInfo,
          type: CommandType.local,
          fetchRemote: true,
          retries: 0,
          timeoutMs: 3000,
        )
        .then((result) => NodeDeviceInfo.fromJson(result.output));
    // check current sn and clear it
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(pCurrentSN);
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
    final isNode = isNodeModel(
        modelNumber: state.deviceInfo?.modelNumber ?? '',
        hardwareVersion: state.deviceInfo?.hardwareVersion ?? '1');
    // getInternetConnectionStatus for Node router
    Future<bool> isInternetConnected() async {
      bool isConnected = false;
      for (int i = 0; i < retries; i++) {
        logger.i(
            '[PnP]: Check internet connections MAX retries <$retries>, i=$i');
        isConnected = await ref
            .read(routerRepositoryProvider)
            .send(JNAPAction.getInternetConnectionStatus,
                auth: true, retries: 0)
            .then((result) {
          return result.output['connectionStatus'] == 'InternetConnected';
        });
        if (isConnected) {
          break;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      return isConnected;
    }

    Future<bool> testPing() => ref.read(cloudRepositoryProvider).testPingPng();
    final isOnline = isNode ? await isInternetConnected() : await testPing();
    // final isOnline = await testPing();
    if (!isOnline) {
      throw ExceptionNoInternetConnection();
    }
    return true;
  }

  @override
  Future<bool> pnpCheck() async {
    if (!serviceHelper.isSupportPnP(state.deviceInfo?.services)) {
      logger.i('[PnP]: The router does NOT support PNP!');
      return false;
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
          JNAPAction.getAutoConfigurationSettings,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then((data) =>
            data.output['isAutoConfigurationSupported'] &&
            !data.output['userAcknowledgedAutoConfiguration'])
        .onError((error, stackTrace) =>
            false); // error handling - set false to prevent go into pnp
    logger.d('[PnP]: PnP check result: $result');
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
  Future fetchData() {
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

  @override
  Future save() async {
    // store current configured SN
    final deviceInfo = state.deviceInfo;
    final prefs = await SharedPreferences.getInstance();
    if (deviceInfo != null) {
      prefs.setString(pPnpConfiguredSN, deviceInfo.serialNumber);
    }
    // processing data
    final defaultWiFi = getDefaultWiFiNameAndPassphrase();
    final defaultGuestWiFi = getDefaultGuestWiFiNameAndPassPhrase();
    // if configured call setUserAcknowledgedAutoConfiguration else call setAdminPassword
    final closeCommand = state.isRouterUnConfigured
        ? JNAPAction.pnpSetAdminPassword
        : JNAPAction.setUserAcknowledgedAutoConfiguration;
    final closeData = state.isRouterUnConfigured
        ? {'adminPassword': defaultWiFi.password}
        : <String, dynamic>{};
    // personal wifi
    final wifiStateData = getStepState(0).data;
    final wifiName = wifiStateData['ssid'] as String? ?? defaultWiFi.name;
    final wifiPassphase =
        wifiStateData['password'] as String? ?? defaultWiFi.password;
    final simpleWiFiSettingsJson =
        getData(JNAPAction.getSimpleWiFiSettings) ?? {};
    final simpleWiFiSettings =
        List.from(simpleWiFiSettingsJson['simpleWiFiSettings'])
            .map((e) => SimpleWiFiSettings.fromMap(e).copyWith(
                ssid: wifiName,
                passphrase: wifiPassphase,
                security: defaultWiFi.security))
            .toList();

    final isWiFiChanged =
        wifiName != defaultWiFi.name || wifiPassphase != defaultWiFi.password;
    // guest wifi
    final guestWifiStateData = getStepState(1).data;
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
    final nightModeStateData = getStepState(2).data;
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
      MapEntry(closeCommand, closeData),
      if (isWiFiChanged)
        MapEntry(JNAPAction.setSimpleWiFiSettings, {
          'simpleWiFiSettings':
              simpleWiFiSettings.map((e) => e.toMap()).toList()
        }),
      // if (isGuestEnabled)
      MapEntry(JNAPAction.setGuestRadioSettings, setGuestRadioSettings.toMap()),
      if (isNightModeEnabled)
        MapEntry(JNAPAction.setLedNightModeSetting, nightModeSettings.toMap()),
      MapEntry(JNAPAction.setFirmwareUpdateSettings, firmwareUpdateSettings),
      if (state.isRouterUnConfigured)
        const MapEntry(JNAPAction.setDeviceMode, {'mode': 'Master'})
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
        .then((_) => checkAdminPassword(defaultWiFi.password))
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
  Future checkRouterConfigured() async {
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
          .where((device) => device.nodeType != null)
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
}
