import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Where a run of the no-internet troubleshooting flow is (#1511 P1).
///
/// Troubleshooting's own phases rather than PnP's, because PnP is not its only
/// caller: the dashboard can enter the same pages with no PnP flow behind them.
/// [ModemRestartCountdown], [ModemRestartCheckingInternet] and [IspSaving] moved
/// here from `PnpPhase` unchanged.
///
/// Two phases end a run, and neither says where the user goes next — that is the
/// caller's ending (`TroubleshootingEnding`), so nothing here asks who the caller
/// is.
sealed class TroubleshootingPhase extends Equatable {
  const TroubleshootingPhase();
}

/// The router answered and has no internet: the hub and its forms.
///
/// [saveError] is why the last ISP save failed, for the form to show once. Any
/// later transition builds a new phase without it, so it cannot be shown twice.
/// Typed, not `'$e'` (constitution §13.4): the form localizes it, as the
/// wizard's `WizardConfiguring.saveError` is localized.
class TroubleshootingNoInternet extends TroubleshootingPhase {
  final ServiceError? saveError;
  const TroubleshootingNoInternet({this.saveError});
  @override
  List<Object?> get props => [saveError];
}

// ─── Modem Restart ──────────────────────────────────────────

/// Modem restart countdown running (150s → 0s).
class ModemRestartCountdown extends TroubleshootingPhase {
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
class ModemRestartCheckingInternet extends TroubleshootingPhase {
  final int attemptCount;
  final int maxAttempts;
  const ModemRestartCheckingInternet({
    required this.attemptCount,
    this.maxAttempts = 30,
  });
  @override
  List<Object?> get props => [attemptCount, maxAttempts];
}

// ─── ISP Save Progress ──────────────────────────────────────

enum IspSaveStep { saving, checkingSettings, checkingInternet }

/// ISP settings save is in progress, with multi-step display.
class IspSaving extends TroubleshootingPhase {
  final IspSaveStep step;
  const IspSaving({required this.step});
  @override
  List<Object?> get props => [step];
}

// ─── Endings ────────────────────────────────────────────────

/// The router has internet again. The caller's ending takes over.
class TroubleshootingRecovered extends TroubleshootingPhase {
  const TroubleshootingRecovered();
  @override
  List<Object?> get props => [];
}

/// The router could not be read, so whether it has internet is unknown.
///
/// Distinct from [TroubleshootingNoInternet] (#1098): the router did not confirm
/// "no internet", so the troubleshooting options are not the answer. The caller's
/// ending takes over — PnP's entry re-runs its check and shows its read-failure
/// card. [code] / [detail] are for the log only.
class TroubleshootingReadFailure extends TroubleshootingPhase {
  final int? code;
  final String? detail;
  const TroubleshootingReadFailure({this.code, this.detail});
  @override
  List<Object?> get props => [code, detail];
}
