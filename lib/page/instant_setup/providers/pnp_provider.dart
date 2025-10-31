import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import '../troubleshooter/providers/pnp_troubleshooter_provider.dart';

/// The main Riverpod provider for the PnP feature.
final pnpProvider = NotifierProvider<BasePnpNotifier, PnpState>(
    () => NoInternetMockPnpNotifier());

/// Abstract base class for the PnP Notifier.
/// Defines the contract for all actions that can be performed during the PnP flow.
abstract class BasePnpNotifier extends Notifier<PnpState> {
  @override
  PnpState build() => const PnpState(status: PnpFlowStatus.adminInitializing);

  //region Step State Management
  //----------------------------------------------------------------------------

  /// Gets the state for a specific step by its ID.
  PnpStepState getStepState(PnpStepId stepId) {
    return state.stepStateList[stepId] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
  }

  /// Sets the entire state for a specific step.
  void setStepState(PnpStepId stepId, PnpStepState stepState) {
    final stepStateData =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    stepStateData[stepId] = stepState;
    state = state.copyWith(stepStateList: stepStateData);
  }

  /// Updates the status of a specific step.
  void setStepStatus(PnpStepId stepId, {required StepViewStatus status}) {
    final stepStateData =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(status: status);
    state = state.copyWith(stepStateList: stepStateData);
  }

  /// Merges new data into a specific step's state.
  void setStepData(PnpStepId stepId, {required Map<String, dynamic> data}) {
    final stepStateData =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(
        data: Map.fromEntries(target.data.entries)..addAll(data));
    state = state.copyWith(stepStateList: stepStateData);
    logger.d('[PnP]: Set step <$stepId> data - ${state.stepStateList[stepId]}');
  }

  /// Sets an error object for a specific step.
  void setStepError(PnpStepId stepId, {Object? error}) {
    final stepStateData =
        Map<PnpStepId, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[stepId] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[stepId] = target.copyWith(error: error);
    state = state.copyWith(stepStateList: stepStateData);
  }

  //endregion

  //region Abstract Methods
  //----------------------------------------------------------------------------

  /// Orchestrates the initial checks when the PnP flow begins.
  Future<void> startPnpFlow(String? password);

  /// Submits the admin password for login.
  Future<void> submitPassword(String password);

  /// Continues the flow from an unconfigured state.
  Future<void> continueFromUnconfigured();

  /// Initializes the wizard phase.
  Future<void> initializeWizard();

  /// Saves all collected settings from the wizard to the router.
  Future<void> savePnpSettings();

  /// Tests the connection after a settings change and proceeds.
  Future<void> testPnpReconnect();

  /// Completes the firmware check and moves to the final screen.
  Future<void> completeFwCheck();

  /// Fetches basic device information.
  Future fetchDeviceInfo([bool clearCurrentSN = true]);

  /// Validates the admin password against the router.
  Future checkAdminPassword(String? password);

  /// Checks for a live internet connection.
  Future checkInternetConnection([int retries = 1]);

  /// Checks if the router is in an unconfigured (factory default) state.
  Future<ConfigurationResult> checkRouterConfigured();

  Future<AutoConfigurationSettings?> autoConfigurationCheck();

  /// Checks if the admin password has been set by the user.
  Future<bool> isRouterPasswordSet();

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

/// The concrete implementation of the PnP Notifier.
/// This class contains the core business logic for the PnP setup flow.
class PnpNotifier extends BasePnpNotifier {
  @override
  Future<void> startPnpFlow(String? password) async {
    logger.i(
        '[PnP]: Starting PnP flow... ${password != null ? 'with' : 'without'} a pre-filled password.');
    state = state.copyWith(status: PnpFlowStatus.adminInitializing);

    try {
      await fetchDeviceInfo();
      if (password != null) {
        setAttachedPassword(password);
      }

      final configResult = await checkRouterConfigured();
      if (configResult.status == ConfigStatus.unconfigured) {
        setAttachedPassword(configResult.passwordToUse);
        state = state.copyWith(status: PnpFlowStatus.adminUnconfigured);
        return; // End flow here for unconfigured case
      }

      final pnpService = ref.read(pnpServiceProvider);
      await pnpService
          .checkLoginAndAuthenticateIfNeeded(state.attachedPassword);

      logger.i('[PnP]: Checking for internet connection.');
      await checkInternetConnection();

      final routeFrom = ref.read(pnpTroubleshooterProvider).enterRouteName;
      if (routeFrom.isNotEmpty) {
        throw ExceptionInterruptAndExit(route: routeFrom);
      }

      logger.i('[PnP]: All initial checks passed. Internet is connected.');
      state = state.copyWith(status: PnpFlowStatus.adminInternetConnected);
    } on ExceptionFetchDeviceInfo catch (e) {
      logger.e('[PnP]: Failed to fetch device info.', error: e);
      state = state.copyWith(status: PnpFlowStatus.adminError, error: e);
    } on ExceptionInvalidAdminPassword catch (e) {
      logger.w('[PnP]: Invalid admin password. Awaiting user input.');
      setAttachedPassword(null); // Clear the invalid password
      state =
          state.copyWith(status: PnpFlowStatus.adminAwaitingPassword, error: e);
    } on ExceptionNoInternetConnection catch (e) {
      logger.w(
          '[PnP]: No internet connection detected. Navigating to troubleshooter.');
      state = state.copyWith(
          status: PnpFlowStatus.adminNeedsInternetTroubleshooting, error: e);
    } on ExceptionInterruptAndExit catch (e) {
      logger.i('[PnP]: Flow interrupted. Navigating to: ${e.route}');
      ref.read(pnpServiceProvider).forcePollingOnLocalLogin();
      state = state.copyWith(status: PnpFlowStatus.wizardInitFailed, error: e);
    } catch (e, stackTrace) {
      logger.e('[PnP]: An unexpected error occurred during initial checks',
          error: e, stackTrace: stackTrace);
      state = state.copyWith(status: PnpFlowStatus.adminError, error: e);
    }
  }

