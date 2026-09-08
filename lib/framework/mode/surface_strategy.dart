import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';

/// **Cause 5 — which surfaces the mode has a concept for.**
///
/// The narrow one, and the only cause whose implementations live under
/// `lib/page/`. Remote Assistance has no concept of a dashboard *preset picker*
/// (its preset is fixed), of dashboard edit mode, or of a support-request entry
/// on the support page — not because a flag forbids them, but because a support
/// session has nothing to personalise and is already the support channel. The
/// discipline #1474 sets is that a mode expresses this by *its strategy not using
/// a surface*, never by a bool that hides UI.
///
/// ## Every member returns composition, never a verdict
///
/// This is the rule that killed the rejected `UiCapabilities` bool table, and it
/// is the reason the signatures below look the way they do. A member answers
/// "what does this surface consist of" and the call site renders the answer; it
/// never answers "may I" and leaves the call site to write the `if`. Concretely:
///
/// * A surface a mode lacks is a **`null` widget** ([assistanceBanner],
///   [sessionIndicator], [assistanceEntryCard], [accountActions]) or a **short
///   list** ([ambientCoordinators], [recoveryMessages], [routes]) — not a
///   `false`.
/// * [firmwareManualEntry] is the one that says "nothing" with an empty widget
///   instead of `null`, and the reason is the call site rather than taste: it is
///   consumed from inside a `switch` arm that must produce a `Widget`, so a `null`
///   would buy back the `?? const SizedBox.shrink()` this contract exists to
///   remove. Same reasoning as [sessionExitAction]'s non-nullable return, arrived
///   at from the opposite direction.
/// * An *action* a mode lacks is a **`null` callback** ([layoutEditor]) or a
///   **`null` flow** ([firstRunPresetFlow]). The call site can render the
///   affordance only if it was handed something to run, so there is nothing to
///   forget to guard.
/// * A surface both modes have but *label* differently is a widget both ways
///   ([sessionExitAction], [sessionGuard]) — the pair with no `null` arm, and the
///   reason "hidden in remote" is the wrong summary of this contract.
///
/// The one exception proves the rule: [connectionBannerLevel] returns an
/// [SseBannerLevel], because the SSE banner is a surface **both** modes have and
/// the difference is how loudly it speaks. An enum with three values switched in
/// two places is Rule 4's own prescription; a `bool isSevere` per mode would have
/// been the capability table again.
///
/// ## Two composition roots
///
/// Rule 3 with the sign flipped: because these implementations must live at
/// `lib/page/_shared/mode/`, they are **not** reachable from `AppModeProfile`
/// (CLAUDE.md forbids `lib/core/` → `lib/page/`). [SurfaceStrategy] therefore has
/// its own composition root — a second exhaustive `switch` over the same
/// `AppMode` — at `lib/page/_shared/mode/surface_strategy_provider.dart`. Two
/// roots is the intended shape, and constitution Article XVII Rule 2 names both
/// so a third cannot appear unnoticed.
///
/// The contract itself stays clean of `lib/page/` in both directions, which is
/// what forces two of the signatures below to be looser than they look.
/// [firstRunPresetFlow] returns a `(context, ref)` callback rather than a
/// `Future<UspDashboardPreset?>`, and [firmwareManualEntry] takes a builder rather
/// than naming the card type, because naming those types here would drag
/// `lib/page/dashboard/` and `lib/page/firmware_update/` into
/// `lib/framework/mode/` — the coupling `mode_contract_roster_test.dart`'s
/// import scan exists to prevent, arriving through a return type exactly the way
/// `BridgeConfig` once did.
///
/// See `doc/mode_strategy/mode_strategy_guide.md` §"Cause 5: the surfaces".
abstract class SurfaceStrategy {
  // ══════════════════════════════════════════════════════════════════════════
  // Shell chrome
  // ══════════════════════════════════════════════════════════════════════════

