import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_share_detail_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardWiFiGrid extends ConsumerWidget {
  const DashboardWiFiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHorizontal = ref.watch(
        dashboardHomeProvider.select((value) => value.isHorizontalLayout));
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    final crossAxisCount =
        (ResponsiveLayout.isMobileLayout(context) || !isHorizontal) ? 1 : 2;
    const mainSpacing = 8.0;
    const itemHeight = 160.0;
    final mainAxisCount = (items.length / crossAxisCount);
    return SizedBox(
      height: isLoading
          ? itemHeight * 2 + mainSpacing * 1
          : mainAxisCount * itemHeight +
              ((mainAxisCount == 0 ? 1 : mainAxisCount) - 1) * mainSpacing,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainSpacing,
          crossAxisSpacing: 4,
          // childAspectRatio: (3 / 2),
          mainAxisExtent: itemHeight,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: isLoading ? 4 : items.length,
        itemBuilder: (context, index) {
          final item = isLoading ? null : items[index];
          return ShimmerContainer(
              child: SizedBox(
                  height: itemHeight,
                  child:
                      item == null ? Container() : _wifiCard(context, item)));
        },
      ),
    );
  }

  Widget _wifiCard(BuildContext context, DashboardWiFiItem item) {
    return AppCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.bodyMedium(
              item.isGuest
                  ? loc(context).guest
                  : item.radios
                      .map((e) => e.replaceAll('RADIO_', ''))
                      .join('/'),
            ),
          ],
        ),
        const AppGap.semiBig(),
        AppText.titleMedium(item.ssid),
        const AppGap.semiBig(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LinksysIcons.devices),
                const AppGap.regular(),
                AppText.labelLarge(
                  loc(context).nDevices(item.numOfConnectedDevices),
                ),
              ],
            ),
            AppIconButton.noPadding(
                icon: LinksysIcons.share,
                onTap: () {
                  _showWiFiShareModal(context, item);
                })
          ],
        )
      ],
    ));
  }

  _showWiFiShareModal(BuildContext context, DashboardWiFiItem item) {
    showSimpleAppOkDialog(context,
        title: loc(context).wifi,
        content: WiFiShareDetailView(
          ssid: item.ssid,
          password: item.password,
        ),
        okLabel: loc(context).close);
  }
}
