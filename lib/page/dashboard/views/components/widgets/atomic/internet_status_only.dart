import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying internet connection status.
///
/// For custom layout (Bento Grid) only.
/// Shows: Online/Offline indicator, geolocation (normal/expanded), uptime (expanded).
class CustomInternetStatus extends DisplayModeConsumerWidget {
  const CustomInternetStatus({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact =>
          60, // Min height to fit LoadingTile default skeleton
        DisplayMode.normal => 80,
        DisplayMode.expanded => 100,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _statusIndicator(context, isOnline),
          AppGap.sm(),
          AppText.labelLarge(
            isOnline
                ? loc(context).internetOnline
                : loc(context).internetOffline,
          ),
          const Spacer(),
          if (!Utils.isMobilePlatform()) _refreshButton(ref),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);
    final geolocationState = ref.watch(geolocationProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _statusIndicator(context, isOnline),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(
                  isOnline
                      ? loc(context).internetOnline
                      : loc(context).internetOffline,
                ),
                if (geolocationState.value?.name.isNotEmpty == true) ...[
                  AppGap.xs(),
                  SharedWidgets.geolocationWidget(
                    context,
                    geolocationState.value?.name ?? '',
                    geolocationState.value?.displayLocationText ?? '',
                  ),
                ],
              ],
            ),
          ),
          if (!Utils.isMobilePlatform()) _refreshButton(ref),
        ],
      ),
    );
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    final isOnline = _isOnline(ref);
    final geolocationState = ref.watch(geolocationProvider);
    final uptime = ref.watch(dashboardHomeProvider).uptime;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _statusIndicator(context, isOnline),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(
                  isOnline
                      ? loc(context).internetOnline
                      : loc(context).internetOffline,
                ),
                if (geolocationState.value?.name.isNotEmpty == true) ...[
                  AppGap.xs(),
                  SharedWidgets.geolocationWidget(
                    context,
                    geolocationState.value?.name ?? '',
                    geolocationState.value?.displayLocationText ?? '',
                  ),
                ],
                if (uptime != null && isOnline) ...[
                  AppGap.xs(),
                  Row(
                    children: [
                      AppIcon.font(Icons.access_time, size: 12),
                      AppGap.xs(),
                      AppText.bodySmall(
                        _formatUptime(context, uptime),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!Utils.isMobilePlatform()) _refreshButton(ref),
        ],
      ),
    );
  }

  // Helper methods
  bool _isOnline(WidgetRef ref) =>
      ref.watch(internetStatusProvider) == InternetStatus.online;

  Widget _statusIndicator(BuildContext context, bool isOnline) => Icon(
        Icons.circle,
        color: isOnline
            ? Theme.of(context).extension<AppColorScheme>()!.semanticSuccess
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        size: 12.0,
      );

  Widget _refreshButton(WidgetRef ref) => AnimatedRefreshContainer(
        builder: (controller) => AppIconButton(
          icon: AppIcon.font(AppFontIcons.refresh, size: 16),
          onTap: () {
            controller.repeat();
            ref.read(pollingProvider.notifier).forcePolling().then((_) {
              controller.stop();
            });
          },
        ),
      );

  String _formatUptime(BuildContext context, int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '${loc(context).uptime}: ${days}d ${hours}h';
    } else if (hours > 0) {
      return '${loc(context).uptime}: ${hours}h ${minutes}m';
    } else {
      return '${loc(context).uptime}: ${minutes}m';
    }
  }
}
