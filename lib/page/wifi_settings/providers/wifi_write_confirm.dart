import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

/// How long a WiFi write's answer is waited for before the save stops waiting
/// and reads the router back instead.
///
/// Every WiFi write reloads all the radios on FL-WRT 2.0, so the answer often
/// has nowhere to arrive. Thirty seconds covers the ~25 s reload a write was
/// answered after on the bench (2.0.2, the value `pnpWifiAnswerWindowProvider`
/// was set from). Ending the wait early is safe: an unanswered write is read
/// back before it is reported either way.
final wifiAnswerWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// How often the router is read back while a write's outcome is unknown.
final wifiReadBackIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

/// How long after the write the router is read back before the save gives up.
///
/// Counted from the write. Sixty seconds covers the two longest single waits
/// measured: #1460's DFS SET answered at 35.4 s over Remote Assistance, and on
/// 2.0.2 a renamed network went on the air 40 s after its write.
final wifiSaveDeadlineProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// Sends [plan] under the mutation lock and settles its outcome; returns the
/// plan's [WifiWritePlan.count] once the write is confirmed.
typedef WifiWriteConfirm = Future<WifiConfirmResult> Function(
  WifiWritePlan plan, {
  required Future<bool> Function(Map<String, dynamic> written) isApplied,
  bool allowRouterAway,
});

/// How a WiFi write settled.
sealed class WifiConfirmResult {
  const WifiConfirmResult();
}

/// The router answered the write, or read back what it was given.
final class WifiConfirmed extends WifiConfirmResult {
  /// The plan's [WifiWritePlan.count].
  final int count;
  const WifiConfirmed(this.count);
}

/// Every read-back by the deadline failed to reach the router.
///
/// Only returned to a caller that passed `allowRouterAway: true`. A WiFi Settings
/// rename takes the browser off the network it is on, and the browser cannot
/// rejoin a network it does not know — the user has to, which takes longer than
/// any deadline (bench 2026-10-07: the router had applied a Quick Setup rename,
/// the user was back on the new password, and the save had already reported
/// failure at 60 s). Over Remote Assistance the agent's path never breaks, but
/// the router still has to rejoin the cloud after the reload before it can be
/// read. The caller waits for the router instead and reads [proof] back once it
/// is reachable.
final class WifiRouterAway extends WifiConfirmResult {
  final Map<String, dynamic> proof;
  const WifiRouterAway(this.proof);
}

/// [WifiWriteConfirm] for the WiFi Settings and WiFi Advanced pages.
///
/// A provider rather than a service: it composes a service's write with the
/// lock and that service's read-back, and services do not call each other
/// (constitution §6.2). The shape is PnP's #1655 save, which bench-verified on
/// 2.0.2; PnP keeps its own copy because it ends on a reconnect step instead.
///
/// - A **confirmed** write returns at once.
/// - An **unanswered** write — the reply lost to the reload, or the lock's
///   [wifiAnswerWindowProvider] running out — is read back every
///   [wifiReadBackIntervalProvider] until [isApplied] says the router carries
///   the plan's [WifiWritePlan.proof] — the values the save changes, known
///   before the write, so a reply that never comes still leaves something to
///   check. Then it is confirmed. An empty proof cannot be checked, so a lost
///   reply then ends as an [UnexpectedError], never as a success. This is the fix for #1460, where
///   a 35.4 s SET had succeeded and the app reported a failure at 30 s.
/// - A failed read-back is "not yet": the radios can drop a request while they
///   settle.
/// - Not applied by [wifiSaveDeadlineProvider] is an [UnexpectedError], so the
///   page reports a failure instead of a success it could not confirm.
/// - A refusal from the write itself propagates unchanged.
///
/// The lock is released when its window ends even if the request is still in
/// flight, as it is for any hung call, so a read-back can take it.
final wifiWriteConfirmProvider = Provider<WifiWriteConfirm>((ref) {
  return (plan, {required isApplied, allowRouterAway = false}) async {
    if (plan.params.isEmpty) return WifiConfirmed(plan.count);
    // `clock`, not `Stopwatch()`: fakeAsync moves the former only, and the
    // shipped 30 s / 60 s are what the tests have to be able to run.
    final sinceWrite = clock.stopwatch()..start();
    final window = ref.read(wifiAnswerWindowProvider);

    var outcome = WifiWriteOutcome.unanswered;
    try {
      outcome = await ref.read(uspMutationLockProvider).withLock(
            plan.send,
            timeout: window,
          );
    } on TimeoutException {
      logger.i('[USP][WiFi]: write not answered within ${window.inSeconds}s '
          '— reading the router back');
    }
    if (outcome == WifiWriteOutcome.confirmed) return WifiConfirmed(plan.count);

    // Nothing this save changed can be read back — a password-only change is
    // the case. Reading back would compare only values that were already
    // there, so it would "confirm" a write that never arrived
    // (CLOUD_GUARDIANS#215). Unconfirmed is reported as a failure.
    if (plan.proof.isEmpty) {
      logger.w('[USP][WiFi]: write unanswered and nothing it changed can be '
          'read back — reporting it unconfirmed');
      throw const UnexpectedError();
    }

    final interval = ref.read(wifiReadBackIntervalProvider);
    final deadline = ref.read(wifiSaveDeadlineProvider);
    // Whether any read-back got an answer. One that did and read the wrong
    // values is the router saying no; none at all is the router being away.
    var reachedRouter = false;
    while (true) {
      try {
        final applied = await isApplied(plan.proof);
        reachedRouter = true;
        if (applied) {
          logger.i('[USP][WiFi]: write read back as applied after '
              '${sinceWrite.elapsed.inSeconds}s');
          return WifiConfirmed(plan.count);
        }
      } on ServiceError catch (e) {
        logger.d('[USP][WiFi]: could not read the WiFi back yet: $e');
      }
      if (sinceWrite.elapsed + interval > deadline) {
        if (allowRouterAway && !reachedRouter) {
          logger.i('[USP][WiFi]: router still away after '
              '${deadline.inSeconds}s — handing over to recovery');
          return WifiRouterAway(plan.proof);
        }
        logger.w('[USP][WiFi]: write not read back as applied within '
            '${deadline.inSeconds}s');
        throw const UnexpectedError();
      }
      await Future<void>.delayed(interval);
    }
  };
});
