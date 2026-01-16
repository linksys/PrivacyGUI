import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/data/providers/router_time_provider.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/settings/dashboard_layout_settings_panel.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';

class DashboardHomeTitle extends ConsumerWidget {
  final VoidCallback? onEditPressed;
  final bool showSettings;

  const DashboardHomeTitle({
    super.key,
    this.onEditPressed,
    this.showSettings = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 60,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final routerTime = ref.watch(routerTimeProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final localTime = DateTime.fromMillisecondsSinceEpoch(routerTime);

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
                    child: AppText.bodyMedium(
                        loc(context).formalDateTime(localTime, localTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            if (showSettings && BuildConfig.customLayout) ...[
              AppGap.lg(),
              AppIconButton.icon(
                size: AppButtonSize.small,
                icon: const Icon(Icons.settings_outlined),
                onTap: onEditPressed ?? () => _openLayoutSettings(context),
              ),
            ],
          ],
        ),
        if (!isOnline) _troubleshooting(context, ref),
      ],
    );
  }

  void _openLayoutSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: AppText.titleMedium(loc(context).dashboardSettings),
        content: const DashboardLayoutSettingsPanel(),
        actions: [
          AppButton(
            label: loc(context).close,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
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
