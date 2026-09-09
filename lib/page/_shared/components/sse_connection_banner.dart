import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A page-wide banner that appears when the SSE connection is not healthy.
///
/// *How loudly* it speaks is the surface's call, not this widget's: it asks
/// [SurfaceStrategy.connectionBannerLevel] and renders the answer.
///
/// - [SseBannerLevel.hidden] — nothing (`SizedBox.shrink()`)
/// - [SseBannerLevel.warning] — warning colours, and only after [_graceDelay],
///   so a stream that comes straight back never flashes anything
/// - [SseBannerLevel.danger] — danger colours, immediately
///
/// The "Reconnect" affordance is a separate question with a mode-independent
/// answer ([_canReconnect]): it is offered when the manager is *not* already
/// retrying, which until #1497 happened to be the same states that were severe.
/// Under Remote Assistance it no longer is — Guardian force-closes the proxied
/// stream at roughly ten minutes, so `disconnected` is both routine and exactly
/// when the agent needs the button.
///
/// This banner used to return `SizedBox.shrink()` outright in Remote Assistance,
/// on the grounds that SSE is "not supported via the Guardian proxy". It is: the
/// stream runs, it is just short-lived. Acceptance 7b of #1497 is that a support
/// engineer sees the same real-time-connection state the router's owner does.
///
/// Place this at the top of [UspDashboardShell] body so it spans all pages.
class SseConnectionBanner extends ConsumerStatefulWidget {
  const SseConnectionBanner({super.key});

  @override
  ConsumerState<SseConnectionBanner> createState() =>
      _SseConnectionBannerState();
}

class _SseConnectionBannerState extends ConsumerState<SseConnectionBanner> {
  /// Grace period before showing the banner. If SSE reconnects within this
  /// window the banner never appears, preventing visual flickering.
  static const _graceDelay = Duration(seconds: 3);

  /// The state currently displayed in the banner (null = hidden).
  SseConnectionState? _visibleState;
  Timer? _graceTimer;

  @override
  void initState() {
    super.initState();
    // Listen outside build() so setState() never fires during the build phase.
    ref.listenManual(sseConnectionStateProvider, (prev, next) {
      next.whenData(_reconcile);
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide banner in demo mode (where sseManagerProvider returns null)
    final sseManager = ref.watch(sseManagerProvider);
    if (sseManager == null) return const SizedBox.shrink();

    // Hide when recovery dialog is handling the disconnection UI
    final connState = ref.watch(appConnectionStateProvider);
    if (connState == AppConnectionState.waitingForRecovery) {
      return const SizedBox.shrink();
    }

    // Keep the watch so the widget rebuilds when the provider emits, but
    // all state reconciliation happens in the listenManual callback above.
    ref.watch(sseConnectionStateProvider);

    final state = _visibleState;
    if (state == null) return const SizedBox.shrink();
    return _buildBanner(
      context,
      state,
      ref.watch(surfaceStrategyProvider).connectionBannerLevel(state),
    );
  }

  /// Reconciles the real SSE state with what the banner displays, applying
  /// the grace period to everything this surface considers merely a warning.
  void _reconcile(SseConnectionState realState) {
    switch (
        ref.read(surfaceStrategyProvider).connectionBannerLevel(realState)) {
      case SseBannerLevel.hidden:
        // Recovered — hide immediately and cancel any pending show.
        _graceTimer?.cancel();
        _graceTimer = null;
        if (_visibleState != null) {
          setState(() => _visibleState = null);
        }

      case SseBannerLevel.danger:
        // Severe — bypass the grace period.
        _graceTimer?.cancel();
        _graceTimer = null;
        if (_visibleState != realState) {
          setState(() => _visibleState = realState);
        }

      case SseBannerLevel.warning:
        // Wait out the grace period before showing, in case it comes back.
        if (_graceTimer != null) return; // already waiting
        _graceTimer = Timer(_graceDelay, _showWhateverIsLiveNow);
    }
  }

  /// Applies the state as it is when the grace period *ends*, not as it was when
  /// the timer started.
  ///
  /// The distinction is the whole reason this is a method. `_reconcile` returns
  /// early while a timer is pending, so every warning-level change inside the
  /// three-second window is dropped — and closing over `realState` meant the
  /// banner then displayed a value up to three seconds stale. Two of the three
  /// warning states withhold the Reconnect button and one offers it, so the
  /// staleness straddles [_canReconnect]: `disconnected` captured and then
  /// superseded by `connecting` rendered "Disconnected" with a button that
  /// `tryReconnect()` refuses mid-attempt, and nothing re-ran this until the
  /// next provider emission — which, in the Remote Assistance case where the
  /// reopened stream carries no subscriptions, is never.
  ///
  /// Re-reading also means `hidden` is honoured here: recovery during the window
  /// cancels this timer via the `hidden` arm, but a recovery racing the timer's
  /// own tick would otherwise show a banner for a healthy connection.
  void _showWhateverIsLiveNow() {
    _graceTimer = null;
    if (!mounted) return;

    final live = ref.read(sseConnectionStateProvider).valueOrNull;
    if (live == null) return;

    final level = ref.read(surfaceStrategyProvider).connectionBannerLevel(live);
    setState(
        () => _visibleState = level == SseBannerLevel.hidden ? null : live);
  }

  /// Whether offering "Reconnect" would do anything.
  ///
  /// True for the two states in which the manager has stopped trying by itself —
  /// [SseConnectionState.disconnected] and [SseConnectionState.suspended] — and
  /// false while it is mid-attempt, where the button would race its own retry.
  /// A property of the connection, not of the mode.
  static bool _canReconnect(SseConnectionState state) =>
      state == SseConnectionState.disconnected ||
      state == SseConnectionState.suspended;

  Widget _buildBanner(
      BuildContext context, SseConnectionState state, SseBannerLevel level) {
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final isSevere = level == SseBannerLevel.danger;

    final bgColor = isSevere
        ? (appColors?.semanticDanger ?? Colors.red)
        : (appColors?.semanticWarning ?? Colors.orange);
    final fgColor = isSevere
        ? (appColors?.onSemanticDanger ?? Colors.white)
        : (appColors?.onSemanticWarning ?? Colors.black);

    final (icon, label) = switch (state) {
      SseConnectionState.connecting => (
          Icons.sync,
          loc(context).connectingToRouter,
        ),
      SseConnectionState.reconnecting => (
          Icons.sync,
          loc(context).reconnecting,
        ),
      SseConnectionState.suspended => (
          Icons.cloud_off,
          loc(context).realTimeConnectionLost,
        ),
      SseConnectionState.disconnected => (
          Icons.cloud_off,
          loc(context).disconnected,
        ),
      _ => (Icons.info_outline, ''),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: Container(
        key: ValueKey(state),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: bgColor,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(icon, size: 18, color: fgColor),
              AppGap.sm(),
              Expanded(
                child: AppText.bodySmall(label, color: fgColor),
              ),
              if (_canReconnect(state))
                AppButton.text(
                  label: loc(context).reconnect,
                  onTap: () {
                    ref.read(sseManagerProvider)?.tryReconnect();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
