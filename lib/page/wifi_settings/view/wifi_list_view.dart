import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class WifiListView extends ConsumerStatefulWidget {
  const WifiListView({Key? key}) : super(key: key);

  @override
  ConsumerState<WifiListView> createState() => _WifiListViewState();
}

class _WifiListViewState extends ConsumerState<WifiListView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const AppText.titleLarge(
          'Your WiFi networks',
        ),
        content: _wifiList(),
      ),
    );
  }

  Widget _wifiList() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final items = _getWifiInfo(deviceManagerState, dashboardManagerState);
    return Column(
        children: List.generate(items.length, (index) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppPadding(
                padding:
                    const AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
                child: _information(items, index),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref
                      .read(wifiSettingProvider.notifier)
                      .selectWifi(items[index]);
                  context.pushNamed(RouteNamed.wifiShareDetails);
                },
                child: AppIcon.regular(
                  icon: getCharactersIcons(context).shareiOS,
                ),
              ),
            ],
          ),
          Offstage(
            offstage: index == items.length - 1,
            child: const Divider(
              thickness: 1,
              height: 1,
            ),
          )
        ],
      );
    }));
  }

  List<WifiListItem> _getWifiInfo(
    DeviceManagerState deviceManagerState,
    DashboardManagerState dashboardManagerState,
  ) {
    List<WifiListItem> items = [];
    final mainRadios = dashboardManagerState.mainRadios;
    Map<String, RouterRadioInfo> infoMap =
        Map.fromEntries(mainRadios.map((e) => MapEntry(e.settings.ssid, e)));
    items = List.from(infoMap.values).map((e) {
      RouterRadioInfo info = e as RouterRadioInfo;
      return WifiListItem(
        wifiType: WifiType.main,
        ssid: info.settings.ssid,
        password: info.settings.wpaPersonalSettings.passphrase,
        securityType:
            WifiListItem.convertToWifiSecurityType(info.settings.security),
        mode: WifiListItem.convertToWifiMode(info.settings.mode),
        isWifiEnabled: info.settings.isEnabled,
        numOfDevices: deviceManagerState.mainWifiDevices.length,
        signal: 0,
      );
    }).toList();
    final guestRadio = dashboardManagerState.guestRadios.firstOrNull;
    if (guestRadio != null) {
      items.add(
        WifiListItem(
          wifiType: WifiType.guest,
          ssid: guestRadio.guestSSID,
          password: guestRadio.guestWPAPassphrase ?? '',
          securityType: items.isNotEmpty
              ? items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: items.isNotEmpty ? items.first.mode : WifiMode.mixed,
          isWifiEnabled: dashboardManagerState.isGuestNetworkEnabled,
          numOfDevices: deviceManagerState.guestWifiDevices.length,
          signal: 0,
        ),
      );
    }
    return items;
  }

  Widget _information(List<WifiListItem> items, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.titleLarge(
              items[index].wifiType.displayTitle,
            ),
            const AppGap.small(),
            Container(
              padding: const EdgeInsets.all(5),
              child: AppText.headlineSmall(
                items[index].isWifiEnabled ? 'ON' : 'OFF',
              ),
            )
          ],
        ),
        const AppGap.semiSmall(),
        AppText.bodyLarge(
          items[index].ssid,
        ),
        const AppGap.small(),
        HiddenPasswordWidget(password: items[index].password),
        AppText.bodyMedium(
          '${items[index].numOfDevices} devices',
        ),
      ],
    );
  }
}
