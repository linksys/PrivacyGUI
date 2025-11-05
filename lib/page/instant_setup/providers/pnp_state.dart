import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';

/// Defines all possible explicit states for the entire PnP (Plug and Play) flow.
/// This enum replaces local state variables and flags in the UI, creating a single
/// source of truth for the flow's state within the PnpNotifier.
enum PnpFlowStatus {
  // Admin Phase
  adminInitializing,
  adminAwaitingPassword,
  adminLoggingIn,
  adminLoginFailed,
  adminUnconfigured,
  adminCheckingInternet,
  adminInternetConnected,
  adminError,
  adminNeedsInternetTroubleshooting,

  // Wizard Phase
  wizardInitializing,
  wizardInitFailed,
  wizardConfiguring,
  wizardSaving,
  wizardSaveFailed,
  wizardSaved,
  wizardCheckingFirmware,
  wizardUpdatingFirmware,
  wizardNeedsReconnect,
  wizardTestingReconnect,
  wizardWifiReady,
}

/// Represents the entire state of the PnP (Plug and Play) setup flow.
///
/// This class is immutable and holds all the data required across different steps
/// of the setup wizard, acting as the single source of truth.
class PnpState extends Equatable {
  /// The overall status of the PnP flow, driving the UI.
  final PnpFlowStatus status;

  /// Information about the router device being set up (UI Model).
  final PnpDeviceInfoUIModel? deviceInfo;

  /// Raw device information from JNAP (Domain Model).
  final PnpDeviceCapabilitiesUIModel? capabilities;

  /// The admin password passed via URL or manually entered, used for initial login attempts.
  final String? attachedPassword;

  /// A map holding the state for each individual step in the wizard, keyed by [PnpStepId].
  final Map<PnpStepId, PnpStepState> stepStateList;

  /// Indicates whether the router is in an unconfigured (factory default) state.
  /// `null` means it hasn't been checked yet.
  final bool? isUnconfigured;

  /// A cache of raw JNAP responses from the router for pre-fetched data.
  final PnpDefaultSettingsUIModel? defaultSettings;

  /// A list of child nodes detected in the network.
  final List<PnpChildNodeUIModel> childNodes;

  /// A flag to indicate if the flow should force a login, bypassing other checks.
  final bool forceLogin;

  /// Holds an error object when the status is a failure state (e.g., adminLoginFailed).
  final Object? error;

  /// Holds a message for loading screens.
  final String? loadingMessage;

  const PnpState({
    this.status = PnpFlowStatus.adminInitializing,
    this.deviceInfo,
    this.capabilities,
    this.attachedPassword,
    this.stepStateList = const {},
    this.isUnconfigured,
    this.defaultSettings,
    this.childNodes = const [],
    this.forceLogin = false,
    this.error,
    this.loadingMessage,
  });

  PnpState copyWith({
    PnpFlowStatus? status,
    PnpDeviceInfoUIModel? deviceInfo,
    PnpDeviceCapabilitiesUIModel? capabilities,
    String? attachedPassword,
    Map<PnpStepId, PnpStepState>? stepStateList,
    bool? isUnconfigured,
    PnpDefaultSettingsUIModel? defaultSettings,
    List<PnpChildNodeUIModel>? childNodes,
    bool? forceLogin,
    Object? error,
    String? loadingMessage,
  }) {
    return PnpState(
      status: status ?? this.status,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      capabilities: capabilities ?? this.capabilities,
      attachedPassword: attachedPassword ?? this.attachedPassword,
      stepStateList: stepStateList ?? this.stepStateList,
      isUnconfigured: isUnconfigured ?? this.isUnconfigured,
      defaultSettings: defaultSettings ?? this.defaultSettings,
      childNodes: childNodes ?? this.childNodes,
      forceLogin: forceLogin ?? this.forceLogin,
      error: error, // Errors are typically not persisted across states
      loadingMessage: loadingMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        deviceInfo,
        capabilities,
        attachedPassword,
        stepStateList,
        isUnconfigured,
        defaultSettings,
        childNodes,
        forceLogin,
        error,
        loadingMessage,
      ];

  /// A convenience getter that treats `null` `isUnconfigured` as `false`.
  bool get isRouterUnConfigured => isUnconfigured ?? false;
}
