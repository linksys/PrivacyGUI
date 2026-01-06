import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';

class DashboardHomeTitle extends ConsumerWidget {
  const DashboardHomeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final state = ref.watch(dashboardManagerProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final localTime = DateTime.fromMillisecondsSinceEpoch(state.localTime);
    return isLoading
        ? AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                height: 150,
                child: const LoadingTile()))
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      helloString(context, localTime),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      doSomethingWithSpinner(context,
                              ref.read(timezoneProvider.notifier).fetch())
                          .then((_) {
                        if (!context.mounted) return;
                        context.pushNamed(RouteNamed.settingsTimeZone);
                      });
                    },
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppIcon.font(AppFontIcons.calendar,
                            color: Theme.of(context).colorScheme.onSurface),
                        Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: Text(
                            loc(context).formalDateTime(localTime, localTime),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
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
        trailing: AppIcon.font(AppFontIcons.chevronRight),
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
