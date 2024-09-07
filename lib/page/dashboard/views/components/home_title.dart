import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';

class DashboardHomeTitle extends ConsumerWidget {
  const DashboardHomeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText.titleLarge(helloString(context)),
        Row(
          children: [
            Icon(LinksysIcons.calendar,
                color: Theme.of(context).colorScheme.onSurface),
            const AppGap.small2(),
            AppText.bodyMedium(
                loc(context).formalDateTime(DateTime.now(), DateTime.now()),
                color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
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
        title: AppText.labelLarge(loc(context).troubleshoot),
        trailing: const Icon(LinksysIcons.chevronRight),
        onTap: () {
          ref
              .read(pnpTroubleshooterProvider.notifier)
              .setEnterRoute(RouteNamed.dashboardHome);
          context.goNamed(RouteNamed.pnpNoInternetConnection);
        },
      ),
    );
  }

  String helloString(BuildContext context) => switch (DateTime.now().hour) {
        >= 18 && < 24 => loc(context).goodEvening,
        >= 12 && < 18 => loc(context).goodAfternoon,
        >= 6 && < 12 => loc(context).goodMorning,
        _ => loc(context).goodNight,
      };
}
