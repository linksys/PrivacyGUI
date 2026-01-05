import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacy_gui/utils.dart';

import 'package:ui_kit_library/ui_kit.dart';

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
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;

    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final geolocationState = ref.watch(geolocationProvider);
    final master = isLoading
        ? null
        : ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final isMasterOffline =
        master?.data.isOnline == false || wanPortConnection == 'None';
    return isLoading
        ? AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                height: 150,
                child: const LoadingTile()))
        : AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        color: isOnline
                            ? Theme.of(context)
                                .extension<AppColorScheme>()!
                                .semanticSuccess
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        size: 16.0,
                      ),
                      AppGap.sm(),
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
                            if (geolocationState.value?.name.isNotEmpty ==
                                true) ...[
                              AppGap.sm(),
                              SharedWidgets.geolocationWidget(
                                  context,
                                  geolocationState.value?.name ?? '',
                                  geolocationState.value?.displayLocationText ??
                                      ''),
                            ],
                          ],
                        ),
                      ),
                      if (!Utils.isMobilePlatform())
                        AnimatedRefreshContainer(
                          builder: (controller) {
                            return Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: AppIconButton(
                                icon: AppIcon.font(
                                  AppFontIcons.refresh,
                                ),
                                onTap: () {
                                  controller.repeat();
                                  ref
                                      .read(pollingProvider.notifier)
                                      .forcePolling()
                                      .then((value) {
                                    controller.stop();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Container(
                  key: const ValueKey('master'),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: context.isMobileLayout ? 120 : 90,
                        child: SharedWidgets.resolveRouterImage(
                            context, masterIcon,
                            size: 112),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: AppSpacing.lg,
                              bottom: AppSpacing.lg,
                              left: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText.titleMedium(
                                  master?.data.location ?? '-----'),
                              AppGap.lg(),
                              Table(
                                border: const TableBorder(),
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                },
                                children: [
                                  TableRow(children: [
                                    AppText.labelLarge(
                                        '${loc(context).connection}:'),
                                    AppText.bodyMedium(isMasterOffline
                                        ? '--'
                                        : (master?.data.isWiredConnection ==
                                                true)
                                            ? loc(context).wired
                                            : loc(context).wireless),
                                  ]),
                                  TableRow(children: [
                                    AppText.labelLarge(
                                        '${loc(context).model}:'),
                                    AppText.bodyMedium(
                                        master?.data.model ?? '--'),
                                  ]),
                                  TableRow(children: [
                                    AppText.labelLarge(
                                        '${loc(context).serialNo}:'),
                                    AppText.bodyMedium(
                                        master?.data.serialNumber ?? '--'),
                                  ]),
                                  TableRow(children: [
                                    AppText.labelLarge(
                                        '${loc(context).fwVersion}:'),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        AppText.bodyMedium(
                                            master?.data.fwVersion ?? '--'),
                                        if (!isMasterOffline) ...[
                                          AppGap.lg(),
                                          SharedWidgets
                                              .nodeFirmwareStatusWidget(
                                            context,
                                            master?.data.fwUpToDate == false,
                                            () {
                                              context.pushNamed(RouteNamed
                                                  .firmwareUpdateDetail);
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
                ),
              ],
            ),
          );
  }
}
