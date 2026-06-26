import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A page-wide banner that appears when the SSE connection is not healthy.
///
/// - **connected**: hidden (`SizedBox.shrink()`)
/// - **connecting / reconnecting**: warning banner with pulse indicator
/// - **suspended / disconnected** (non-intentional): danger banner with
///   a "Reconnect" button that calls [SseConnectionManager.tryReconnect]
///
/// Uses a grace period ([_graceDelay]) before showing the banner to avoid
/// flickering during brief reconnection cycles.
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
    // Hide banner in Remote Assistance mode (SSE not supported via Guardian proxy)
    if (GlobalConfig.remote.isActive) return const SizedBox.shrink();

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
    return _buildBanner(context, state);
  }

  /// Reconciles the real SSE state with what the banner displays, applying
  /// the grace period for non-connected states.
  void _reconcile(SseConnectionState realState) {
    if (realState == SseConnectionState.connected) {
      // Recovered — hide immediately and cancel any pending show.
      _graceTimer?.cancel();
      _graceTimer = null;
      if (_visibleState != null) {
        setState(() => _visibleState = null);
      }
      return;
    }

    // Non-connected state: start grace timer if not already ticking.
    // Suspended/disconnected bypass the grace period (already severe).
    final isSevere = realState == SseConnectionState.suspended ||
        realState == SseConnectionState.disconnected;

    if (isSevere) {
      _graceTimer?.cancel();
      _graceTimer = null;
      if (_visibleState != realState) {
        setState(() => _visibleState = realState);
      }
      return;
    }

    // connecting / reconnecting — wait for grace period before showing.
    if (_graceTimer != null) return; // already waiting
    _graceTimer = Timer(_graceDelay, () {
      _graceTimer = null;
      if (mounted) {
        setState(() => _visibleState = realState);
      }
    });
  }

  Widget _buildBanner(BuildContext context, SseConnectionState state) {
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final isSevere = state == SseConnectionState.suspended ||
        state == SseConnectionState.disconnected;

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
              if (isSevere)
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
