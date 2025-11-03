import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';

/// Base Mock Notifier with common simulation logic for PnP flows.
/// This class extends [BasePnpNotifier] and provides mock implementations
/// for various PnP operations, useful for testing and UI development.
class BaseMockPnpNotifier extends BasePnpNotifier {
  /// Sets the current status of the PnP flow.
  void setStatus(PnpFlowStatus status) {
    state = state.copyWith(status: status);
  }

  /// Simulates an asynchronous operation with a delay, updating the PnP flow status.
  Future<void> _simulate(PnpFlowStatus newStatus,
      {int seconds = 1, Object? error, String? loadingMessage}) async {
    logger.d(
        '[PnP]: Mock - Simulating state change to $newStatus after $seconds second(s)');
    await Future.delayed(Duration(seconds: seconds));
    // Only update if the state hasn't transitioned to an admin error in the meantime.
    if (state.status != PnpFlowStatus.adminError) {
      state = state.copyWith(
          status: newStatus, error: error, loadingMessage: loadingMessage);
    }
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    logger.d('[PnP]: Mock - startPnpFlow called');
    // Mock implementation: does nothing by default, specific mocks override this.
  }

  @override
  Future<void> submitPassword(String password) async {
    logger.d('[PnP]: Mock - submitPassword called');
    await _simulate(PnpFlowStatus.adminLoggingIn);
    if (password == 'password') {
      await _simulate(PnpFlowStatus.wizardInitializing);
    } else {
      await _simulate(PnpFlowStatus.adminLoginFailed,
          error: ExceptionInvalidAdminPassword());
    }
  }

  @override
  Future<void> continueFromUnconfigured() async {
    logger.d('[PnP]: Mock - continueFromUnconfigured called');
    await _simulate(PnpFlowStatus.adminCheckingInternet);
    await _simulate(PnpFlowStatus.wizardInitializing);
  }