  /// Providers the shell activates for their side effects while it is mounted.
  ///
  /// Watched, not read: these are coordinators whose whole job is to run — the
  /// mascot's random-speech timer is the local one — so the shell keeps them
  /// alive for as long as it is on screen and discards the values.
  ///
  /// A list rather than a nullable single provider, and rather than a
  /// `startCoordinators(ref)` method: the shell must do the watching itself.
  /// `ref.watch` inside a strategy would either need a `WidgetRef` passed in
  /// (which makes the strategy a widget's collaborator) or would register the
  /// dependency against the wrong element. Handing back *which* providers keeps
  /// the subscription where Riverpod expects it and leaves the strategy with no
  /// `if` at all — an empty list is how a mode says it has no ambient state.
  List<ProviderListenable<Object?>> ambientCoordinators();

  /// Wraps the shell's content in this surface's session guard.
  ///
  /// Both modes return a widget; only the local one wraps. This replaced *two*
  /// reads that had to agree — the shell's `if (!isRemoteMode)` around the
  /// wrapper and the guard widget's own early `return child` — which is the
  /// failure mode a strategy removes rather than relocates: the guard could be
  /// wrapped by a caller that thought it was needed and then decline to do
  /// anything, and nothing said so.
  Widget sessionGuard({required Widget child});

  /// The banner announcing a Remote Assistance session awaiting consent, or
  /// `null` where the mode is the session.
  Widget? assistanceBanner();

  /// The floating indicator for the session the app is *inside*, or `null`.
  ///
  /// The mirror image of [assistanceBanner], and the reason both exist as
  /// separate members: local shows a banner about a session it is granting,
  /// remote shows a chip about the session it is running. Neither mode wants
  /// both, and no single surface covers them.
  Widget? sessionIndicator();

  /// How this surface classifies an SSE connection state.
  ///
  /// The only member whose two implementations differ in *degree* rather than in
  /// presence — see [SseBannerLevel] for the ten-minute Guardian stream close
  /// that makes `disconnected` routine in one mode and a fault in the other.
  SseBannerLevel connectionBannerLevel(SseConnectionState state);

  // ══════════════════════════════════════════════════════════════════════════
  // Page surfaces
  // ══════════════════════════════════════════════════════════════════════════

  /// The support page's entry point for *requesting* remote assistance, or
  /// `null` — a support session does not offer to start another one.
  Widget? assistanceEntryCard();

  /// The account block in General Settings — legal links and sign-out — or
  /// `null`.
  ///
  /// Remote returns `null` for a reason narrower than "hide it in RA": the
  /// credential is a one-shot Guardian token, so "log out" has no counterpart
  /// "log in", and [sessionExitAction] is where that mode's exit lives instead.
  Widget? accountActions();

  /// This surface's dashboard layout editor, wired to [enterEditMode], or `null`
  /// where the layout is not the viewer's to arrange.
  ///
  /// Returns the callback rather than a flag so `DashboardHeaderBar` can stay
  /// provider-free *and* mode-free: it renders the `dashboard-edit` action iff
  /// it was handed something for the action to do. Until #1497 it took an
  /// `isRemoteMode` bool, which is the same condition spelled twice — once here
  /// and once as `onEdit`, a required callback that a remote build passed and
  /// never used.
  VoidCallback? layoutEditor(VoidCallback enterEditMode);

  /// This surface's first-run dashboard personalisation, or `null` where the
  /// preset is fixed.
  ///
  /// The whole flow, not just the dialog: the "have we asked before" preference,
  /// the picker, and applying the result are one decision, and splitting them
  /// left the call site holding a `showPresetDialog` flag it had to consult
  /// before touching any of them.
  Future<void> Function(BuildContext context, WidgetRef ref)?
      firstRunPresetFlow();

