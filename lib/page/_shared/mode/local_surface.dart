import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/session/session_exit_actions.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/account_actions_section.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';
import 'package:privacy_gui/framework/mode/surface_strategy.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/first_run_preset_flow.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_banner.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_session_guard.dart';
import 'package:privacy_gui/page/support/views/components/remote_assistance_card.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// Local / cloud / demo surfaces: the user owns this router, so the mascot, the
/// dashboard preset picker and edit mode are all concepts this mode has.
///
/// The fuller of the two implementations, which is the expected shape — cause 5
/// is about surfaces a *support session* has no concept of, so almost every
/// member here is the one that returns something.
class LocalSurface implements SurfaceStrategy {
  const LocalSurface();

  /// The mascot's coordinator, whose only job is to run a random-speech timer.
  @override
  List<ProviderListenable<Object?>> ambientCoordinators() =>
      [mascotCoordinatorProvider];

  /// The user granting a support session needs the guard: a page refresh in the
  /// middle of an ACTIVE session must come back to a blocking dialog rather than
  /// to a dashboard someone else is also driving.
  @override
  Widget sessionGuard({required Widget child}) =>
      RemoteAssistanceSessionGuard(child: child);

  @override
  Widget? assistanceBanner() => const RemoteAssistanceBanner();

  /// No chip: this side of the session is the router's owner, and the banner
  /// above is what tells them about it.
  @override
  Widget? sessionIndicator() => null;

  /// The router is on the other end of a LAN. Nothing on that path should be
  /// closing a stream, so a closed one is a fault and says so immediately.
  @override
  SseBannerLevel connectionBannerLevel(SseConnectionState state) =>
      switch (state) {
        SseConnectionState.connected => SseBannerLevel.hidden,
        SseConnectionState.connecting => SseBannerLevel.warning,
        SseConnectionState.reconnecting => SseBannerLevel.warning,
        SseConnectionState.disconnected => SseBannerLevel.danger,
        SseConnectionState.suspended => SseBannerLevel.danger,
      };

  @override
  Widget? assistanceEntryCard() => const RemoteAssistanceCard();

  @override
  Widget? accountActions() => const AccountActionsSection();

  /// The layout is this user's to arrange, so the editor runs the callback the
  /// dashboard handed over.
  @override
  VoidCallback? layoutEditor(VoidCallback enterEditMode) => enterEditMode;

  @override
  Future<void> Function(BuildContext context, WidgetRef ref)?
      firstRunPresetFlow() => runFirstRunPresetFlow;

  @override
  Widget firmwareManualEntry({required Widget Function() picker}) => picker();

  @override
  Widget sessionExitAction() => const ReturnToLoginAction();

  /// Unlocalized, and kept that way deliberately: this is the string
  /// `showRecoveryDialog` has always defaulted to, moved rather than rewritten.
  /// Localizing it is a 26-file ARB change that #1497 is not, and doing it here
  /// would hide that debt behind a refactor.
  @override
  List<String> recoveryMessages() => const [
        'Your Wi-Fi network may restart. Please reconnect to your router\'s network if needed.',
      ];

  /// No `remoteAssistanceRoute`: in a local build `/remoteAssistance` is not a
  /// location that exists, so go_router answers it with its 404 rather than the
  /// redirect having to recognise and refuse it.
  ///
  /// A copy rather than `sharedAppRoutes` itself: see the contract: the list is a
  /// mutable top-level `final`, and the remote arm builds a new one anyway.
  @override
  List<RouteBase> routes() => [...sharedAppRoutes];
}
