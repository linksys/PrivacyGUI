import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';

/// Outcome of [PnpAutoMasterFlowMixin.runAutoMasterFlow].
///
/// The mixin reports *what happened* to Auto Master and never navigates itself;
/// each caller maps these to the appropriate action (navigate / continue / show
/// error). This keeps the pnp-vs-login decision with the router
/// (`userAcknowledgedAutoConfiguration`) rather than hardcoding a redirect here.
enum AutoMasterFlowResult {
  /// Auto Master finished making this router the Master (status reached
  /// `complete`/`idle`). The router's admin state changed, so the caller should
  /// route onward to recover.
  completed,

  /// Auto Master did not change anything: it `failed`, or it never engaged. The
  /// session is valid and the caller may proceed with whatever it was doing
  /// (e.g. resume a pending save, or continue to the next step).
  proceed,

  /// The wait ran out of time, but the router is still reachable — so Auto
  /// Master's outcome is simply unknown. Distinct from [proceed], where Auto
  /// Master is known to have left the credential alone: here it may still be
  /// mid-flight, and a caller about to do something the rotation would break
  /// (saving settings) may want another look before committing. Callers with
  /// nothing at stake can treat it as [proceed].
  budgetExhausted,

  /// The router could not be reached after the wait ran out of time. The caller
  /// should surface the error and offer a retry.
  connectionError,
}

/// Shared Auto Master wait/poll state machine for PnP views.
///
/// Auto Master (firmware "make Master") is triggered when WAN comes up and,
/// after ~1 minute, changes the admin password and restarts services — which
/// invalidates the GUI's authenticated session. This mixin encapsulates the
/// polling/waiting logic that used to be copy-pasted across PnP views.
///
/// It requires [ConsumerState] (for `ref`, `context`, `mounted`, `setState`)
/// and drives the caller's own waiting UI through the supplied callbacks. It
/// deliberately performs no navigation of its own.
mixin PnpAutoMasterFlowMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Runs the Auto Master wait flow.
  ///
  /// When [waitForRunningFirst] is true (the ISP-save WAN-up point), it first
  /// polls until Auto Master *starts* (Idle -> Running) before waiting for it to
  /// finish. When false (the pre-save check), it goes straight to waiting for
  /// completion (the caller has already observed `running`).
  ///
  /// Callbacks:
  /// - [onEnterWaiting] fired once at the start (show the waiting UI).
  /// - [onShowConnectionError] fired on [AutoMasterFlowResult.connectionError].
  /// - [onExitWaiting] fired on the non-error outcomes (hide the waiting UI).
  ///
  /// All callbacks are only invoked while `mounted`.
  Future<AutoMasterFlowResult> runAutoMasterFlow({
    bool waitForRunningFirst = false,
    required VoidCallback onEnterWaiting,
    required VoidCallback onShowConnectionError,
    VoidCallback? onExitWaiting,
  }) async {
    if (mounted) onEnterWaiting();

    AutoMasterFlowResult result;
    if (waitForRunningFirst) {
      final phaseA = await _waitForRunning();
      // null => observed Running, fall through to waiting for completion.
      result = phaseA ?? await _waitForCompletion();
    } else {
      result = await _waitForCompletion();
    }

    if (!mounted) return result;
    if (result == AutoMasterFlowResult.connectionError) {
      onShowConnectionError();
    } else {
      onExitWaiting?.call();
    }
    return result;
  }

  /// Phase A — wait for Auto Master to *start*.
  ///
  /// Returns a terminal [AutoMasterFlowResult], or `null` to signal "Running
  /// observed, proceed to wait for completion".
  Future<AutoMasterFlowResult?> _waitForRunning() async {
    await for (final status
        in ref.read(pnpProvider.notifier).pollAutoMasterUntilRunning()) {
      if (!mounted) return AutoMasterFlowResult.proceed;

      if (status == AutoMasterStatus.running) {
        return null; // → wait for completion
      }
      if (status == AutoMasterStatus.complete) {
        return AutoMasterFlowResult.completed;
      }
      if (status == AutoMasterStatus.failed) {
        return AutoMasterFlowResult.proceed;
      }
      // null (unreachable, unsupported, or a firmware that will not serve the
      // status) and idle both mean "not started yet" — keep waiting until the
      // stream's own budget runs out.
    }

    // Stream ended without Running (budget spent). The session was just proven
    // alive by the upstream internet check, so we do NOT re-test the connection
    // here: Auto Master simply never announced itself.
    logger.w('[PnP]: Auto Master wait-for-running budget spent, proceed');
    return AutoMasterFlowResult.proceed;
  }

  /// Phase B — wait for Auto Master to *finish*.
  ///
  /// A `null` status is not evidence of anything here. make-Master takes the
  /// router's HTTP service down for the better part of a minute, and during that
  /// window the router may time out, refuse, or answer something unrecognised —
  /// so counting nulls to decide the router is gone reads noise as signal, and
  /// gives up (~50s) before the service is even back (~65s). The poll's own
  /// bounded length is the give-up rule instead, and only then does an actual
  /// reachability test decide.
  Future<AutoMasterFlowResult> _waitForCompletion() async {
    await for (final status
        in ref.read(pnpProvider.notifier).pollAutoMasterStatus()) {
      if (!mounted) return AutoMasterFlowResult.proceed;

      if (status == AutoMasterStatus.complete ||
          status == AutoMasterStatus.idle) {
        return AutoMasterFlowResult.completed;
      }
      if (status == AutoMasterStatus.failed) {
        return AutoMasterFlowResult.proceed;
      }
      // running / null → keep waiting.
    }

    // Budget spent without a terminal status. Ask the one question that can be
    // answered reliably: is the router there?
    logger.w('[PnP]: Auto Master polling budget spent, verifying connection');
    try {
      await ref.read(pnpProvider.notifier).testConnectionReconnected();
      // Reachable, but Auto Master's outcome is unknown — it may still be
      // running. Report that honestly and let the caller decide.
      return AutoMasterFlowResult.budgetExhausted;
    } catch (_) {
      return AutoMasterFlowResult.connectionError;
    }
  }
}