  @override
  Future<void> initializeWizard() async {
    logger.d('[PnP]: Mock - initializeWizard called');
    state = state.copyWith(
        status: PnpFlowStatus.wizardInitializing,
        loadingMessage: 'Collecting data');
    state = state.copyWith(
        defaultSettings: const PnpDefaultSettingsUIModel(
      wifiSsid: 'Mock-WiFi',
      wifiPassword: 'mock-password',
      guestWifiSsid: 'Mock-Guest',
      guestWifiPassword: 'mock-guest-password',
    ));
    await _simulate(PnpFlowStatus.wizardConfiguring);
  }

  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock - savePnpSettings called');
    // Mock implementation: does nothing by default, specific mocks override this.
  }

  @override
  Future<void> testPnpReconnect() async {
    logger.d('[PnP]: Mock - testPnpReconnect called');
    // Mock implementation: does nothing by default, specific mocks override this.
  }

  @override
  Future<void> completeFwCheck() async {
    logger.d('[PnP]: Mock - completeFwCheck called');
    await _simulate(PnpFlowStatus.wizardWifiReady);
  }

  @override
  Future<void> checkAdminPassword(String? password) {
    logger.d('[PnP]: Mock - checkAdminPassword called');
    return Future.value();
  }

  @override
  Future<void> checkInternetConnection([int retries = 1]) {
    logger.d('[PnP]: Mock - checkInternetConnection called');
    return Future.value();
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) {
    logger.d('[PnP]: Mock - fetchDeviceInfo called');
    state = state.copyWith(
        deviceInfo: const PnpDeviceInfoUIModel(
            serialNumber: 'mock-serial',
            firmwareVersion: 'mock-model',
            modelName: 'mock-model',
            image: ''),
        capabilities: const PnpDeviceCapabilitiesUIModel(
          isGuestWiFiSupported: true,
          isNightModeSupported: true,
          isPnpSupported: true,
        ));
    return Future.value();
  }

  @override
  Future<ConfigurationResult> checkRouterConfigured() async {
    logger.d('[PnP]: Mock - checkRouterConfigured called');
    return ConfigurationResult(status: ConfigStatus.configured);
  }

  @override
  Future<bool> isRouterPasswordSet() {
    logger.d('[PnP]: Mock - isRouterPasswordSet called');
    return Future.value(true);
  }

  @override
  Future<void> testConnectionReconnected() {
    logger.d('[PnP]: Mock - testConnectionReconnected called');
    return Future.value();
  }

  /// Optional mock child nodes to be returned by [fetchDevices].
  List<PnpChildNodeUIModel>? mockChildNodes;

  /// Flag to simulate an error during [fetchDevices].
  bool shouldThrowFetchDevicesError = false;

  @override
  Future<List<PnpChildNodeUIModel>> fetchDevices() async {
    logger.d('[PnP]: Mock - fetchDevices called');
    if (shouldThrowFetchDevicesError) {
      throw Exception('Mock fetchDevices error');
    }
    await Future.delayed(const Duration(milliseconds: 10));
    return mockChildNodes ?? [];
  }

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    logger.d('[PnP]: Mock - autoConfigurationCheck called');
    // Default to configured, acknowledged
    return Future.value(const AutoConfigurationSettings(
      isAutoConfigurationSupported: true,
      userAcknowledgedAutoConfiguration: true,
      autoConfigurationMethod: AutoConfigurationMethod.preConfigured,
    ));
  }

  @override
  void setAttachedPassword(String? password) {
    logger.d('[PnP]: Mock - setAttachedPassword called');
    state = state.copyWith(attachedPassword: password);
  }

  @override
  void setForceLogin(bool force) {
    logger.d('[PnP]: Mock - setForceLogin called');
    state = state.copyWith(forceLogin: force);
  }

  @override
  void setStepData(PnpStepId stepId, {required Map<String, dynamic> data}) {
    final currentStepState = state.stepStateList[stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});

    // Merge old data with new data
    final newData = Map<String, dynamic>.from(currentStepState.data)
      ..addAll(data);

    final newStepState = currentStepState.copyWith(data: newData);

    final newStepStateList =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    newStepStateList[stepId] = newStepState;

    state = state.copyWith(stepStateList: newStepStateList);
  }

  @override
  void validateStep(PnpStep step) {
    logger.d('[PnP]: Mock - validateStep called for step: ${step.stepId}');

    final validationData = step.getValidationData();

    final validationRules = step.getValidationRules();

    logger.d('GuestWiFiTest: validationData: $validationData');

    logger.d('GuestWiFiTest: validationRules keys: ${validationRules.keys}');

    final errors = <String, String?>{};

    var isStepValid = true;

    validationRules.forEach((field, rules) {
      final value = validationData[field]?.toString() ?? '';

      errors[field] = null; // Default to no error

      for (final rule in rules) {
        final bool isValidForRule = rule.validate(value);

        if (!isValidForRule) {
          errors[field] = 'Invalid input (failed ${rule.name})';

          isStepValid = false;

          break; // Stop at the first error for the field
        }
      }
    });

    logger.d('GuestWiFiTest: isStepValid computed: $isStepValid');

    final currentStepState = state.stepStateList[step.stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});

    final newStatus = isStepValid ? StepViewStatus.data : StepViewStatus.error;

    final newStepState = currentStepState.copyWith(
      status: newStatus,
      error: errors,
    );

    final newStepStateList =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);

    newStepStateList[step.stepId] = newStepState;

    state = state.copyWith(stepStateList: newStepStateList);
  }

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    logger.d('[PnP]: Mock - getDefaultWiFiNameAndPassphrase called');
    return (
      name: state.defaultSettings?.wifiSsid ?? 'Mock-WiFi',
      password: state.defaultSettings?.wifiPassword ?? 'mock-password',
      security: 'WPA2'
    );
  }

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    logger.d('[PnP]: Mock - getDefaultGuestWiFiNameAndPassPhrase called');
    return (
      name: state.defaultSettings?.guestWifiSsid ?? 'Mock-Guest',
      password:
          state.defaultSettings?.guestWifiPassword ?? 'mock-guest-password'
    );
  }
}

