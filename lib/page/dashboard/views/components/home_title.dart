import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class DashboardHomeTitle extends ConsumerWidget {
  const DashboardHomeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final state = ref.watch(dashboardManagerProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    final localTime = DateTime.fromMillisecondsSinceEpoch(state.localTime);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppText.titleLarge(
                helloString(context, localTime),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () {
                doSomethingWithSpinner(
                        context, ref.read(timezoneProvider.notifier).fetch())
                    .then((_) {
                  context.pushNamed(RouteNamed.settingsTimeZone);
                });
              },
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(LinksysIcons.calendar,
                      color: Theme.of(context).colorScheme.onSurface),
                  Padding(
                    padding: const EdgeInsets.only(left: Spacing.small2),
                    child: AppText.bodyMedium(
                      loc(context).formalDateTime(localTime, localTime),
                      color: Theme.of(context).colorScheme.onSurface,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLoading && !isOnline) _troubleshooting(context, ref),
      ],
    );
  }

  Widget _troubleshooting(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
      ),
      child: AppListCard(
        title: AppText.labelLarge(loc(context).troubleshoot),
        trailing: const Icon(LinksysIcons.chevronRight),
        onTap: () {
          ref
              .read(pnpTroubleshooterProvider.notifier)
              .setEnterRoute(RouteNamed.dashboardHome);
          context.goNamed(RouteNamed.pnpNoInternetConnection,
              extra: {'from': 'dashboard'});
        },
      ),
    );
  }

  String helloString(BuildContext context, DateTime localTime) =>
      switch (localTime.hour) {
        >= 17 && < 22 => loc(context).goodEvening,
        >= 12 && < 17 => loc(context).goodAfternoon,
        >= 1 && < 12 => loc(context).goodMorning,
        _ => loc(context).goodNight,
      };
}
