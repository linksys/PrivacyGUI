import 'package:equatable/equatable.dart';
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

  factory PnpState.initial() => const PnpState(phase: AdminInitializing());

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

/// Entry point — attempting default password login.
class AdminInitializing extends PnpPhase {
  const AdminInitializing();
  @override
  List<Object?> get props => [];
}

/// Router is in factory-default state (default password + FirstUseDate zero).
class AdminUnconfigured extends PnpPhase {
  const AdminUnconfigured();
  @override
  List<Object?> get props => [];
}

/// Default password failed — user must enter their password.
class AdminAwaitingPassword extends PnpPhase {
  const AdminAwaitingPassword();
  @override
  List<Object?> get props => [];
}

/// Authenticating with user-provided password.
class AdminLoggingIn extends PnpPhase {
  const AdminLoggingIn();
  @override
  List<Object?> get props => [];
}

/// Login failed — show error and let user retry.
class AdminLoginFailed extends PnpPhase {
  final String message;
  const AdminLoginFailed({required this.message});
  @override
  List<Object?> get props => [message];
}

/// Checking WAN / internet connectivity.
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
  const NoInternet();
  @override
  List<Object?> get props => [];
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

  const WizardConfiguring({required this.wifiConfig});

  @override
  List<Object?> get props => [wifiConfig];
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
