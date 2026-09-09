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
/// Keyed on the cause being present rather than on the state transition alone.
/// [AppConnectionState.loggedOut] also arrives when auth logged *itself* out — an
/// idle timeout, a 401 through `sse_providers.dart`, the account menu — and the
/// connection notifier merely followed; calling `logout()` again there would be a
/// second teardown of a session already gone. `takePendingSessionExit()` returns
/// non-null only for an exit the core itself decided, and only once, so this is
/// safe to call on every transition into [AppConnectionState.loggedOut].
///
/// Review asked for the transition to be narrowed as well — `prev != loggedOut`,
/// the shape the recovery-dialog branch beside the caller already uses. Declined,
/// with a reason: a cause is set *before* the state assignment, and Riverpod does
/// not notify when an enum state is reassigned its current value, so a cause
/// decided while the state already read `loggedOut` never produces a transition to
/// key off. Keying on the cause is what makes that case merely late rather than
/// lost — see [listenForCoreSessionExit]. A destructive read that returns `null`
/// costs nothing; a stranded cause does.
///
/// `@visibleForTesting` because [listenForCoreSessionExit] is now its only caller
/// in `lib/` — the extraction that answered round 2's first finding also made this
/// one a test seam rather than an API. Left top-level rather than made private so
/// the read-and-clear-once property keeps its own three tests, which a state
/// transition cannot express: the claim there is about calling it *twice*.
@visibleForTesting
void endSessionIfCoreReportedOne(WidgetRef ref) {
  final cause =
      ref.read(appConnectionStateProvider.notifier).takePendingSessionExit();
  if (cause == null) return;
  logger.i('[Recovery] Connection state reports the session is over '
      '(${cause.name}) — ending it');
  ref.read(authProvider.notifier).logout(cause: cause);
}

/// Subscribe [endSessionIfCoreReportedOne] to the connection state.
///
/// A named symbol rather than an inline `listenManual` inside the caller's
/// `initState`, because the wiring is the part that can be deleted without any
/// test noticing. Measured on this PR: removing the three lines that used to sit in
/// `UspDashboardShell.initState` left all fourteen tests in this file's suite and
/// in `session_teardown_call_sites_test.dart` green, because one invoked the verb
/// by hand and the other pinned the verb's *definition* site. Extracted, the thing
/// a mutation deletes and the thing the census names are the same thing, and
/// `session_exit_sink_test.dart` drives a real state transition through the
/// subscription instead of calling the function.
///
/// ## The catch-up read, and why the "always mounted" argument it replaces was wrong
///
/// A report nobody consumes fails *open*: auth stays logged in while the
/// connection state says the session is over. The earlier version of this argued
/// the consumer could not be absent, because all three exits are reachable only
/// from inside the `/usp*` shell. That is true of what *triggers* an exit and false
/// of what *resolves* one. Two of the three are set by `_runProbe`, which runs on a
/// `Timer.periodic` owned by an app-lifetime notifier, and the two callers that
/// report a connectivity failure into it (`usp_system_monitor_notifier.dart`,
/// `usp_traffic_analysis_notifier.dart`) are documented as *not* autoDispose so
/// their history survives tab switches — they keep polling with no page of their
/// own on screen, and their only gate is `state == authenticated`.
///
/// So the subscription reads any pending cause once on wiring, before listening.
/// An exit decided with no consumer mounted is then acted on by the next one that
/// appears rather than never, which turns "fails open" into "signs out on the next
/// visit to a `/usp*` page". Combined with `AppConnectionStateNotifier`'s
/// `authProvider` listener clearing the field on both of its arms, a cause cannot
/// outlive the session it belongs to either.
///
/// Moving the subscription to the app root instead — always mounted, so no
/// catch-up needed — was measured and rejected. `appConnectionStateProvider`'s ten
/// readers are all post-login, so it is first built from a `/usp*` page today; its
/// `build()` wires `onReconnectFailed` from a **one-shot** `ref.read(
/// sseManagerProvider)`, that provider returns `null` until the USP client and
/// bridge exist, and nothing ever invalidates it. Subscribing at app-root
/// `initState` would therefore build it before login, against a null manager, and
/// permanently disable automatic entry into recovery — a certain regression traded
/// for a narrow one.
ProviderSubscription<AppConnectionState> listenForCoreSessionExit(
    WidgetRef ref) {
  // Deferred by one frame, and only this call. Callers wire this from `initState`,
  // so an inline read runs during the build pass — and `AuthNotifier.logout` opens
  // with `state = const AsyncValue.loading()`, a synchronous provider write.
  // `AuthNotifier.init` avoids the same shape for the same reason, in a comment on
  // itself; measured on riverpod 2.6.1, the inline version here raises
  // `framework.dart:5551 '!_dirty': is not true`. Pinned by the last test in
  // `session_exit_sink_test.dart`.
  //
  // The *listener* stays synchronous, deliberately: it fires from a provider change —
  // a button handler or the probe timer — never from a build pass, and the design's
  // "the cause is set before `state =`" ordering depends on it running in the same
  // turn as the transition.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The subscription dies with the `State`, so by the next frame this widget
    // may be gone. A cause left behind is picked up by the next consumer to
    // mount, which is the whole property of the catch-up read.
    if (!ref.context.mounted) return;
    endSessionIfCoreReportedOne(ref);
  });
  return ref.listenManual(appConnectionStateProvider, (prev, next) {
    if (next != AppConnectionState.loggedOut) return;
    endSessionIfCoreReportedOne(ref);
  });
}
