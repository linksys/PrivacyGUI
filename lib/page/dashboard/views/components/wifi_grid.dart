import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class DashboardWiFiGrid extends ConsumerWidget {
  final String _tag = 'dashboard-wifi-grid';

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
    final mainSpacing = ResponsiveLayout.columnPadding(context);
    const itemHeight = 176.0;
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
          crossAxisSpacing: mainSpacing,
          // childAspectRatio: (3 / 2),
          mainAxisExtent: itemHeight,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: isLoading ? 4 : items.length,
        itemBuilder: (context, index) {
          final item = isLoading ? null : items[index];
          return ShimmerContainer(
              isLoading: isLoading,
              child: SizedBox(
                  height: itemHeight,
                  child: item == null
                      ? Container()
                      : _wifiCard(context, ref, item, index)));
        },
      ),
    );
  }

  Widget _wifiCard(
      BuildContext context, WidgetRef ref, DashboardWiFiItem item, int index) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.large2, horizontal: Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(
                item.isGuest
                    ? loc(context).guest
                    : item.radios
                        .map((e) => e.replaceAll('RADIO_', ''))
                        .join('/'),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'wifi-card-title'),
                semanticLabel: 'wifi card title',
              ),
              AppSwitch(
                identifier:
                    semanticIdentifier(tag: _tag, description: 'wifi-card'),
                semanticLabel: 'wifi card',
                value: item.isEnabled,
                onChanged: (value) async {
                  if (item.isGuest) {
                    showSpinnerDialog(context);
                    final guestWiFiProvider =
                        ref.read(guestWifiProvider.notifier);
                    await guestWiFiProvider.fetch();
                    guestWiFiProvider.setEnable(value);
                    await guestWiFiProvider
                        .save()
                        .then((value) =>
                            ref.read(pollingProvider.notifier).forcePolling())
                        .then((value) => context.pop());
                  } else {
                    showSpinnerDialog(context);
                    final wifiProvider = ref.read(wifiListProvider.notifier);
                    await wifiProvider.fetch();
                    await wifiProvider
                        .saveToggleEnabled(radios: item.radios, enabled: value)
                        .then((value) =>
                            ref.read(pollingProvider.notifier).forcePolling())
                        .then((value) => context.pop());
                  }
                },
              ),
            ],
          ),
          const AppGap.medium(),
          AppText.titleMedium(
            item.ssid,
            identifier:
                semanticIdentifier(tag: _tag, description: 'wifi-card-ssid'),
            semanticLabel: 'wifi card ssid',
          ),
          const AppGap.medium(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Semantics(
                      identifier: semanticIdentifier(
                          tag: _tag, description: 'wifi-card-device-icon'),
                      label: 'wifi card device icon',
                      child: const Icon(LinksysIcons.devices)),
                  const AppGap.medium(),
                  AppText.labelLarge(
                    loc(context).nDevices(item.numOfConnectedDevices),
                    identifier: semanticIdentifier(
                        tag: _tag, description: 'wifi-card-devices'),
                    semanticLabel: 'wifi card device',
                  ),
                ],
              ),
              AppIconButton.noPadding(
                  icon: LinksysIcons.share,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'wifi-card-share'),
                  semanticLabel: 'wifi card share',
                  onTap: () {
                    _showWiFiShareModal(context, item);
                  })
            ],
          )
        ],
      ),
      onTap: () {
        context.pushNamed(RouteNamed.settingsWifi,
            extra: {'wifiIndex': index, 'guest': item.isGuest});
      },
    );
  }

  _showWiFiShareModal(BuildContext context, DashboardWiFiItem item) {
    showSimpleAppOkDialog(context,
        title: loc(context).shareWiFi,
        content: WiFiShareDetailView(
          ssid: item.ssid,
          password: item.password,
        ),
        okLabel: loc(context).close);
  }
}
