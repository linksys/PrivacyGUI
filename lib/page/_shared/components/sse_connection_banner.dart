import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A page-wide banner that appears when the SSE connection is not healthy.
///
/// - **connected**: hidden (`SizedBox.shrink()`)
/// - **connecting / reconnecting**: warning banner with pulse indicator
/// - **suspended / disconnected** (non-intentional): danger banner with
///   a "Reconnect" button that calls [SseConnectionManager.tryReconnect]
///
/// Place this at the top of [UspDashboardShell] body so it spans all pages.
class SseConnectionBanner extends ConsumerWidget {
  const SseConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(sseConnectionStateProvider);

    return stateAsync.when(
      data: (state) => _buildBanner(context, ref, state),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(
      BuildContext context, WidgetRef ref, SseConnectionState state) {
    if (state == SseConnectionState.connected) {
      return const SizedBox.shrink();
    }

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
          'Connecting to router...',
        ),
      SseConnectionState.reconnecting => (
          Icons.sync,
          'Reconnecting...',
        ),
      SseConnectionState.suspended => (
          Icons.cloud_off,
          'Real-time connection lost',
        ),
      SseConnectionState.disconnected => (
          Icons.cloud_off,
          'Disconnected',
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
                  label: 'Reconnect',
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
