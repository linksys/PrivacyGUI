import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'pnp_flow_plan.dart';
import 'pnp_wifi_ready_band.dart';
import 'pnp_wifi_write.dart';

/// Top-level PnP state — where the flow is, plus what it learned on the way.
///
/// Since #1511 P4 it holds **no form**: what the user types lives in the
/// setting steps' drafts (`pnp_wifi_draft_provider.dart`), so an edit never changes
/// this state and adding a step never adds a field here.
class PnpState extends Equatable {
  final PnpPhase phase;
  final String? serialNumber;
  final String? modelName;
  final String? errorMessage;

  /// The wizard's steps, decided once when it initializes; `null` before.
  final PnpFlowPlan? plan;

  /// The mesh nodes Your Network lists. Read with the Wi-Fi when the wizard
  /// initializes, and again after nodes are added (#1734).
  final List<NodeEntity> meshNodes;

  const PnpState({
    required this.phase,
    this.serialNumber,
    this.modelName,
    this.errorMessage,
    this.plan,
    this.meshNodes = const [],
  });

  factory PnpState.initial() => const PnpState(phase: AdminCheckingInternet());

  PnpState copyWith({
    PnpPhase? phase,
    String? serialNumber,
    String? modelName,
    String? errorMessage,
    bool clearError = false,
    PnpFlowPlan? plan,
    List<NodeEntity>? meshNodes,
  }) {
    return PnpState(
      phase: phase ?? this.phase,
      serialNumber: serialNumber ?? this.serialNumber,
      modelName: modelName ?? this.modelName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      plan: plan ?? this.plan,
      meshNodes: meshNodes ?? this.meshNodes,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        serialNumber,
        modelName,
        errorMessage,
        plan,
        meshNodes,
      ];
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

/// No internet detected — PnP hands the user to the troubleshooting flow.
///
/// PnP's part ends here (#1511 P1): retrying, restarting the modem and entering
/// ISP settings are the troubleshooting flow's, with state of its own, and it
/// reads the WAN for its forms itself. Internet back means `/pnp` again, which
/// re-runs this check.
class NoInternet extends PnpPhase {
  final String? ssid;
  const NoInternet({this.ssid});
  @override
  List<Object?> get props => [ssid];
}

// ─── Wizard Phase ──────────────────────────────────────────

/// Fetching current WiFi / admin config from router.
class WizardInitializing extends PnpPhase {
  const WizardInitializing();
  @override
  List<Object?> get props => [];
}

/// The user is on the wizard's steps, editing.
///
/// What they edit is not here: it is in the steps' drafts (#1511 P4).
class WizardConfiguring extends PnpPhase {
  /// Why the last save sent the user back here, for the shell to show once.
  ///
  /// On the phase rather than on [PnpState] so that it cannot outlive the
  /// return: the next save builds a new phase without it. A failed save used to
  /// put its error in a state field no view read, which is the "guest page
  /// shown twice" of #1000 — the user was sent back with nothing said.
  final ServiceError? saveError;

  const WizardConfiguring({this.saveError});

  @override
  List<Object?> get props => [saveError];
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

  /// What the save wrote, so that the router can be asked whether it took it
  /// once the user is back. `null` only from the demo launcher.
  final PnpWifiWrite? write;

  /// The WiFi write was sent but its answer never came, so whether the router
  /// applied it is asked after the reconnect. On FLWRT 2.0 this is the usual
  /// case, not a fault — see `PnpWifiWriteOutcome`.
  final bool writeUnanswered;

  const WizardNeedsReconnect({
    required this.newSsid,
    required this.newPassword,
    this.write,
    this.writeUnanswered = false,
  });
  @override
  List<Object?> get props => [newSsid, newPassword, write, writeUnanswered];
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
/// the wizard that has to outlive it — see [PnpWifiReadyBand] for why carrying the
/// whole configuration would be a worse answer.
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

  /// The phase for a wizard that has just written [write].
  ///
  /// The split-mode decision is made **here, once**, off what was written:
  /// [PnpMainWifiSettings.splitMode] is decided by the router read, which only
  /// the write still carries. Leaving it to the view would mean re-deciding it
  /// from a snapshot that no longer has it.
  factory WizardWifiReady.fromWrite(PnpWifiWrite write) {
    final main = write.main.current;
    return WizardWifiReady(
      ssid: write.reconnectSsid,
      password: write.reconnectPassword,
      bands: main.splitMode
          ? main.bands
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
