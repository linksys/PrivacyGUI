import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/services/internet_troubleshooting_service.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';

/// The no-internet troubleshooting flow's state (#1511 P1).
///
/// `autoDispose`: a run lives while its pages do. The hub sits under every other
/// troubleshooting page in the navigator stack and listens to this, so the run
/// lasts from entering the hub to leaving the tree, and the next entry starts
/// clean.
final internetTroubleshootingProvider = NotifierProvider.autoDispose<
    InternetTroubleshootingNotifier,
    TroubleshootingPhase>(InternetTroubleshootingNotifier.new);

/// The router's WAN settings, for the PPPoE and static-IP forms to prefill.
///
/// Read when the hub opens — it watches this — and again after every ISP save,
/// so a form reopened after a save starts from what the router now holds.
/// `null` when the read fails: an empty form is still usable.
final troubleshootingWanPrefillProvider =
    FutureProvider.autoDispose<UspInternetSettingsForm?>((ref) {
  return ref
      .watch(internetTroubleshootingServiceProvider)
      .fetchCurrentWanSettings();
});

/// Retry, modem restart and ISP save — the three ways out of "no internet".
///
/// Every way out ends on [TroubleshootingRecovered] or
/// [TroubleshootingReadFailure], and what happens then is the caller's: PnP goes
/// back to its entry, the dashboard back to itself. Nothing here asks who the
/// caller is.
class InternetTroubleshootingNotifier
    extends AutoDisposeNotifier<TroubleshootingPhase> {
  InternetTroubleshootingService get _svc =>
      ref.read(internetTroubleshootingServiceProvider);

  /// Set when the run is left. The countdown and the poll outlive a single
  /// frame, so each step checks this before touching `state` or `ref` again.
  bool _disposed = false;

  @override
  TroubleshootingPhase build() {
    ref.onDispose(() => _disposed = true);
    return const TroubleshootingNoInternet();
  }

  void _set(TroubleshootingPhase phase) {
    if (!_disposed) state = phase;
  }

  /// "Try again" on the hub: ask the router once more.
  Future<void> retryInternetCheck() => _checkInternet();

  Future<void> _checkInternet() async {
    if (_disposed) return;
    try {
      final hasInternet = await _svc.checkInternetConnected();
      _set(hasInternet
          ? const TroubleshootingRecovered()
          : const TroubleshootingNoInternet());
    } on ServiceError catch (e) {
      // The WAN read threw — we could NOT determine the WAN state (router
      // unreachable / USP GET returned empty). This is distinct from the router
      // confirming "no internet" (which returns false above, no throw), so we
      // must not collapse it into no internet.
      logger.e(
          '[Troubleshooting] Internet check read failure: $e (code=${e.code})');
      _set(TroubleshootingReadFailure(code: e.code, detail: '$e'));
    }
  }

  // ─── Modem Restart Flow ───────────────────────────────────

  /// Start the modem restart countdown (150s).
  /// Called when user confirms they plugged the modem back in.
  Future<void> startModemRestartCountdown() async {
    const total = 150;
    for (int s = total; s >= 0; s--) {
      if (_disposed) return;
      // Leaving the tree disposes the run (checked above); this catches the
      // phase being moved by something else meanwhile, such as an ISP save.
      if (state is! ModemRestartCountdown &&
          state is! TroubleshootingNoInternet &&
          s < total) {
        return;
      }
      state = ModemRestartCountdown(remainingSeconds: s, totalSeconds: total);
      if (s > 0) await Future.delayed(const Duration(seconds: 1));
    }
    await _modemRestartCheckInternet();
  }

  /// Poll internet after modem restart (up to 30 attempts, 5s apart).
  ///
  /// A failed read during the poll is expected (the router may be rebooting with
  /// the modem), so it only moves on to the next attempt. What decides the final
  /// page is the LAST attempt, the same split [_checkInternet] makes: a router
  /// that answered "no internet" lands on [TroubleshootingNoInternet], a router
  /// that could not be read lands on [TroubleshootingReadFailure] (#1098).
  Future<void> _modemRestartCheckInternet() async {
    const maxAttempts = 30;
    ServiceError? lastReadFailure;
    for (int i = 1; i <= maxAttempts; i++) {
      if (_disposed) return;
      state = ModemRestartCheckingInternet(
        attemptCount: i,
        maxAttempts: maxAttempts,
      );
      await Future.delayed(const Duration(seconds: 5));
      if (_disposed) return;
      try {
        final hasInternet = await _svc.checkInternetConnected();
        lastReadFailure = null;
        if (hasInternet) {
          _set(const TroubleshootingRecovered());
          return;
        }
      } on ServiceError catch (e) {
        lastReadFailure = e;
      }
    }
    final failure = lastReadFailure;
    if (failure != null) {
      logger.e('[Troubleshooting] Modem restart check read failure: $failure');
      _set(TroubleshootingReadFailure(code: failure.code, detail: '$failure'));
      return;
    }
    _set(const TroubleshootingNoInternet());
  }

  // ─── ISP Save with Progress ───────────────────────────────

  /// Save ISP settings with multi-step progress indication.
  Future<void> saveIspWithProgress(PnpIspConfig config) async {
    if (_disposed) return;
    try {
      state = const IspSaving(step: IspSaveStep.saving);
      await _svc.saveIspSettings(config);

      _set(const IspSaving(step: IspSaveStep.checkingSettings));
      await Future.delayed(const Duration(seconds: 3));

      _set(const IspSaving(step: IspSaveStep.checkingInternet));
      await Future.delayed(const Duration(seconds: 5));
      _refreshPrefill();
      await _checkInternet();
    } on ServiceError catch (e) {
      // The service throws only `ServiceError` — the mutation lock's timeout
      // included, typed where it starts — so this is the only catch the
      // constitution allows here (§13.4).
      logger.e('[Troubleshooting] ISP save failed: $e');
      _refreshPrefill();
      _set(TroubleshootingNoInternet(saveError: e));
    }
  }

  /// The WAN the forms prefill from is no longer what the router holds once a
  /// save has been sent, whether or not it was taken.
  void _refreshPrefill() {
    if (!_disposed) ref.invalidate(troubleshootingWanPrefillProvider);
  }
}
