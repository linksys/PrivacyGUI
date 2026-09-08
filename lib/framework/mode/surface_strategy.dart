import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';
// One name, because that is all [SurfaceStrategy.fixedDashboardLayout] needs and
// because the package's barrel collides with riverpod's (`Ref`, `AsyncValue` and
// three more, which `usp_layout_controller.dart` has to `hide`). A `show` cannot
// grow such a collision by accident.
import 'package:sliver_dashboard/sliver_dashboard.dart' show LayoutItem;

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
/// * [fixedDashboardLayout] is the one whose `null` points the other way: the
///   surface that answers it is the one with *less* to say, because a viewer whose
///   layout is their own has no fixed answer to give. Same rule underneath — the
///   call site renders what it is handed and consults nothing about the mode.
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
/// what forces three of the signatures below to be looser than they look.
/// [firstRunPresetFlow] returns a `(context, ref)` callback rather than a
/// `Future<UspDashboardPreset?>`, [firmwareManualEntry] takes a builder rather
/// than naming the card type, and [fixedDashboardLayout] returns the package's
/// `LayoutItem`s rather than the preset that produces them, because naming those
/// types here would drag `lib/page/dashboard/` and `lib/page/firmware_update/`
/// into `lib/framework/mode/` — the coupling
/// `mode_contract_roster_test.dart`'s import scan exists to prevent, arriving
/// through a return type exactly the way `BridgeConfig` once did.
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

  /// The layout this surface's dashboard is fixed to, or `null` where the
  /// viewer's own stored layout is authoritative.
  ///
  /// Non-null is a stronger statement than "start here": it says the layout is
  /// **nobody's preference**, so nothing about it is read from storage and nothing
  /// is written back. Both halves matter and both used to be decided by the same
  /// mode read, at two different providers — the grid
  /// (`usp_layout_controller.dart`) and the widget/preset preferences
  /// (`usp_layout_preferences_provider.dart`). One member rather than a "which
  /// preset" and a "do we persist" pair, because they are one decision and a pair
  /// is a pair that can be edited apart; see [sessionGuard] for the same failure
  /// found the other way round.
  ///
  /// A `List<LayoutItem>` and not a `UspDashboardPreset`, for the reason the two
  /// signatures below are also loose: the preset enum lives under `lib/page/`, and
  /// `LayoutItem` is the `sliver_dashboard` package's, so only the latter can be
  /// named here. Plain data rather than a builder — unlike [firmwareManualEntry],
  /// there is nothing to defer: `createLayout()` allocates a list of value
  /// objects and touches no provider. A **fresh** list per call, and not a cached
  /// one: the grid mutates `LayoutItem` geometry in place, so a shared instance
  /// would carry one session's drag into the next container.
  ///
  /// What the two halves are actually worth, since "nothing is written" is the
  /// kind of promise that is easy to write and easy to leave unenforced. The read
  /// half is an early `return` on both consumers. The write half is one guard in
  /// `UspLayoutController.saveLayout()`, which every writer funnels through —
  /// placed there rather than on the auto-persist hook, which five direct callers
  /// of `saveLayout` bypass. Not enforced, and unreachable rather than guarded:
  /// `resetLayout()` and `applyPreset()` still build their controller from the
  /// default layout, so a *future* non-edit-mode entry point to either would swap
  /// a fixed surface off its layout in memory. Both are reachable only from the
  /// edit-mode settings panel today, i.e. behind [layoutEditor].
  ///
  /// Remote's consequence is deliberate: a support session's `selectedPreset` is
  /// `null` rather than `UspDashboardPreset.remote`, because nobody picked it and
  /// the field's one reader is the edit-mode-only settings panel that
  /// [layoutEditor] keeps that surface out of.
  List<LayoutItem>? fixedDashboardLayout();

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
