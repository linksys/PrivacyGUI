import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// End the app session if `lib/core/` has reported that one is over.
///
/// The acting half of `AppConnectionStateNotifier.takePendingSessionExit`, and the
/// only place in the app that turns that report into a sign-out.
///
/// **Keyed on the cause, not on the state transition.**
/// [AppConnectionState.loggedOut] also arrives when auth logged *itself* out — an
/// idle timeout, a 401 through `sse_providers.dart`, the account menu — and there a
/// second `logout()` would tear down a session already gone.
/// `takePendingSessionExit()` returns non-null only for an exit the core itself
/// decided, and only once, so this is safe on every transition into
/// [AppConnectionState.loggedOut]. It is not narrowed to `prev != loggedOut` either:
/// the cause is set *before* the state assignment, and Riverpod does not notify when
/// an enum state is reassigned its current value, so a cause decided while the state
/// already read `loggedOut` has no transition to key off. Keying on the cause makes
/// that case late rather than lost — see [listenForCoreSessionExit].
///
/// `@visibleForTesting` because [listenForCoreSessionExit] is its only caller in
/// `lib/`; top-level rather than private so the read-and-clear-once property keeps its
/// own tests, whose claim is about calling this *twice* and which no state transition
/// can express.
///
/// Why each decision in this file is the way it is, with the mutants that measure it:
/// §12 of `doc/mode_strategy/mode_strategy_guide.md`.
@visibleForTesting
void endSessionIfCoreReportedOne(WidgetRef ref) {
  final notifier = ref.read(appConnectionStateProvider.notifier);
  final cause = notifier.takePendingSessionExit();
  if (cause == null) return;
  // The probe result belongs on this line: [EndCause.sessionLost] is two events
  // wearing one name — a router that came back factory-reset (`recovered`) and one
  // that came back with a different serial (`serialMismatch`) — and which happened
  // decides what a support engineer does next. The alternative is correlating with a
  // `[Connection]` line up to a page mount away. `none` is the manual exit, whose
  // cause already names itself.
  logger.i('[Recovery] Connection state reports the session is over '
      '(${cause.name}, probe: ${notifier.lastProbeResult?.name ?? 'none'}) '
      '— ending it');
  // Cannot be awaited: both call sites are synchronous. The `onError` is what this
  // buys over a bare call, and it matters more here than at the other `logout()`
  // sites because the read above is destructive — nothing will re-report the cause,
  // so a silent failure leaves the app signed in to a session `lib/core/` has given
  // up on, and in Remote Assistance leaves the Guardian session open until it expires
  // (`RemoteSessionStrategy.end` is what releases it), while reading in a log exactly
  // like a clean sign-out.
  unawaited(
    ref.read(authProvider.notifier).logout(cause: cause).onError((e, s) {
      logger.e(
        '[Recovery] Ending the session failed after the report was consumed '
        '(${cause.name}) — nothing will retry it',
        error: e,
        stackTrace: s,
      );
    }),
  );
}

/// Subscribe [endSessionIfCoreReportedOne] to the connection state.
///
/// A named symbol rather than an inline `listenManual` in the caller's `initState`,
/// because the wiring is the part that can be deleted without a test noticing —
/// measured, while it was inline. Extracted, what a mutation deletes and what
/// `session_teardown_call_sites_test.dart` names are the same thing.
///
/// **The catch-up read, because the consumer is not always mounted.** A report nobody
/// consumes fails *open*: auth stays logged in while the connection state says the
/// session is over. The exits are only *triggered* from inside the `/usp*` shell —
/// two of the three are set by `_runProbe`, on a `Timer.periodic` owned by an
/// app-lifetime notifier and fed by two deliberately non-autoDispose polling
/// notifiers (`usp_system_monitor_notifier.dart`, `usp_traffic_analysis_notifier.dart`)
/// whose only gate is `state == authenticated` — so nothing guarantees a page is on
/// screen when one fires. Reading any pending cause once on wiring, before listening,
/// turns "fails open" into "signs out on the next visit to a `/usp*` page". A cause
/// cannot outlive its session either: `AppConnectionStateNotifier`'s `authProvider`
/// listener clears the field on its signed-out arm, which every sign-out passes
/// through. That listener's other arm deliberately does not — see
/// `takePendingSessionExit`.
///
/// **Not at the app root**, tempting as always-mounted is.
/// `appConnectionStateProvider`'s `build()` wires `onReconnectFailed` from a one-shot
/// `ref.read(sseManagerProvider)`, which returns `null` until the USP client and
/// bridge exist and is never invalidated; all ten of its readers are post-login, so
/// today it is first built from a `/usp*` page. Subscribing at app-root `initState`
/// would build it pre-login against a null manager and permanently disable automatic
/// entry into recovery — a certain regression traded for a narrow one.
///
/// **Returns nothing on purpose**, and not because closing a subscription twice is
/// dangerous (it is not, in riverpod 2.6.1). `ref.listenManual` closes with the
/// calling widget, so the handle had no caller — and handing one back would advertise
/// an ownership this function does not have: it wires *two* things, so closing the
/// subscription would silence the listener while leaving the post-frame catch-up
/// already scheduled.
void listenForCoreSessionExit(WidgetRef ref) {
  // Deferred by one frame, and only this call: callers wire this from `initState`, so
  // an inline read runs during the build pass, and `AuthNotifier.logout` opens with a
  // synchronous `state = const AsyncValue.loading()`. Measured on riverpod 2.6.1, the
  // inline version raises `framework.dart:5551 '!_dirty': is not true`;
  // `AuthNotifier.init` avoids the same shape for the same reason. Pinned by the last
  // test in `session_exit_sink_test.dart`.
  //
  // The *listener* stays synchronous: it fires from a provider change — a button
  // handler or the probe timer — never from a build pass, and the "cause is set before
  // `state =`" ordering needs it to run in the same turn as the transition.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The subscription dies with the `State`, so by the next frame this widget may be
    // gone. A cause left behind is picked up by the next consumer to mount.
    if (!ref.context.mounted) return;
    endSessionIfCoreReportedOne(ref);
  });
  ref.listenManual(appConnectionStateProvider, (prev, next) {
    if (next != AppConnectionState.loggedOut) return;
    endSessionIfCoreReportedOne(ref);
  });
}