  /// The firmware page's manual entry point — the card that offers picking a
  /// local image and starting the upload — or nothing where pushing an image from
  /// the operator's browser is not a thing this surface does.
  ///
  /// Austin's 2026-09-08 decision, at the narrowest seam that expresses it.
  /// Manual firmware update is a local-only *feature*, with cloud OTA as the
  /// remote answer to the same need; `OperationGuard` is the floor underneath, so
  /// this member stops the operation being *offered* and #1496 stops it being
  /// *performed*.
  ///
  /// **Entry point, not the page and not the phase machine.** #1497 first spelled
  /// this as a `firmwareUpdateCards` list that dropped a `manualUpdate` card, and
  /// that was a real regression: the widget being dropped was the page's whole
  /// eleven-phase state machine, and a *cloud OTA* install drives the same phases
  /// — `triggering`, `installing`, `rebooting`, `verifying`, then `done` or
  /// `failed`. Removing it deleted the progress, the failure copy and the retry
  /// button for the operation this mode explicitly keeps, and no test caught it
  /// because every one of them pumped the `idle` phase, where the entry point and
  /// the machine happen to be the same widget. What a mode lacks here is the way
  /// *in*; what happens after an install starts belongs to whichever path started
  /// it.
  ///
  /// A builder, so a surface that omits the card never builds it and cannot
  /// register `firmwareUpdateProvider` dependencies for a card it is not showing.
  Widget firmwareManualEntry({required Widget Function() picker});

  // ══════════════════════════════════════════════════════════════════════════
  // Recovery dialogs
  // ══════════════════════════════════════════════════════════════════════════

  /// The bail-out button both recovery dialogs offer while the router is away.
  ///
  /// Never `null`, and #1323 records why: this is the whole `actions:` list of
  /// `showRecoveryDialog`, which passes `barrierDismissible: false` and only
  /// pops on a transition *into* `authenticated`. A mode with no exit action
  /// renders a modal an operator cannot leave.
  ///
  /// The two labels — "Return to login page" and "End session" — are the two
  /// answers to `SessionStrategy.destination`, so the widget pair lives outside
  /// `lib/page/` and neither dialog names either one.
  Widget sessionExitAction();

  /// The lines the recovery dialog shows under its title when the caller has no
  /// message of its own.
  ///
  /// Local's is the "reconnect to your router's network if needed" hint, which
  /// is advice a Remote Assistance agent cannot act on and should not be given —
  /// the agent's browser is nowhere near the Wi-Fi that is restarting. Remote's
  /// list is empty rather than differently worded: an accurate remote line is
  /// new user-visible copy, and the surface that has nothing to add says so.
  List<String> recoveryMessages();

  // ══════════════════════════════════════════════════════════════════════════
  // Routing
  // ══════════════════════════════════════════════════════════════════════════

  /// The route table for this surface.
  ///
  /// The structural half of #1357: a local build simply does not register
  /// `remoteAssistanceRoute`, so `/remoteAssistance` is a 404 rather than a
  /// location the redirect has to recognise and refuse. The `?session=` entry
  /// still needs its guard — an unmatched location returned *from* a redirect
  /// renders go_router's error page, so there is no route table that declines
  /// it — but the two entry points no longer have to agree by hand.
  ///
  /// **A fresh list, in both implementations.** `sharedAppRoutes` is a mutable
  /// top-level `final`, so returning it directly hands every caller an alias of
  /// the app's route table; the remote arm already had to build a new list to
  /// append to it, and the asymmetry was the only thing making the local arm's
  /// alias look deliberate.
  ///
  /// This member is also why importing a surface pulls in `router_provider.dart`,
  /// which imports the surfaces back through `surfaceStrategyProvider` —
  /// `sharedAppRoutes` and `remoteAssistanceRoute` both belong to that library
  /// (the latter is a `part` of it). The cycle is real and benign: every name
  /// involved is a lazily-initialised top-level `final`, so nothing observes a
  /// half-built library. Breaking it means giving the route definitions a library
  /// of their own, which is a routing refactor rather than a mode one.
  List<RouteBase> routes();
}
