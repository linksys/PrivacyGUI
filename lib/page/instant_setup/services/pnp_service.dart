import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/jnap_device_info_raw.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/simple_wifi_settings.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/connectivity/mixin.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pnpServiceProvider = Provider((ref) => PnpService(ref));

enum ConfigStatus { configured, unconfigured }

class ConfigurationResult {
  final ConfigStatus status;
  final String? passwordToUse;

  ConfigurationResult({required this.status, this.passwordToUse});
}

/// A service class responsible for handling business logic and data transformations
/// for the PnP (Plug and Play) flow. It acts as an intermediary between the
/// PnpNotifier and the RouterRepository, converting domain models to UI models.
class PnpService with AvailabilityChecker {
  final Ref _ref;

  JnapDeviceInfoRaw? _rawDeviceInfo;
  Map<JNAPAction, JNAPResult> _rawData = {};

  PnpService(this._ref);

  /// Fetches raw device information and transforms it into a UI-specific model.
  Future<(PnpDeviceInfoUIModel, PnpDeviceCapabilitiesUIModel)> getDeviceInfo(
      [bool clearCurrentSN = true]) async {
    logger.i('[PnP]: Service - Fetching device info...');
    _rawDeviceInfo = await _fetchRawDeviceInfo();

    // Handle SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (clearCurrentSN) {
      await prefs.remove(pCurrentSN);
    }
    await prefs.setString(pPnpConfiguredSN, _rawDeviceInfo!.serialNumber);

    // Pause polling
    _ref.read(pollingProvider.notifier).paused = true;

    // Build/Update better actions
    buildBetterActions(_rawDeviceInfo!.services);

    final capabilities = PnpDeviceCapabilitiesUIModel(
      isGuestWiFiSupported:
          serviceHelper.isSupportGuestNetwork(_rawDeviceInfo!.services),
      isNightModeSupported:
          serviceHelper.isSupportLedMode(_rawDeviceInfo!.services),
      isPnpSupported: serviceHelper.isSupportPnP(_rawDeviceInfo!.services),
    );

    // Asynchronously fetch device mode, but don't wait for it as it's not part of the result
    _ref.read(routerRepositoryProvider).send(JNAPAction.getDeviceMode,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);

    // Apply business logic and transformation to create PnpDeviceInfoUIModel
    final String imageUrl =
        routerIconTestByModel(modelNumber: _rawDeviceInfo!.modelNumber);

    final uiModel = PnpDeviceInfoUIModel(
      modelName: _rawDeviceInfo!.modelNumber,
      image: imageUrl,
      serialNumber: _rawDeviceInfo!.serialNumber,
      firmwareVersion: _rawDeviceInfo!.firmwareVersion,
    );

    logger.i(
        '[PnP]: Service - Fetched device info successfully for ${_rawDeviceInfo!.modelNumber}.');

