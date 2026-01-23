import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';

import 'package:ui_kit_library/ui_kit.dart';

/// Widget displaying internet connection status.
///
/// Supports three display modes:
/// - [DisplayMode.compact]: Only status indicator and IP
/// - [DisplayMode.normal]: Full display with router info
/// - [DisplayMode.expanded]: Extra details like uptime
class FixedInternetConnectionWidget extends ConsumerStatefulWidget {
  const FixedInternetConnectionWidget({
    super.key,
    this.displayMode = DisplayMode.normal,
    this.useAppCard = true,
  });

  /// The display mode for this widget
  final DisplayMode displayMode;

  /// Whether to wrap the content in an AppCard (default true).
  /// Set to false for layouts that provide their own containers.
  final bool useAppCard;

  @override
  ConsumerState<FixedInternetConnectionWidget> createState() =>
      _FixedInternetConnectionWidgetState();
}

class _FixedInternetConnectionWidgetState
    extends ConsumerState<FixedInternetConnectionWidget> {
  @override
  Widget build(BuildContext context) {
    return DashboardLoadingWrapper(
      loadingHeight: _getLoadingHeight(),
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  double _getLoadingHeight() {
    return switch (widget.displayMode) {
      DisplayMode.compact => 40,
      DisplayMode.normal => 150,
      DisplayMode.expanded => 200,
    };
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return switch (widget.displayMode) {
      DisplayMode.compact => _buildCompactView(context, ref),
      DisplayMode.normal => _buildNormalView(context, ref),
      DisplayMode.expanded => _buildExpandedView(context, ref),
    };
  }

  /// Compact view: Single row with status indicator + Online/Offline + location
  Widget _buildCompactView(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;

    final content = Row(
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
        // Status text
        AppText.labelLarge(
          isOnline ? loc(context).internetOnline : loc(context).internetOffline,
        ),
        const Spacer(),
        // Refresh button (non-mobile only)
        if (!Utils.isMobilePlatform()) ...[
          AppGap.md(),
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
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }

  /// Normal view: Full display with router info (current implementation)
  Widget _buildNormalView(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final geolocationState = ref.watch(geolocationProvider);
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final isMasterOffline =
        master.data.isOnline == false || wanPortConnection == 'None';

    final content = Column(
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
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    if (geolocationState.value?.name.isNotEmpty == true) ...[
                      AppGap.sm(),
                      SharedWidgets.geolocationWidget(
                          context,
                          geolocationState.value?.name ?? '',
                          geolocationState.value?.displayLocationText ?? ''),
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
                child: SharedWidgets.resolveRouterImage(context, masterIcon,
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
                      AppText.titleMedium(master.data.location),
                      AppGap.lg(),
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
                                : (master.data.isWiredConnection == true)
                                    ? loc(context).wired
                                    : loc(context).wireless),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).model}:'),
                            AppText.bodyMedium(master.data.model),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).serialNo}:'),
                            AppText.bodyMedium(master.data.serialNumber),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).fwVersion}:'),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppText.bodyMedium(master.data.fwVersion),
                                if (!isMasterOffline) ...[
                                  AppGap.lg(),
                                  SharedWidgets.nodeFirmwareStatusWidget(
                                    context,
                                    master.data.fwUpToDate == false,
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
        ),
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: content,
      );
    }
    return content;
  }

  /// Expanded view: Normal view + uptime info
  Widget _buildExpandedView(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final geolocationState = ref.watch(geolocationProvider);
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final uptime = ref.watch(dashboardHomeProvider).uptime;
    final isMasterOffline =
        master.data.isOnline == false || wanPortConnection == 'None';

    final content = Column(
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
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    if (geolocationState.value?.name.isNotEmpty == true) ...[
                      AppGap.sm(),
                      SharedWidgets.geolocationWidget(
                          context,
                          geolocationState.value?.name ?? '',
                          geolocationState.value?.displayLocationText ?? ''),
                    ],
                    // Uptime info (expanded only)
                    if (uptime != null && isOnline) ...[
                      AppGap.md(),
                      Row(
                        children: [
                          AppIcon.font(Icons.access_time, size: 14),
                          AppGap.xs(),
                          AppText.bodySmall(
                            _formatUptime(uptime),
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
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
                        icon: AppIcon.font(AppFontIcons.refresh),
                        onTap: () {
                          controller.repeat();
                          ref
                              .read(pollingProvider.notifier)
                              .forcePolling()
                              .then((_) {
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
          key: const ValueKey('master_expanded'),
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
                child: SharedWidgets.resolveRouterImage(context, masterIcon,
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
                      AppText.titleMedium(master.data.location),
                      AppGap.lg(),
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
                                : (master.data.isWiredConnection == true)
                                    ? loc(context).wired
                                    : loc(context).wireless),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).model}:'),
                            AppText.bodyMedium(master.data.model),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).serialNo}:'),
                            AppText.bodyMedium(master.data.serialNumber),
                          ]),
                          TableRow(children: [
                            AppText.labelLarge('${loc(context).fwVersion}:'),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppText.bodyMedium(master.data.fwVersion),
                                if (!isMasterOffline) ...[
                                  AppGap.lg(),
                                  SharedWidgets.nodeFirmwareStatusWidget(
                                    context,
                                    master.data.fwUpToDate == false,
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
        ),
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: content,
      );
    }
    return content;
  }

  /// Format uptime in human-readable format
  String _formatUptime(int seconds) {
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
