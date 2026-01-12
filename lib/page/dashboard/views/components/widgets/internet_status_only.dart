import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying internet connection status only.
///
/// Extracted from [InternetConnectionWidget] for Bento Grid atomic usage.
/// Shows: Online/Offline indicator, geolocation, uptime (in expanded mode).
class DashboardInternetStatus extends ConsumerWidget {
  const DashboardInternetStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 80,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final geolocationState = ref.watch(geolocationProvider);
    final uptime = ref.watch(dashboardHomeProvider).uptime;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Status indicator
          Icon(
            Icons.circle,
            color: isOnline
                ? Theme.of(context).extension<AppColorScheme>()!.semanticSuccess
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            size: 12.0,
          ),
          AppGap.sm(),
          // Status text and location
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
          // Refresh button (non-mobile only)
          if (!Utils.isMobilePlatform())
            AnimatedRefreshContainer(
              builder: (controller) => AppIconButton(
                icon: AppIcon.font(AppFontIcons.refresh, size: 16),
                onTap: () {
                  controller.repeat();
                  ref.read(pollingProvider.notifier).forcePolling().then((_) {
                    controller.stop();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

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
