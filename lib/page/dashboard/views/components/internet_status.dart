import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class InternetConnectionWidget extends ConsumerStatefulWidget {
  const InternetConnectionWidget({super.key});

  @override
  ConsumerState<InternetConnectionWidget> createState() =>
      _InternetConnectionWidgetState();
}

class _InternetConnectionWidgetState
    extends ConsumerState<InternetConnectionWidget> {
  @override
  Widget build(BuildContext context) {
    final isFirstPolling = ref
        .watch(dashboardHomeProvider.select((value) => value.isFirstPolling));
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;

    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    final geolocationState = ref.watch(geolocationProvider);
    final master = isLoading
        ? null
        : ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final isMasterOffline =
        master?.data.isOnline == false || wanPortConnection == 'None';
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.large2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline
                      ? Theme.of(context).colorSchemeExt.green
                      : Theme.of(context).colorScheme.surfaceVariant,
                  size: 16.0,
                ),
                const AppGap.small2(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(
                        isOnline
                            ? loc(context).internetOnline
                            : loc(context).internetOffline,
                      ),
                      if (geolocationState.value?.name.isNotEmpty == true) ...[
                        const AppGap.small2(),
                        SharedWidgets.geolocationWidget(
                            context,
                            geolocationState.value?.name ?? '',
                            geolocationState.value?.displayLocationText ?? ''),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('master'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
              border: Border.all(color: Colors.transparent),
              borderRadius: CustomTheme.of(context)
                  .radius
                  .asBorderRadius()
                  .medium
                  .copyWith(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
            ),
            child: Row(
              children: [
                Container(
                  color: Colors.blueAccent,
                  height: 158,
                  width: ResponsiveLayout.isDesktopLayout(context) ? 176 : 104,
                  // height: 176,
                  child: SharedWidgets.resolveRouterImage(context, masterIcon,
                      size: 112),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: Spacing.medium,
                        bottom: Spacing.medium,
                        left: Spacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.titleMedium(master?.data.location ?? '-----'),
                        const AppGap.large1(),
                        Table(
                          border: const TableBorder(),
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(children: [
                              AppText.labelLarge('${loc(context).connection}:'),
                              AppText.bodyMedium(isMasterOffline
                                  ? '--'
                                  : (master?.data.isWiredConnection == true)
                                      ? loc(context).wired
                                      : loc(context).wireless),
                            ]),
                            TableRow(children: [
                              AppText.labelLarge('${loc(context).model}:'),
                              AppText.bodyMedium(master?.data.model ?? '--'),
                            ]),
                            TableRow(children: [
                              AppText.labelLarge('${loc(context).serialNo}:'),
                              AppText.bodyMedium(
                                  master?.data.serialNumber ?? '--'),
                            ]),
                            TableRow(children: [
                              AppText.labelLarge('${loc(context).fwVersion}:'),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  AppText.bodyMedium(
                                      master?.data.fwVersion ?? '--'),
                                  if (!isMasterOffline) ...[
                                    const AppGap.medium(),
                                    SharedWidgets.nodeFirmwareStatusWidget(
                                      context,
                                      master?.data.fwUpToDate == false,
                                      () {
                                        context.pushNamed(
                                            RouteNamed.firmwareUpdateDetail);
                                      },
                                    ),
                                  ]
                                ],
                              ),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
