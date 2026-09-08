import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/session/session_exit_actions.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';
import 'package:privacy_gui/framework/mode/surface_strategy.dart';
import 'package:privacy_gui/page/_shared/components/remote_session_chip.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// Remote Assistance surfaces: a support session has nothing to personalise, so
/// there is no mascot, the dashboard preset is fixed rather than picked, and edit
/// mode is not offered.
///
/// The discipline is that this mode expresses that by *not using* those
/// surfaces — not by a bool that hides them. See [SurfaceStrategy] and
/// `GlobalConfig.remote`'s doc comment, which records the three per-mode flags
/// phase 8 deleted with zero consumers each.
///
/// **The `null`s here are not "hidden in RA".** Each one is a surface this mode
/// has no concept of, and the two members that are *not* `null` are the point:
/// [sessionIndicator] and [sessionExitAction] exist only because remote is the
/// mode that is inside a session, and [connectionBannerLevel] reports the same
/// SSE states as local does — just not in the same colours.
class RemoteSurface implements SurfaceStrategy {
  const RemoteSurface();

  /// Nothing ambient. The mascot is the only coordinator either surface has, and
  /// a support session is not the place for a talking robot.
  @override
  List<ProviderListenable<Object?>> ambientCoordinators() => const [];

  /// Nothing to guard: this build *is* the session, so there is no "someone else
  /// is driving your router" state for a guard to detect. Returning the child
  /// unwrapped is what the guard's own first line used to do after being wrapped
  /// anyway.
  @override
  Widget sessionGuard({required Widget child}) => child;

  /// No banner about a session awaiting consent — consent is what got this build
  /// its token in the first place.
  @override
  Widget? assistanceBanner() => null;

  @override
  Widget? sessionIndicator() => const RemoteSessionChip();

  /// Guardian force-closes every proxied stream at roughly ten minutes, so
  /// `disconnected` is the most routine event in a support session: reported as a
  /// warning, after the banner's grace period, with Reconnect still offered.
  /// [SseConnectionState.suspended] stays danger — that is the manager having
  /// given up after its retries, which no amount of waiting fixes.
  @override
  SseBannerLevel connectionBannerLevel(SseConnectionState state) =>
      switch (state) {
        SseConnectionState.connected => SseBannerLevel.hidden,
        SseConnectionState.connecting => SseBannerLevel.warning,
        SseConnectionState.reconnecting => SseBannerLevel.warning,
        SseConnectionState.disconnected => SseBannerLevel.warning,
        SseConnectionState.suspended => SseBannerLevel.danger,
      };

  /// A support session does not offer to start another one.
  @override
  Widget? assistanceEntryCard() => null;

  /// The credential is a one-shot Guardian token: "log out" has no counterpart
  /// "log in", so the account block would offer a door with nothing behind it.
  /// [sessionExitAction] is this mode's way out.
  @override
  Widget? accountActions() => null;

  /// The layout belongs to the router's owner, not to the agent looking at it for
  /// twenty minutes. `null` is how the header bar learns not to render the
  /// `dashboard-edit` action at all.
  @override
  VoidCallback? layoutEditor(VoidCallback enterEditMode) => null;

  /// The preset is fixed (`UspDashboardPreset.remote`), so there is nothing to
  /// ask a first-time user — and the agent is not the user whose preference a
  /// picker would be storing.
  @override
  Future<void> Function(BuildContext context, WidgetRef ref)?
      firstRunPresetFlow() => null;

  /// No way in to a manual update. Uploading a firmware image is a local-only
  /// feature — #1496's `OperationGuard` refuses the transport-losing operation
  /// underneath, and this is the same decision one layer up, where the affordance
  /// is offered.
  ///
  /// The entry card, and only the entry card. The cloud OTA check stays, and so
  /// does the install phase machine behind this card: an OTA install is allowed in
  /// every mode and reports its progress, its failure and its retry through those
  /// same phases. Dropping them here was #1497's own regression.
  @override
  Widget firmwareManualEntry({required Widget Function() picker}) =>
      const SizedBox.shrink();

  @override
  Widget sessionExitAction() => const EndSessionAction();

  /// Empty rather than differently worded. The local line is advice to reconnect
  /// to the Wi-Fi that is restarting, which an agent's browser is nowhere near;
  /// an accurate remote line is new user-visible copy in 26 locales, and the
  /// surface with nothing to add says nothing.
  @override
  List<String> recoveryMessages() => const [];

  /// The only surface that registers `remoteAssistanceRoute`, which is the
  /// structural half of #1357: the confirm page cannot be reached in a build that
  /// has no route to it.
  @override
  List<RouteBase> routes() => [...sharedAppRoutes, remoteAssistanceRoute];
}