  @override
  Future<void> submitPassword(String password) async {
    logger.i('[PnP]: Submit password button tapped.');
    state = state.copyWith(status: PnpFlowStatus.adminLoggingIn);
    try {
      await checkAdminPassword(password);
      state = state.copyWith(status: PnpFlowStatus.adminCheckingInternet);
      await checkInternetConnection();
      logger.i('[PnP]: Manual login successful, navigating to setup wizard.');
      state = state.copyWith(status: PnpFlowStatus.wizardInitializing);
    } on ExceptionInvalidAdminPassword catch (e) {
      logger.w('[PnP]: Manual login failed - invalid password.');
      state = state.copyWith(status: PnpFlowStatus.adminLoginFailed, error: e);
    } on ExceptionNoInternetConnection catch (e) {
      logger.w('[PnP]: No internet after manual login.');
      state = state.copyWith(
          status: PnpFlowStatus.adminNeedsInternetTroubleshooting, error: e);
    } catch (e) {
      logger.e('[PnP]: Unexpected error during manual login.', error: e);
      state = state.copyWith(status: PnpFlowStatus.adminError, error: e);
    }
  }

  @override
  Future<void> continueFromUnconfigured() async {
    logger.i('[PnP]: Continue tapped from unconfigured state.');
    state = state.copyWith(status: PnpFlowStatus.adminCheckingInternet);
    try {
      await checkAdminPassword(state.attachedPassword);
      await checkInternetConnection();
      logger.i(
          '[PnP]: Logged in from unconfigured state, navigating to setup wizard.');
      state = state.copyWith(status: PnpFlowStatus.wizardInitializing);
    } on ExceptionNoInternetConnection catch (e) {
      logger.w('[PnP]: No internet after continuing from unconfigured state.');
      state = state.copyWith(
          status: PnpFlowStatus.adminNeedsInternetTroubleshooting, error: e);
    } catch (e) {
      logger.e('[PnP]: Failed to continue from unconfigured state.', error: e);
      state =
          state.copyWith(status: PnpFlowStatus.adminAwaitingPassword, error: e);
    }
  }

  @override
  Future<void> initializeWizard() async {
    state = state.copyWith(
        status: PnpFlowStatus.wizardInitializing,
        loadingMessage: 'Collecting data');
    logger.d('[PnP]: Initializing wizard... Fetching data.');
    try {
      final pnpService = ref.read(pnpServiceProvider);
      final uiModel = await pnpService.fetchData();
      state = state.copyWith(
        status: PnpFlowStatus.wizardConfiguring,
        defaultSettings: uiModel,
      );
      logger.d('[PnP]: Wizard initialization complete.');
    } catch (e, s) {
      logger.e('[PnP]: Failed to fetch initial router data for wizard.',
          error: e, stackTrace: s);
      state = state.copyWith(status: PnpFlowStatus.wizardInitFailed, error: e);
    }
  }

