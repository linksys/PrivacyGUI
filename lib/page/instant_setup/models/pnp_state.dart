import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'pnp_wifi_config.dart';
import 'pnp_wifi_ready_band.dart';

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

/// Router state could not be read (USP GET returned empty / missing fields).
///
/// Distinct from [NoInternet]: the router did not confirm "no internet" — the
/// read itself failed, so we cannot tell the WAN state at all. The no-internet
/// troubleshooter options (restart modem / enter ISP settings) are meaningless
/// here, so this phase renders its own error card with a plain retry instead.
///
/// [code] / [detail] carry the underlying [ServiceError] diagnostics (e.g. the
/// codegen 9998 "required fields missing" fault) for logging only — the UI
/// derives its message from the phase itself.
class AdminReadFailure extends PnpPhase {
  final int? code;
  final String? detail;
  const AdminReadFailure({this.code, this.detail});
  @override
  List<Object?> get props => [code, detail];
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
  final List<NodeEntity> meshNodes;

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
  final PnpWifiConfig? wifiConfig;

  const WizardNeedsReconnect({
    required this.newSsid,
    required this.newPassword,
    this.wifiConfig,
  });
  @override
  List<Object?> get props => [newSsid, newPassword, wifiConfig];
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

/// The router is fetching and installing a newer firmware, mid-setup.
///
/// REQ-B2: a first-connection update is **locked** — there is no Skip and no way
/// back to the form or forward to the dashboard while it runs. The design reason
/// is that first connection has exactly two ways past this phase, and both are
/// facts about the router rather than choices: there is no update, or there is no
/// internet to fetch one over.
///
/// [version] is what the check named, and it may be empty: the router publishes
/// `Available=true` with no `Version` on some builds. The screen omits the line
/// rather than showing a blank one.
///
/// The progress itself is **not** here. It lives in `FirmwareUpdateState`, which
/// the view reads directly so that PnP renders W5's `FirmwareInstallPhaseCard`
/// rather than a second copy of its phase machine (REQ-B2). Mirroring the phase
/// into this object would give one install two sources of truth.
class WizardUpdatingFirmware extends PnpPhase {
  final String version;

  const WizardUpdatingFirmware({this.version = ''});

  @override
  List<Object?> get props => [version];
}

/// Setup complete — show new WiFi credentials and proceed to dashboard.
///
/// For unified mode: [ssid] and [password] are what is shown, and [bands] is
/// empty. For split mode: [bands] holds one entry per band.
///
/// **It carries credentials rather than the configuration they came from, and
/// that is REQ-B4.** A firmware update sits between [WizardSaved] and this phase
/// and reboots the router once, so these three-or-more strings are the one part of
/// the wizard that has to outlive it — see [PnpWifiReadyBand] for why carrying a
/// [PnpWifiConfig] would be a worse answer.
///
/// **They are not persisted, and that is the decision rather than an omission**
/// (Austin, 2026-09-16). REQ-B4's implementation note used to require a durable
/// copy — "not only in the in-memory phase object" — and W6 wrote one to
/// `FlutterSecureStorage`. Two measurements retired it. The reboot is the
/// *router's*, so the SPA is not reloaded and this object survives it: verified on
/// hardware (`..15 → ..16` through PnP, completion screen showed the configured
/// SSID and passphrase). And on web, `flutter_secure_storage` is `localStorage`
/// with the AES-GCM key kept in the same `localStorage` — so the durable copy was
/// a passphrase readable by any same-origin script, with no reader of its own:
/// `read()` had zero production callers for the life of the feature.
///
/// The case the copy would have covered is a **page** reload during the firmware
/// stage, which REQ-B4 never named and which cannot be recovered from by a read
/// alone — PnP re-entry is gated on `acknowledge()`, so it needs #1511's re-entry
/// semantics. Restoring persistence therefore means designing that first.
class WizardWifiReady extends PnpPhase {
  final String ssid;
  final String password;
  final List<PnpWifiReadyBand> bands;

  const WizardWifiReady({
    required this.ssid,
    required this.password,
    this.bands = const [],
  });

  /// The phase for a wizard that has just written [wifiConfig].
  ///
  /// The split-mode decision is made **here, once**, off the real configuration:
  /// [PnpWifiConfig.isSplitMode] compares the bands' `originalSsid` values, which
  /// only the configuration knows. Leaving it to the view would mean re-deciding
  /// it from a restored snapshot that no longer has those values.
  factory WizardWifiReady.fromWifiConfig({
    required String ssid,
    required String password,
    PnpWifiConfig? wifiConfig,
  }) {
    final split = wifiConfig?.isSplitMode ?? false;
    return WizardWifiReady(
      ssid: ssid,
      password: password,
      bands: split
          ? wifiConfig!.mainBands
              .map((b) => PnpWifiReadyBand(
                    bandName: b.bandName,
                    ssid: b.ssid,
                    password: b.password,
                  ))
              .toList()
          : const [],
    );
  }

  /// Two or more bands to show. Not a stored flag: one band is a unified network
  /// whichever way it was reached, and [ssid]/[password] already describe it.
  bool get isSplitMode => bands.length > 1;

  @override
  List<Object?> get props => [ssid, password, bands];
}

/// Recoverable error during wizard phase.
class WizardError extends PnpPhase {
  final String message;
  const WizardError({required this.message});
  @override
  List<Object?> get props => [message];
}
