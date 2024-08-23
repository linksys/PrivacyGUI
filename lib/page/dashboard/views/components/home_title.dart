import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardHomeTitle extends ConsumerWidget {
  final String _tag = 'dashboard-home-title';

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
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Visibility(
              visible: isFirstPolling,
              child: AnimatedOpacity(
                opacity: isFirstPolling ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Semantics(
                      identifier:
                          semanticIdentifier(tag: _tag, description: 'spinner'),
                      label: 'spinner',
                      child: const CircularProgressIndicator()),
                ),
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
                      Semantics(
                        identifier: semanticIdentifier(
                            tag: _tag, description: 'online-icon'),
                        label: 'online icon',
                        child: Icon(
                          Icons.circle,
                          color: isOnline
                              ? Theme.of(context).colorSchemeExt.green
                              : Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                      const AppGap.large2(),
                      AppText.titleLarge(
                        isOnline
                            ? loc(context).internetOnline
                            : loc(context).internetOffline,
                        identifier: semanticIdentifier(
                          tag: _tag,
                          description:
                              isOnline ? 'internetOnline' : 'internetOffline',
                        ),
                      ),
                    ],
                  ),
                  if (!ResponsiveLayout.isMobileLayout(context) && isOnline)
                    Row(
                      children: [
                        Semantics(
                          identifier: semanticIdentifier(
                              tag: _tag, description: 'uptime-icon'),
                          label: 'uptime icon',
                          child: Icon(LinksysIcons.uptime,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const AppGap.medium(),
                        AppText.bodyMedium(
                          '${loc(context).uptime}: $uptime',
                          color: Theme.of(context).colorScheme.onSurface,
                          identifier: semanticIdentifier(
                              tag: _tag, description: 'uptime'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (ResponsiveLayout.isMobileLayout(context) && isOnline) ...[
          const AppGap.medium(),
          Row(
            children: [
              Semantics(
                identifier:
                    semanticIdentifier(tag: _tag, description: 'uptime-icon'),
                label: 'uptime icon',
                child: Icon(LinksysIcons.uptime,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const AppGap.medium(),
              AppText.bodyMedium(
                '${loc(context).uptime}: $uptime',
                color: Theme.of(context).colorScheme.onSurface,
                identifier:
                    semanticIdentifier(tag: _tag, description: 'uptime'),
              ),
            ],
          ),
        ],
        const AppGap.medium(),
        if (!isLoading && !isOnline) _troubleshooting(context, ref),
      ],
    );
  }

  Widget _troubleshooting(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16.0,
      ),
      child: AppListCard(
        title: AppText.labelLarge(
          loc(context).troubleshoot,
          identifier:
              semanticIdentifier(tag: _tag, description: 'troubleshoot'),
        ),
        trailing: Semantics(
            identifier:
                semanticIdentifier(tag: _tag, description: 'troubleshoot'),
            label: '${loc(context).troubleshoot} icon',
            child: const Icon(LinksysIcons.chevronRight)),
        onTap: () {
          ref
              .read(pnpTroubleshooterProvider.notifier)
              .setEnterRoute(RouteNamed.dashboardHome);
          context.goNamed(RouteNamed.pnpNoInternetConnection);
        },
      ),
    );
  }
}
