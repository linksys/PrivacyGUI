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

  /// Auto Master did not change anything: it `failed`, or it timed out with the
  /// session still alive, or it never engaged. The session is valid and the
  /// caller may proceed with whatever it was doing (e.g. resume a pending save,
  /// or continue to the next step).
  proceed,

  /// A genuine connection error was detected (repeated polling failures that a
  /// probe could not attribute to a completed / dead-session state). The caller
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
    int consecutiveNullThreshold = 3,
    required VoidCallback onEnterWaiting,
    required VoidCallback onShowConnectionError,
    VoidCallback? onExitWaiting,
  }) async {
    if (mounted) onEnterWaiting();

    AutoMasterFlowResult result;
    if (waitForRunningFirst) {
      final phaseA = await _waitForRunning(consecutiveNullThreshold);
      // null => observed Running, fall through to waiting for completion.
      result = phaseA ?? await _waitForCompletion(consecutiveNullThreshold);
    } else {
      result = await _waitForCompletion(consecutiveNullThreshold);
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
  Future<AutoMasterFlowResult?> _waitForRunning(int threshold) async {
    int consecutiveNulls = 0;
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
      if (status == null) {
        consecutiveNulls++;
        logger.w(
            '[PnP]: Auto Master wait-for-running null, consecutive: $consecutiveNulls');
        if (consecutiveNulls >= threshold) {
          final probe = await _probe();
          if (!mounted) return AutoMasterFlowResult.proceed;
          // An undetermined probe means Auto Master status is unavailable — on
          // firmware that does not serve it unauthed, every poll lands here.
          // Phase A runs after ISP settings saved and WAN came up, so the
          // session was just proven alive; treating that as a connection error
          // would show "router not found" right after a successful setup.
          // Proceed instead and let PnP's own second pass handle recovery.
          if (probe == AutoMasterFlowResult.connectionError) {
            logger.w(
                '[PnP]: Auto Master wait-for-running undetermined, proceed');
            return AutoMasterFlowResult.proceed;
          }
          if (probe != null) return probe;
          consecutiveNulls = 0; // probe saw Running → keep waiting
        }
      } else {
        // idle → not started yet, keep waiting
        consecutiveNulls = 0;
      }
    }

    // Stream ended without Running (timeout). The session was just proven alive
    // by the upstream internet check, so we do NOT re-test the connection here.
    logger.w('[PnP]: Auto Master wait-for-running timeout, proceed');
    return AutoMasterFlowResult.proceed;
  }

  /// Phase B — wait for Auto Master to *finish*.
  Future<AutoMasterFlowResult> _waitForCompletion(int threshold) async {
    int consecutiveNulls = 0;
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
      if (status == null) {
        consecutiveNulls++;
        logger.w(
            '[PnP]: Auto Master polling null, consecutive: $consecutiveNulls');
        if (consecutiveNulls >= threshold) {
          final probe = await _probe();
          if (!mounted) return AutoMasterFlowResult.proceed;
          if (probe != null) return probe;
          consecutiveNulls = 0; // probe saw Running → keep waiting
        }
      } else {
        // running → keep waiting for completion
        consecutiveNulls = 0;
      }
    }

    // Stream ended (timeout). Verify the session survived make-Master.
    logger.w('[PnP]: Auto Master polling timeout, verifying connection');
    try {
      await ref.read(pnpProvider.notifier).testConnectionReconnected();
      return AutoMasterFlowResult.proceed;
    } catch (_) {
      return AutoMasterFlowResult.connectionError;
    }
  }

  /// Disambiguate a run of null poll results with one direct status read.
  ///
  /// The polls flatten every non-success result to `null`, so a router that is
  /// genuinely unreachable looks the same as firmware that will not serve the
  /// status. This probe re-reads the status once to see which it is.
  ///
  /// Returns a terminal [AutoMasterFlowResult], or `null` to signal "keep
  /// polling" (Auto Master is still Running). Callers decide what an
  /// undetermined status ([AutoMasterFlowResult.connectionError]) means for
  /// their phase — Phase A downgrades it to `proceed`.
  Future<AutoMasterFlowResult?> _probe() async {
    final status = await ref.read(pnpProvider.notifier).checkAutoMasterStatus();
    switch (status) {
      case AutoMasterStatus.complete:
      case AutoMasterStatus.idle:
        return AutoMasterFlowResult.completed;
      case AutoMasterStatus.failed:
        return AutoMasterFlowResult.proceed;
      case AutoMasterStatus.running:
        return null; // reset + keep polling
      case null:
        // Status unavailable: unreachable router, or firmware that does not
        // serve GetAutoMasterStatus unauthed.
        return AutoMasterFlowResult.connectionError;
    }
  }
}