    return (uiModel, capabilities);
  }

  /// Fetches the raw JnapDeviceInfoRaw from the router repository.
  Future<JnapDeviceInfoRaw> _fetchRawDeviceInfo() async {
    try {
      final result = await _ref.read(routerRepositoryProvider).send(
            JNAPAction.getDeviceInfo,
            type: CommandType.local,
            retries: 10,
            timeoutMs: 3000,
          );
      return JnapDeviceInfoRaw.fromJson(result.output);
    } catch (e) {
      logger.e('[PnP]: Service - Failed to fetch device info.', error: e);
      throw ExceptionFetchDeviceInfo();
    }
  }

  Future<void> checkLoginAndAuthenticateIfNeeded(String? password) async {
    final isLoggedIn = _ref.read(routerRepositoryProvider).isLoggedIn();
    if (!isLoggedIn) {
      logger.i('[PnP]: Service - Not logged in, checking admin password.');
      await checkAdminPassword(password);
    }
  }

  /// Validates the admin password against the router.
  Future<bool> checkAdminPassword(String? password) async {
    logger.i('[PnP]: Service - Checking admin password.');
    if (password == null) {
      logger.w('[PnP]: Service - Admin password is null.');
      throw ExceptionInvalidAdminPassword();
    }
    await _ref
        .read(authProvider.notifier)
        .localLogin(password, pnp: true, guardError: false)
        .then((value) {
      logger.i('[PnP]: Service - Admin password accepted.');
      return true;
    }).catchError((error) {
      logger.e('[PnP]: Service - Admin password check failed.', error: error);
      throw ExceptionInvalidAdminPassword();
    },
            test: (error) =>
                error is JNAPError && error.result == errorJNAPUnauthorized);
    return false; // Should not reach here if successful or error is thrown
  }

  /// Checks for a live internet connection.
  Future<bool> checkInternetConnection([int retries = 1]) async {
    Future<bool> isInternetConnected() async {
      bool isConnected = false;
      for (int i = 0; i < retries; i++) {
        logger.d(
            '[PnP]: Service - Checking internet connection (Attempt ${i + 1}/$retries)');
        isConnected = await _ref
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
          logger.i('[PnP]: Service - Internet connection detected.');
          break;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      return isConnected;
    }

    final isOnline = await isInternetConnected();
    if (!isOnline) {
      logger.e('[PnP]: Service - No internet connection after all retries.');
      throw ExceptionNoInternetConnection();
    }
    return true;
  }

  /// Checks if the router is in an unconfigured (factory default) state.
  Future<ConfigurationResult> checkRouterConfigured() async {
    logger.d('[PnP]: Service - Checking if router is configured...');
    final repo = _ref.read(routerRepositoryProvider);
    final isUnconfigured = await repo
        .send(JNAPAction.getDeviceMode, fetchRemote: true)
        .then((value) =>
            (value.output['mode'] ?? 'Unconfigured') == 'Unconfigured');

    if (isUnconfigured) {
      return ConfigurationResult(
        status: ConfigStatus.unconfigured,
        passwordToUse: defaultAdminPassword,
      );
    } else {
      return ConfigurationResult(status: ConfigStatus.configured);
    }
  }

  /// Checks the auto-configuration status of the router.
  ///
  /// Returns an [AutoConfigurationUIModel] containing the auto-configuration
  /// settings, or null if PnP is not supported or an error occurs.
  Future<AutoConfigurationUIModel?> autoConfigurationCheck() async {
    if (!serviceHelper.isSupportPnP(_rawDeviceInfo?.services)) {
      logger.i('[PnP]: Service - The router does NOT support PNP!');
      return null;
    }
    final repo = _ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
      JNAPAction.getAutoConfigurationSettings,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    )
        .then<AutoConfigurationUIModel?>((data) {
      final jnapModel = AutoConfigurationSettings.fromMap(data.output);
      return _convertToUIModel(jnapModel);
    }).onError((error, stackTrace) => null);
    logger.d('[PnP]: Service - Auto Configuration Check result: $result');
    return result;
  }

  /// Converts a JNAP [AutoConfigurationSettings] to an [AutoConfigurationUIModel].
  AutoConfigurationUIModel _convertToUIModel(
      AutoConfigurationSettings jnapModel) {
    return AutoConfigurationUIModel(
      isSupported: jnapModel.isAutoConfigurationSupported,
      userAcknowledged: jnapModel.userAcknowledgedAutoConfiguration,
      method: _convertMethod(jnapModel.autoConfigurationMethod),
    );
  }

  /// Converts JNAP AutoConfigurationMethod to UI AutoConfigurationMethodUI.
  AutoConfigurationMethodUI? _convertMethod(
      AutoConfigurationMethod? jnapMethod) {
    if (jnapMethod == null) return null;
    return switch (jnapMethod) {
      AutoConfigurationMethod.preConfigured =>
        AutoConfigurationMethodUI.preConfigured,
      AutoConfigurationMethod.autoParent =>
        AutoConfigurationMethodUI.autoParent,
    };
  }

  /// Checks if the admin password has been set by the user.
  Future<bool> isRouterPasswordSet() {
    final transaction = JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.isAdminPasswordDefault, {}),
        const MapEntry(JNAPAction.isAdminPasswordSetByUser, {}),
      ],
      auth: true,
    );
    final repo = _ref.read(routerRepositoryProvider);
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
          '[PnP]: Service - Admin password status: isAdminPasswordDefault=$isAdminPasswordDefault, isAdminPasswordSetByUser=$isAdminPasswordSetByUser');
      return !isAdminPasswordDefault || isAdminPasswordSetByUser;
    }).onError((error, stackTrace) {
      logger.e(
          '[PnP]: Service - Error checking if password is set. Assuming true.',
          error: error);
      return true; // error handling - set configured to prevent go to pnp
    });
  }

  /// Fetches all necessary data for the PnP wizard steps.
  Future<PnpDefaultSettingsUIModel> fetchData() async {
    logger.i('[PnP]: Service - Fetching initial data for wizard steps...');
    bool isSupportNodeLight =
        serviceHelper.isSupportLedMode(_rawDeviceInfo?.services);
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
    return _ref
        .read(routerRepositoryProvider)
        .transaction(transaction, fetchRemote: true, retries: 10)
        .then((response) {
      logger.i('[PnP]: Service - Successfully fetched initial data.');
      _rawData = Map.fromEntries(response.data);
      final wifi = getDefaultWiFiNameAndPassphrase();
      final guest = getDefaultGuestWiFiNameAndPassPhrase();
      final uiModel = PnpDefaultSettingsUIModel(
        wifiSsid: wifi.name,
        wifiPassword: wifi.password,
        guestWifiSsid: guest.name,
        guestWifiPassword: guest.password,
      );
      return uiModel;
    });
  }

  /// Tests if the connection to the router has been re-established after a change.
  Future<bool> testConnectionReconnected() async {
    logger.i('[PnP]: Service - Testing connection after settings change...');
    // Test connect to the proper router
    try {
      final result = await _ref.read(routerRepositoryProvider).send(
          JNAPAction.getDeviceInfo,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          retries: 0,
          timeoutMs: 3000);
      final deviceInfo = JnapDeviceInfoRaw.fromJson(result.output).toUIModel();
      final isConnected =
          _rawDeviceInfo?.serialNumber == deviceInfo.serialNumber;
      if (!isConnected) {
        logger.e(
            '[PnP]: Service - Reconnect test failed. Connected to a different router.');
        throw ExceptionNeedToReconnect();
      }
      logger.i('[PnP]: Service - Reconnect test successful.');
      return true;
    } catch (error) {
      logger.e(
          '[PnP]: Service - Could not get device info during reconnect test.',
          error: error);
      throw ExceptionNeedToReconnect();
    }
  }

  /// Fetches the list of connected child nodes.
  Future<List<PnpChildNodeUIModel>> fetchDevices() {
    logger.i('[PnP]: Service - Fetching child nodes...');
    final repo = _ref.read(routerRepositoryProvider);
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
          .map((e) => PnpChildNodeUIModel(
              location: e.getDeviceLocation(),
              modelNumber: e.modelNumber ?? ''))
          .toList();
      logger.i('[PnP]: Service - Found ${deviceList.length} child nodes.');
      return deviceList;
    });
  }

  //region Save Logic
  //----------------------------------------------------------------------------

  Future<void> savePnpSettings(PnpState currentState) async {
    logger.i('[PnP]: Service - Starting save process...');
    final prefs = await SharedPreferences.getInstance();
    if (currentState.deviceInfo != null) {
      prefs.setString(pPnpConfiguredSN, currentState.deviceInfo!.serialNumber);
    }

    // 1. Build payloads using helper methods
    final commands = [
      _buildPersonalWiFiPayload(currentState),
      _buildGuestWiFiPayload(currentState),
      _buildNightModePayload(currentState),
      _buildFirmwareUpdatePayload(),
      if (currentState.isRouterUnConfigured)
        const MapEntry(JNAPAction.setDeviceMode, {'mode': 'Master'}),
      _buildCloseCommandPayload(currentState),
    ].nonNulls.toList(); // Filter out nulls (no changes needed)

    // 2. Build the transaction
    final transaction = JNAPTransactionBuilder(commands: commands, auth: true);
    logger.i(
        '[PnP]: Service - Sending save transaction with ${transaction.commands.length} commands.');

    // 3. Execute transaction and handle post-save flow
    await _ref
        .read(routerRepositoryProvider)
        .transaction(
          transaction,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          pollConfig:
              const SideEffectPollConfig(maxRetry: 18, retryDelayInSec: 10),
        )
        .catchError((error) {
      logger.e(
          '[PnP]: Service - Connection changed during save. Need to reconnect.',
          error: error);
      throw ExceptionNeedToReconnect();
    },
            test: (error) =>
                error is ClientException ||
                error is ServiceSideEffectError).onError((error, stackTrace) {
      if (error is ExceptionNeedToReconnect) {
        throw error;
      }
      // Saving error
      logger.e('[PnP]: Service - Save transaction failed.', error: error);
      throw ExceptionSavingChanges(error);
    }).then((_) async {
      logger.i(
          '[PnP]: Service - Save transaction successful. Waiting for reconnect test.');
      await Future.delayed(const Duration(seconds: 3));
    }).then((_) {
      final password = getDefaultWiFiNameAndPassphrase().password;
      return testConnectionReconnected()
          .then((_) => checkAdminPassword(password));
    }).whenComplete(() {
      logger.i('[PnP]: Service - Save flow complete. Removing PnP SN.');
      prefs.remove(pPnpConfiguredSN);
    });
  }

  Map<String, dynamic>? _getData(JNAPAction action) {
    return (_rawData[action] as JNAPSuccess?)?.output;
  }

  PnpStepState _getStepState(PnpState pnpState, PnpStepId stepId) {
    return pnpState.stepStateList[stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
  }

  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    String? name, passphrase, security;
    final getRadioInfoJson =
        (_rawData[JNAPAction.getRadioInfo] as JNAPSuccess?)?.output;
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

  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    String? name, passphrase;
    final guestRadioSettingsJson =
        (_rawData[JNAPAction.getGuestRadioSettings] as JNAPSuccess?)?.output;
    if (guestRadioSettingsJson != null) {
      final guestRadioSettings =
          GuestRadioSettings.fromMap(guestRadioSettingsJson);
      final radios = guestRadioSettings.radios;
      name = radios.firstOrNull?.guestSSID;
      passphrase = radios.firstOrNull?.guestWPAPassphrase;
    }
    return (name: name ?? '', password: passphrase ?? '');
  }

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildPersonalWiFiPayload(
      PnpState pnpState) {
    final defaultWiFi = getDefaultWiFiNameAndPassphrase();
    final wifiStateData = _getStepState(pnpState, PnpStepId.personalWifi).data;
    final wifiName = wifiStateData['ssid'] as String? ?? defaultWiFi.name;
    final wifiPassphase =
        wifiStateData['password'] as String? ?? defaultWiFi.password;

    final isWiFiChanged =
        wifiName != defaultWiFi.name || wifiPassphase != defaultWiFi.password;
    logger.d('[PnP]: Service - Wi-Fi changed: $isWiFiChanged');

    if (!isWiFiChanged) return null;

    final simpleWiFiSettingsJson =
        _getData(JNAPAction.getSimpleWiFiSettings) ?? {};
    final settingsList = simpleWiFiSettingsJson['simpleWiFiSettings'];
    if (settingsList is! List) {
      return null;
    }

    final simpleWiFiSettings = settingsList
        .map((e) => SimpleWiFiSettings.fromMap(e).copyWith(
            ssid: wifiName,
            passphrase: wifiPassphase,
            security: defaultWiFi.security))
        .toList();

    return MapEntry(JNAPAction.setSimpleWiFiSettings, {
      'simpleWiFiSettings': simpleWiFiSettings.map((e) => e.toMap()).toList()
    });
  }

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildGuestWiFiPayload(
      PnpState pnpState) {
    final isGuestWiFiSupport =
        serviceHelper.isSupportGuestNetwork(_rawDeviceInfo?.services);
    if (!isGuestWiFiSupport) return null;

    final defaultGuestWiFi = getDefaultGuestWiFiNameAndPassPhrase();
    final guestWifiStateData =
        _getStepState(pnpState, PnpStepId.guestWifi).data;
    final isGuestEnabled = guestWifiStateData['isEnabled'] as bool? ?? false;
    logger.d('[PnP]: Service - Guest Wi-Fi will be enabled: $isGuestEnabled');

    final guestWiFiName =
        guestWifiStateData['ssid'] as String? ?? defaultGuestWiFi.name;
    final guestWiFiPassphase =
        guestWifiStateData['password'] as String? ?? defaultGuestWiFi.password;
    final guestWifiRadioSettingsJson =
        _getData(JNAPAction.getGuestRadioSettings) ?? {};
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

  MapEntry<JNAPAction, Map<String, dynamic>>? _buildNightModePayload(
      PnpState pnpState) {
    final isNightModeSupport =
        serviceHelper.isSupportLedMode(_rawDeviceInfo?.services);
    final nightModeStateData =
        _getStepState(pnpState, PnpStepId.nightMode).data;
    final isNightModeEnabled =
        nightModeStateData['isEnabled'] as bool? ?? false;
    logger
        .d('[PnP]: Service - Night mode will be enabled: $isNightModeEnabled');

    if (!isNightModeSupport || !isNightModeEnabled) return null;

    var nightModeSettings =
        NodeLightSettings(isNightModeEnable: isNightModeEnabled);
    if (isNightModeEnabled) {
      nightModeSettings = nightModeSettings.copyWith(startHour: 20, endHour: 8);
    }
    return MapEntry(
        JNAPAction.setLedNightModeSetting, nightModeSettings.toMap());
  }

  MapEntry<JNAPAction, Map<String, dynamic>> _buildFirmwareUpdatePayload() {
    final firmwareUpdateSettingsJson =
        _getData(JNAPAction.getFirmwareUpdateSettings);
    final firmwareUpdateSettings = firmwareUpdateSettingsJson != null
        ? FirmwareUpdateSettings.fromMap(firmwareUpdateSettingsJson)
            .copyWith(
                updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto)
            .toMap()
        : <String, dynamic>{};
    return MapEntry(
        JNAPAction.setFirmwareUpdateSettings, firmwareUpdateSettings);
  }

  MapEntry<JNAPAction, Map<String, dynamic>> _buildCloseCommandPayload(
      PnpState pnpState) {
    final defaultWiFi = getDefaultWiFiNameAndPassphrase();
    final closeCommand = pnpState.isRouterUnConfigured
        ? JNAPAction.pnpSetAdminPassword
        : JNAPAction.setUserAcknowledgedAutoConfiguration;
    final closeData = pnpState.isRouterUnConfigured
        ? {'adminPassword': defaultWiFi.password}
        : <String, dynamic>{};
    return MapEntry(closeCommand, closeData);
  }

  /// Validates a map of data against a map of validation rules.
  /// Returns a map of field names to error messages. If a field is valid, its entry will be null.
  Map<String, String?> validate(
      Map<String, dynamic> data, Map<String, List<ValidationRule>> rules) {
    final errors = <String, String?>{};
    for (final field in rules.keys) {
      for (final rule in rules[field]!) {
        if (!rule.validate(data[field])) {
          errors[field] =
              rule.name; // Use the rule's class name as the error code
          break;
        }
      }
    }
    return errors;
  }

  //endregion

  Future<bool> checkForFirmwareUpdate() async {
    final fwUpdate = _ref.read(firmwareUpdateProvider.notifier);
    logger.i('[PnP]: Service - Checking for firmware updates...');
    await fwUpdate.fetchAvailableFirmwareUpdates();
    final hasNewFW = fwUpdate.getAvailableUpdateNumber() > 0;
    if (hasNewFW) {
      logger.i('[PnP]: Service - New firmware found! Starting update...');
      await fwUpdate.updateFirmware();
      return true;
    } else {
      logger.i('[PnP]: Service - No new firmware.');
      return false;
    }
  }

  void forcePollingOnLocalLogin() {
    if (_ref.read(authProvider).value?.loginType == LoginType.local) {
      logger.i('[PnP]: Service - Forcing polling for local login.');
      _ref.read(pollingProvider.notifier).forcePolling();
    }
  }
}
