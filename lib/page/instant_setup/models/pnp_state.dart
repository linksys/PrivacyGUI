import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'pnp_wifi_config.dart';

/// Whether this is a factory-default first-time setup or a reconfigure.
enum PnpFlowMode { unconfigured, configured }

/// Top-level PnP state — holds the current phase + shared context.
class PnpState extends Equatable {
  final PnpPhase phase;
  final PnpFlowMode flowMode;
  final String? serialNumber;
  final String? modelName;
  final String? errorMessage;

  const PnpState({
    required this.phase,
    this.flowMode = PnpFlowMode.unconfigured,
    this.serialNumber,
    this.modelName,
    this.errorMessage,
  });

  factory PnpState.initial() => const PnpState(phase: AdminCheckingInternet());

  PnpState copyWith({
    PnpPhase? phase,
    PnpFlowMode? flowMode,
    String? serialNumber,
    String? modelName,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PnpState(
      phase: phase ?? this.phase,
      flowMode: flowMode ?? this.flowMode,
      serialNumber: serialNumber ?? this.serialNumber,
      modelName: modelName ?? this.modelName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [phase, flowMode, serialNumber, modelName, errorMessage];
}

// ═══════════════════════════════════════════════════════════════
// PnP Phase — sealed class hierarchy for exhaustive switch
// ═══════════════════════════════════════════════════════════════

sealed class PnpPhase extends Equatable {
  const PnpPhase();
}

// ─── Admin Phase ───────────────────────────────────────────

/// Entry point — checking WAN / internet connectivity.
/// User is already authenticated at this point (login handled by LoginLocalView).
class AdminCheckingInternet extends PnpPhase {
  const AdminCheckingInternet();
  @override
  List<Object?> get props => [];
}

/// Internet is connected — ready to proceed to wizard.
class AdminInternetConnected extends PnpPhase {
  const AdminInternetConnected();
  @override
  List<Object?> get props => [];
}

/// Critical error in admin phase.
class AdminError extends PnpPhase {
  final String message;
  const AdminError({required this.message});
  @override
  List<Object?> get props => [message];
}

/// No internet detected — route to troubleshooter.
class NoInternet extends PnpPhase {
  final String? ssid;
  final UspInternetSettingsForm? currentWanSettings;
  const NoInternet({this.ssid, this.currentWanSettings});
  @override
  List<Object?> get props => [ssid, currentWanSettings];
}

// ─── Modem Restart Phase ────────────────────────────────────

/// Modem restart countdown running (150s → 0s).
class ModemRestartCountdown extends PnpPhase {
  final int remainingSeconds;
  final int totalSeconds;
  const ModemRestartCountdown({
    required this.remainingSeconds,
    this.totalSeconds = 150,
  });
  @override
  List<Object?> get props => [remainingSeconds, totalSeconds];
}

/// Modem restart: checking internet (polling up to maxAttempts).
class ModemRestartCheckingInternet extends PnpPhase {
  final int attemptCount;
  final int maxAttempts;
  const ModemRestartCheckingInternet({
    required this.attemptCount,
    this.maxAttempts = 30,
  });
  @override
  List<Object?> get props => [attemptCount, maxAttempts];
}

// ─── ISP Save Progress Phase ────────────────────────────────

enum IspSaveStep { saving, checkingSettings, checkingInternet }

/// ISP settings save is in progress, with multi-step display.
class IspSaving extends PnpPhase {
  final IspSaveStep step;
  const IspSaving({required this.step});
  @override
  List<Object?> get props => [step];
}

// ─── Wizard Phase ──────────────────────────────────────────

/// Fetching current WiFi / admin config from router.
class WizardInitializing extends PnpPhase {
  const WizardInitializing();
  @override
  List<Object?> get props => [];
}

/// User is editing WiFi name / password / guest WiFi.
class WizardConfiguring extends PnpPhase {
  final PnpWifiConfig wifiConfig;
  final List<NodeUIModel> meshNodes;

  const WizardConfiguring({
    required this.wifiConfig,
    this.meshNodes = const [],
  });

  @override
  List<Object?> get props => [wifiConfig, meshNodes];
}

/// Writing changes to router.
class WizardSaving extends PnpPhase {
  const WizardSaving();
  @override
  List<Object?> get props => [];
}

/// Changes saved successfully.
class WizardSaved extends PnpPhase {
  const WizardSaved();
  @override
  List<Object?> get props => [];
}

/// Connection lost after WiFi SSID change — user must reconnect.
class WizardNeedsReconnect extends PnpPhase {
  final String newSsid;
  final String newPassword;
  const WizardNeedsReconnect({
    required this.newSsid,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [newSsid, newPassword];
}

/// Polling for router after reconnect.
class WizardTestingReconnect extends PnpPhase {
  final int attemptCount;
  final int maxAttempts;
  const WizardTestingReconnect({
    required this.attemptCount,
    required this.maxAttempts,
  });
  @override
  List<Object?> get props => [attemptCount, maxAttempts];
}

/// Checking for available firmware updates.
class WizardCheckingFirmware extends PnpPhase {
  const WizardCheckingFirmware();
  @override
  List<Object?> get props => [];
}

/// Setup complete — show new WiFi credentials and proceed to dashboard.
class WizardWifiReady extends PnpPhase {
  final String ssid;
  final String password;
  const WizardWifiReady({required this.ssid, required this.password});
  @override
  List<Object?> get props => [ssid, password];
}

/// Recoverable error during wizard phase.
class WizardError extends PnpPhase {
  final String message;
  const WizardError({required this.message});
  @override
  List<Object?> get props => [message];
}