  @override
  Future<void> savePnpSettings() async {
    state = state.copyWith(
        status: PnpFlowStatus.wizardSaving, loadingMessage: 'Saving changes');
    logger.d('[PnP]: Saving changes...');

    try {
      final pnpService = ref.read(pnpServiceProvider);
      await pnpService.savePnpSettings(state);

      logger.d('[PnP]: Save flow complete.');

      if (state.isRouterUnConfigured) {
        // In unconfigured scenario, saving just moves to the next step (YourNetwork)
        state = state.copyWith(status: PnpFlowStatus.wizardConfiguring);
      } else {
        // In configured scenario, proceed to FW check.
        state = state.copyWith(status: PnpFlowStatus.wizardSaved);
        await Future.delayed(const Duration(seconds: 3));
        state = state.copyWith(status: PnpFlowStatus.wizardCheckingFirmware);
        final updateStarted = await pnpService.checkForFirmwareUpdate();
        if (updateStarted) {
          state = state.copyWith(status: PnpFlowStatus.wizardUpdatingFirmware);
        } else {
          await completeFwCheck();
        }
      }
    } on ExceptionNeedToReconnect catch (e) {
      logger.e(
          '[PnP]: Caught a connection error during save. Switching to "needReconnect" state.',
          error: e);
      state =
          state.copyWith(status: PnpFlowStatus.wizardNeedsReconnect, error: e);
    } on ExceptionSavingChanges catch (e) {
      logger.e('[PnP]: Caught a save error: $e. Returning to config.',
          error: e);
      state = state.copyWith(
          status: PnpFlowStatus.wizardSaveFailed, error: e.error);
    }
  }

  @override
  Future<void> completeFwCheck() async {
    try {
      await testConnectionReconnected();
      state = state.copyWith(status: PnpFlowStatus.wizardWifiReady);
    } catch (_) {
      state = state.copyWith(status: PnpFlowStatus.wizardNeedsReconnect);
    }
  }

  @override
  Future<void> testPnpReconnect() async {
    try {
      await testConnectionReconnected();
      final password = getDefaultWiFiNameAndPassphrase().password;
      await checkAdminPassword(password);

      if (state.isRouterUnConfigured) {
        state = state.copyWith(status: PnpFlowStatus.wizardConfiguring);
      } else {
        state = state.copyWith(status: PnpFlowStatus.wizardCheckingFirmware);
        final pnpService = ref.read(pnpServiceProvider);
        final updateStarted = await pnpService.checkForFirmwareUpdate();
        if (updateStarted) {
          state = state.copyWith(status: PnpFlowStatus.wizardUpdatingFirmware);
        } else {
          await completeFwCheck();
        }
      }
    } catch (e) {
      state =
          state.copyWith(status: PnpFlowStatus.wizardNeedsReconnect, error: e);
    }
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {
    logger.i('[PnP]: Fetching device info...');
    final pnpService = ref.read(pnpServiceProvider);
    final (uiModel, capabilities) =
        await pnpService.getDeviceInfo(clearCurrentSN);

    state = state.copyWith(
      deviceInfo: uiModel,
      capabilities: capabilities,
    );
    logger
        .i('[PnP]: Fetched device info successfully for ${uiModel.modelName}.');
  }

  @override
  Future checkAdminPassword(String? password) async {
    final pnpService = ref.read(pnpServiceProvider);
    await pnpService.checkAdminPassword(password);
    // Clear the password in pnp state once logging in successfully
    setAttachedPassword(null);
  }

  @override
  Future checkInternetConnection([int retries = 1]) async {
    final pnpService = ref.read(pnpServiceProvider);
    await pnpService.checkInternetConnection(retries);
  }

  @override
  Future<bool> isRouterPasswordSet() {
    final pnpService = ref.read(pnpServiceProvider);
    return pnpService.isRouterPasswordSet();
  }

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    return (
      name: state.defaultSettings?.wifiSsid ?? '',
      password: state.defaultSettings?.wifiPassword ?? '',
      security: '' // This seems to be unused now, can be cleaned up later
    );
  }

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    return (
      name: state.defaultSettings?.guestWifiSsid ?? '',
      password: state.defaultSettings?.guestWifiPassword ?? '',
    );
  }

  //endregion

  @override
  Future testConnectionReconnected() async {
    final pnpService = ref.read(pnpServiceProvider);
    await pnpService.testConnectionReconnected();
  }

  @override
  Future<ConfigurationResult> checkRouterConfigured() async {
    final pnpService = ref.read(pnpServiceProvider);

    final result = await pnpService.checkRouterConfigured();

    state = state.copyWith(
        isUnconfigured: result.status == ConfigStatus.unconfigured);

    return result;
  }

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() {
    final pnpService = ref.read(pnpServiceProvider);

    return pnpService.autoConfigurationCheck();
  }

  @override
  Future fetchDevices() async {
    logger.i('[PnP]: Fetching child nodes...');
    final pnpService = ref.read(pnpServiceProvider);
    final deviceList = await pnpService.fetchDevices();
    state = state.copyWith(childNodes: deviceList);
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
