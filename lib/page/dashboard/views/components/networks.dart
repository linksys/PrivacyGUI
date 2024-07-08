import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class DashboardNetworks extends ConsumerWidget {
  const DashboardNetworks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: ShimmerContainer(
        isLoading: isLoading,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveLayout(
                desktop: state.isHorizontalLayout
                    ? _desktopHorizontal(context, ref)
                    : _desktopVertical(context, ref),
                mobile: _mobile(context, ref),
              ),
              const AppGap.large2(),
              // ...state.nodes.mapIndexed((index, e) => _nodeCard(context, ref, e)),
              SizedBox(
                height: state.nodes.length * 88,
                child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return _nodeCard(context, ref, state.nodes[index]);
                    },
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: state.nodes.length),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopHorizontal(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final newFirmware = hasNewFirmware(ref);
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(loc(context).myNetwork),
        if (isOnline) ...[
          const AppGap.medium(),
          _firmwareStatusWidget(context, newFirmware),
        ],
        const AppGap.large2(),
        Row(
          children: [
            Expanded(
                child: _nodesInfoTile(
              context,
              ref,
              state,
            )),
            const AppGap.gutter(),
            Expanded(
              child: _devicesInfoTile(
                context,
                ref,
                state,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _desktopVertical(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final newFirmware = hasNewFirmware(ref);
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(loc(context).myNetwork),
            if (isOnline) _firmwareStatusWidget(context, newFirmware),
          ],
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _nodesInfoTile(
                context,
                ref,
                state,
              ),
              const AppGap.gutter(),
              _devicesInfoTile(
                context,
                ref,
                state,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final newFirmware = hasNewFirmware(ref);
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(loc(context).myNetwork),
            if (isOnline) _firmwareStatusWidget(context, newFirmware),
          ],
        ),
        const AppGap.medium(),
        Row(
          children: [
            Expanded(
                child: _nodesInfoTile(
              context,
              ref,
              state,
            )),
            const AppGap.gutter(),
            Expanded(
              child: _devicesInfoTile(
                context,
                ref,
                state,
              ),
            )
          ],
        ),
      ],
    );
  }

  bool hasNewFirmware(WidgetRef ref) {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
  }

  Widget _firmwareStatusWidget(BuildContext context, bool newFirmware) {
    return InkWell(
      onTap: newFirmware
          ? () => context.pushNamed(RouteNamed.firmwareUpdateDetail)
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          newFirmware
              ? AppText.labelMedium(
                  loc(context).updateFirmware,
                  color: Theme.of(context).colorScheme.primary,
                )
              : _firmwareUpdateToDateWidget(context),
          newFirmware
              ? Icon(
                  LinksysIcons.cloudDownload,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  LinksysIcons.check,
                  color: Theme.of(context).colorSchemeExt.green,
                )
        ],
      ),
    );
  }

  Widget _firmwareUpdateToDateWidget(BuildContext context) {
    return AppStyledText(loc(context).dashboardFirmwareUpdateToDate,
        styleTags: {
          'span': Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Theme.of(context).colorSchemeExt.green)
        },
        defaultTextStyle: Theme.of(context).textTheme.bodySmall,
        callbackTags: const {});
  }

  Widget _nodeCard(BuildContext context, WidgetRef ref, LinksysDevice node) {
    return AppListCard(
      padding: const EdgeInsets.symmetric(vertical: Spacing.medium),
      title: AppText.titleMedium(node.getDeviceLocation()),
      description: AppText.bodyMedium(
          loc(context).nDevices(node.connectedDevices.length)),
      leading: Image(
        image: CustomTheme.of(context).images.devices.getByName(
              routerIconTestByModel(modelNumber: node.modelNumber ?? ''),
            ),
        width: 40,
        height: 40,
      ),
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(node.isOnline()
              ? node.isAuthority | !node.isWirelessConnection()
                  ? LinksysIcons.ethernet
                  : getWifiSignalIconData(context, node.signalDecibels)
              : LinksysIcons.signalWifiNone),
          if (!node.isAuthority && node.isWirelessConnection() && node.isOnline())
            AppText.bodySmall('${node.signalDecibels} dBM')
        ],
      ),
      showBorder: false,
      onTap: () {
        ref.read(nodeDetailIdProvider.notifier).state = node.deviceID;
        if (node.isOnline()) {
          // Update the current target Id for node state
          context.pushNamed(RouteNamed.nodeDetails);
        }
      },
    );
  }

  Widget _nodesInfoTile(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    return _infoTile(
      iconData: LinksysIcons.networkNode,
      text: state.nodes.length == 1 ? loc(context).node : loc(context).nodes,
      count: state.nodes.length,
      sub: state.isAnyNodesOffline
          ? Icon(
              LinksysIcons.infoCircle,
              size: 24,
              color: Theme.of(context).colorScheme.error,
            )
          : null,
      onTap: () {
        ref.read(topologySelectedIdProvider.notifier).state = '';
        context.pushNamed(RouteNamed.settingsNodes);
      },
    );
  }

  Widget _devicesInfoTile(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    final count = state.wifis.fold(
        0,
        (previousValue, element) =>
            previousValue += element.numOfConnectedDevices);
    return _infoTile(
      text: count == 1 ? loc(context).device : loc(context).devices,
      count: count,
      iconData: LinksysIcons.devices,
      onTap: () {
        context.goNamed(RouteNamed.dashboardDevices);
      },
    );
  }

  Widget _infoTile({
    required String text,
    required int count,
    required IconData iconData,
    Widget? sub,
    VoidCallback? onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      child: AppCard(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall('$count'),
                const AppGap.medium(),
                AppText.titleSmall(text),
              ],
            ),
            Icon(
              iconData,
              size: 20,
            ),
            if (sub != null) sub,
          ],
        ),
      ),
    );
  }
}
