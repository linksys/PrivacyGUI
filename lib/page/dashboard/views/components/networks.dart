import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';

class DashboardNetworks extends ConsumerWidget {
  const DashboardNetworks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;
    final newFirmware = hasNewFirmware(ref);
    return ShimmerContainer(
      isLoading: isLoading,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(loc(context).myNetwork),
            const AppGap.regular(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodySmall(
                  newFirmware
                      ? loc(context).newFirmwareAvailable
                      : loc(context).upToDate,
                ),
                newFirmware
                    ? Icon(
                        LinksysIcons.error,
                        color: Theme.of(context).colorScheme.error,
                      )
                    : Icon(
                        LinksysIcons.check,
                        color: Theme.of(context).colorSchemeExt.green,
                      )
              ],
            ),
            const AppGap.semiBig(),
            Row(
              children: [
                Expanded(
                    child: _nodesInfoTile(
                  context,
                  ref,
                  state,
                )),
                Expanded(
                  child: _devicesInfoTile(
                    context,
                    ref,
                    state.wifis.fold(
                        0,
                        (previousValue, element) =>
                            previousValue += element.numOfConnectedDevices),
                  ),
                )
              ],
            ),
            const AppGap.semiBig(),
            ...state.nodes.map((e) => _nodeCard(context, e)),
          ],
        ),
      ),
    );
  }

  bool hasNewFirmware(WidgetRef ref) {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
  }

  Widget _nodeCard(BuildContext context, LinksysDevice node) {
    return AppListCard(
      title: AppText.titleMedium(node.getDeviceLocation()),
      description: AppText.bodyMedium(
          loc(context).nDevices(node.connectedDevices.length)),
      leading: Image(
          image: CustomTheme.of(context).images.devices.getByName(
              routerIconTestByModel(modelNumber: node.modelNumber ?? ''))),
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(node.isAuthority
              ? LinksysIcons.ethernet
              : getWifiSignalIconData(context, node.signalDecibels)),
          if (!node.isAuthority) AppText.bodySmall('${node.signalDecibels} dBM')
        ],
      ),
      showBorder: false,
    );
  }

  Widget _nodesInfoTile(
      BuildContext context, WidgetRef ref, DashboardHomeState state) {
    return _infoTile(
      iconData: LinksysIcons.networkNode,
      text: loc(context).nodes,
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
      BuildContext context, WidgetRef ref, int numOfOnlineExternalDevices) {
    return _infoTile(
      text: loc(context).devices,
      count: numOfOnlineExternalDevices,
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
      constraints: const BoxConstraints(
        minHeight: 136,
      ),
      child: AppCard(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  iconData,
                  size: 24,
                ),
                if (sub != null) sub,
              ],
            ),
            AppText.titleSmall(text),
            AppText.displaySmall('$count'),
          ],
        ),
      ),
    );
  }
}
