import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardHomeTitle extends ConsumerWidget {
  const DashboardHomeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uptimeInt =
        ref.watch(dashboardHomeProvider.select((value) => value.uptime ?? 0));
    final isFirstPolling = ref
        .watch(dashboardHomeProvider.select((value) => value.isFirstPolling));
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    final uptime =
        DateFormatUtils.formatDuration(Duration(seconds: uptimeInt), context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AnimatedOpacity(
              opacity: isFirstPolling ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(),
              ),
            ),
            AnimatedOpacity(
              opacity: isFirstPolling ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: isOnline
                            ? Theme.of(context).colorSchemeExt.green
                            : Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      const AppGap.semiBig(),
                      AppText.titleLarge(
                        isOnline
                            ? loc(context).internetOnline
                            : loc(context).internetOffline,
                      ),
                    ],
                  ),
                  if (!ResponsiveLayout.isMobileLayout(context) && isOnline)
                    Row(
                      children: [
                        Icon(LinksysIcons.uptime,
                            color: Theme.of(context).colorScheme.onSurface),
                        const AppGap.regular(),
                        AppText.bodyMedium('${loc(context).uptime}: $uptime',
                            color: Theme.of(context).colorScheme.onSurface),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (ResponsiveLayout.isMobileLayout(context) && isOnline) ...[
          const AppGap.regular(),
          Row(
            children: [
              Icon(LinksysIcons.uptime,
                  color: Theme.of(context).colorScheme.onSurface),
              const AppGap.regular(),
              AppText.bodyMedium('${loc(context).uptime}: $uptime',
                  color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ],
        const AppGap.regular(),
      ],
    );
  }
}