/// --- Scenario: Unconfigured Router (Factory Reset) ---
/// Mock notifier for simulating an unconfigured router scenario.
final unconfiguredPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => UnconfiguredMockPnpNotifier());

class UnconfiguredMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    logger.d('[PnP]: Mock (Unconfigured) - autoConfigurationCheck called');
    return Future.value(const AutoConfigurationSettings(
      isAutoConfigurationSupported: true,
      userAcknowledgedAutoConfiguration: false, // This triggers PnP
      autoConfigurationMethod: AutoConfigurationMethod.preConfigured,
    ));
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    final configResult = await checkRouterConfigured();
    setAttachedPassword(configResult.passwordToUse);
    state = state.copyWith(status: PnpFlowStatus.adminUnconfigured);
  }

  @override
  Future<ConfigurationResult> checkRouterConfigured() async {
    logger.d('[PnP]: Mock (Unconfigured) - checkRouterConfigured called');
    state = state.copyWith(isUnconfigured: true);
    return ConfigurationResult(
        status: ConfigStatus.unconfigured, passwordToUse: defaultAdminPassword);
  }

  @override
  Future<bool> isRouterPasswordSet() {
    logger.d('[PnP]: Mock (Unconfigured) - isRouterPasswordSet called');
    return Future.value(false);
  }

  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock (Unconfigured) - savePnpSettings called');
    state = state.copyWith(
        status: PnpFlowStatus.wizardSaving, loadingMessage: 'Saving changes');
    await _simulate(PnpFlowStatus.wizardSaved, seconds: 1);
    await _simulate(PnpFlowStatus.wizardNeedsReconnect, seconds: 1);
  }

  @override
  Future<void> testPnpReconnect() async {
    logger.d('[PnP]: Mock (Unconfigured) - testPnpReconnect called');
    await _simulate(PnpFlowStatus.wizardConfiguring, seconds: 2);
  }

  @override
  Future<List<PnpChildNodeUIModel>> fetchDevices() {
    logger.d('[PnP]: Mock (Unconfigured) - fetchDevices called');
    if (shouldThrowFetchDevicesError) {
      throw Exception('Mock fetchDevices error');
    }
    final mockNodes = [
      const PnpChildNodeUIModel(location: 'Living Room', modelNumber: 'MX4200'),
      const PnpChildNodeUIModel(location: 'Bedroom', modelNumber: 'MX4200'),
      const PnpChildNodeUIModel(location: 'Office', modelNumber: 'MX4200'),
    ];
    state = state.copyWith(childNodes: mockNodes);
    return Future.value(mockNodes);
  }
}

/// --- Scenario: Already Configured Router (Standard Flow) ---
/// Mock notifier for simulating a standard PnP flow with an already configured router.
final configuredPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => ConfiguredMockPnpNotifier());

class ConfiguredMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminAwaitingPassword);
  }

  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock (Configured) - savePnpSettings called');
    state = state.copyWith(
        status: PnpFlowStatus.wizardSaving, loadingMessage: 'Saving changes');
    await _simulate(PnpFlowStatus.wizardSaved, seconds: 1);
    await _simulate(PnpFlowStatus.wizardCheckingFirmware, seconds: 1);
    await _simulate(PnpFlowStatus.wizardWifiReady, seconds: 2);
  }
}

/// --- Scenario: Mandatory Firmware Update ---
/// Mock notifier for simulating a PnP flow that requires a firmware update.
final fwUpdatePnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => FwUpdateMockPnpNotifier());

class FwUpdateMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    logger.d('[PnP]: Mock (FW Update) - autoConfigurationCheck called');
    return Future.value(const AutoConfigurationSettings(
      isAutoConfigurationSupported: true,
      userAcknowledgedAutoConfiguration: false, // This triggers PnP
      autoConfigurationMethod: AutoConfigurationMethod.preConfigured,
    ));
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminAwaitingPassword);
  }

  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock (FW Update) - savePnpSettings called');
    await _simulate(PnpFlowStatus.wizardSaving,
        seconds: 1, loadingMessage: 'Saving changes');
    await _simulate(PnpFlowStatus.wizardSaved, seconds: 1);
    await _simulate(PnpFlowStatus.wizardCheckingFirmware,
        seconds: 1, loadingMessage: 'Checking for updates...');
    await _simulate(PnpFlowStatus.wizardUpdatingFirmware,
        seconds: 3, loadingMessage: 'Updating firmware...');
    // In a real scenario, a listener on firmwareUpdateProvider would trigger the next step.
    // Here, we'll just move to the end state.
    await completeFwCheck();
  }
}

/// --- Scenario: Unconfigured Router with Mandatory Firmware Update ---
/// Mock notifier for simulating an unconfigured router that also requires a firmware update.
final unconfiguredFwUpdatePnpProvider =
    NotifierProvider<BasePnpNotifier, PnpState>(
        () => UnconfiguredFwUpdateMockPnpNotifier());

class UnconfiguredFwUpdateMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    logger.d(
        '[PnP]: Mock (Unconfigured FW Update) - autoConfigurationCheck called');
    return Future.value(const AutoConfigurationSettings(
      isAutoConfigurationSupported: true,
      userAcknowledgedAutoConfiguration: false, // This triggers PnP
      autoConfigurationMethod: AutoConfigurationMethod.preConfigured,
    ));
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    final configResult = await checkRouterConfigured();
    setAttachedPassword(configResult.passwordToUse);
    state = state.copyWith(status: PnpFlowStatus.adminUnconfigured);
  }

  @override
  Future<ConfigurationResult> checkRouterConfigured() async {
    logger.d(
        '[PnP]: Mock (Unconfigured FW Update) - checkRouterConfigured called');
    state = state.copyWith(isUnconfigured: true);
    return ConfigurationResult(
        status: ConfigStatus.unconfigured, passwordToUse: defaultAdminPassword);
  }

  @override
  Future<bool> isRouterPasswordSet() {
    logger
        .d('[PnP]: Mock (Unconfigured FW Update) - isRouterPasswordSet called');
    return Future.value(false);
  }

  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock (Unconfigured FW Update) - savePnpSettings called');
    state = state.copyWith(
        status: PnpFlowStatus.wizardSaving, loadingMessage: 'Saving changes');
    await _simulate(PnpFlowStatus.wizardSaved, seconds: 1);
    await _simulate(PnpFlowStatus.wizardCheckingFirmware,
        seconds: 1, loadingMessage: 'Checking for updates...');
    await _simulate(PnpFlowStatus.wizardUpdatingFirmware,
        seconds: 3, loadingMessage: 'Updating firmware...');
    await _simulate(PnpFlowStatus.wizardNeedsReconnect, seconds: 1);
  }
}

/// --- Scenario: No Internet Connection ---
/// Mock notifier for simulating a scenario where there is no internet connection.
final noInternetPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => NoInternetMockPnpNotifier());

class NoInternetMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> checkInternetConnection([int retries = 1]) async {
    logger.d('[PnP]: Mock (No Internet) - checkInternetConnection called');
    await _simulate(
      PnpFlowStatus.adminNeedsInternetTroubleshooting,
      seconds: 1,
      error: ExceptionNoInternetConnection(),
    );
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    final configResult = await checkRouterConfigured();
    setAttachedPassword(configResult.passwordToUse);
    state = state.copyWith(status: PnpFlowStatus.adminUnconfigured);
  }

  @override
  Future<void> continueFromUnconfigured() async {
    logger.d('[PnP]: Mock (No Internet) - continueFromUnconfigured called');
    await _simulate(PnpFlowStatus.adminCheckingInternet);
    await checkInternetConnection();
  }

  @override
  Future<ConfigurationResult> checkRouterConfigured() async {
    logger.d('[PnP]: Mock (No Internet) - checkRouterConfigured called');
    state = state.copyWith(isUnconfigured: true);
    return ConfigurationResult(
        status: ConfigStatus.unconfigured, passwordToUse: defaultAdminPassword);
  }

  @override
  Future<bool> isRouterPasswordSet() {
    logger.d('[PnP]: Mock (No Internet) - isRouterPasswordSet called');
    return Future.value(false);
  }
}

/// --- Scenario: Admin Error (e.g., Fetch Device Info Failed) ---
/// Mock notifier for simulating an administrative error, such as failing to fetch device information.
final adminErrorPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => AdminErrorMockPnpNotifier());

class AdminErrorMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {
    logger.d('[PnP]: Mock (Admin Error) - fetchDeviceInfo called');
    await _simulate(PnpFlowStatus.adminError,
        error: ExceptionFetchDeviceInfo());
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    try {
      await fetchDeviceInfo();
    } catch (e) {
      state = state.copyWith(status: PnpFlowStatus.adminError, error: e);
    }
  }
}

/// --- Scenario: Wizard Initialization Failed ---
/// Mock notifier for simulating a failure during the wizard initialization phase.
final wizardInitFailedPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => WizardInitFailedMockPnpNotifier());

class WizardInitFailedMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> initializeWizard() async {
    logger.d('[PnP]: Mock (Wizard Init Failed) - initializeWizard called');
    await _simulate(PnpFlowStatus.wizardInitializing,
        loadingMessage: 'Collecting data');
    await _simulate(PnpFlowStatus.wizardInitFailed,
        error: Exception('Failed to fetch initial router data for wizard.'));
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminInternetConnected);
  }
}

/// --- Scenario: Wizard Save Failed ---
/// Mock notifier for simulating a failure during the saving of wizard settings.
final wizardSaveFailedPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => WizardSaveFailedMockPnpNotifier());

class WizardSaveFailedMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> savePnpSettings() async {
    logger.d('[PnP]: Mock (Wizard Save Failed) - savePnpSettings called');
    await _simulate(PnpFlowStatus.wizardSaving,
        loadingMessage: 'Saving changes');
    await _simulate(PnpFlowStatus.wizardSaveFailed,
        error: ExceptionSavingChanges('Mock save failed'));
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminInternetConnected);
  }
}

/// --- Scenario: Reconnect Failed ---
/// Mock notifier for simulating a failure to reconnect to the router after a settings change.
final reconnectFailedPnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => ReconnectFailedMockPnpNotifier());

class ReconnectFailedMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> testPnpReconnect() async {
    logger.d('[PnP]: Mock (Reconnect Failed) - testPnpReconnect called');
    await _simulate(PnpFlowStatus.wizardNeedsReconnect,
        error: ExceptionNeedToReconnect());
  }

  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminInternetConnected);
  }
}

/// --- Scenario: Already Internet Connected (Direct to Wizard) ---
/// Mock notifier for simulating a scenario where the internet is already connected,
/// leading directly to the wizard.
final internetConnectedPnpProvider =
    NotifierProvider<BasePnpNotifier, PnpState>(
        () => InternetConnectedMockPnpNotifier());

class InternetConnectedMockPnpNotifier extends BaseMockPnpNotifier {
  @override
  Future<void> startPnpFlow(String? password) async {
    super.startPnpFlow(password);
    await _simulate(PnpFlowStatus.adminInitializing, seconds: 0);
    await fetchDeviceInfo();
    await _simulate(PnpFlowStatus.adminInternetConnected);
  }
}
