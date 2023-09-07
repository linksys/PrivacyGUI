import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/iot_network_settings.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/network/_network.dart';
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
    final state = ref.watch(networkProvider);
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const AppText.titleLarge(
          'Your WiFi networks',
        ),
        content: _wifiList(state),
      ),
    );
  }

  Widget _wifiList(NetworkState state) {
    final items = _getWifiInfo(state);
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

  List<WifiListItem> _getWifiInfo(NetworkState state) {
    List<WifiListItem> items = [];
    List<RouterRadioInfo>? radioInfo = state.selected?.radioInfo;
    Map<WifiType, int> deviceCountMap =
        getConnectionDeviceCount(state.selected?.devices);
    if (radioInfo != null) {
      Map<String, RouterRadioInfo> infoMap =
          Map.fromEntries(radioInfo.map((e) => MapEntry(e.settings.ssid, e)));
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
            numOfDevices: deviceCountMap[WifiType.main] ?? 0,
            signal: 0);
      }).toList();
    }
    GuestRadioSetting? guestRadioSetting = state.selected?.guestRadioSetting;
    if (guestRadioSetting != null) {
      items.add(WifiListItem(
          wifiType: WifiType.guest,
          ssid: guestRadioSetting.radios.first.guestSSID,
          password: guestRadioSetting.radios.first.guestWPAPassphrase ?? '',
          securityType: items.isNotEmpty
              ? items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: items.isNotEmpty ? items.first.mode : WifiMode.mixed,
          isWifiEnabled: guestRadioSetting.isGuestNetworkEnabled,
          numOfDevices: deviceCountMap[WifiType.guest] ?? 0,
          signal: 0));
    }
    IoTNetworkSetting? iotNetworkSetting = state.selected?.iotNetworkSetting;
    if (iotNetworkSetting != null) {
      items.add(WifiListItem(
          wifiType: WifiType.iot,
          ssid: '',
          password: '',
          securityType: items.isNotEmpty
              ? items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: items.isNotEmpty ? items.first.mode : WifiMode.mixed,
          isWifiEnabled: iotNetworkSetting.isIoTNetworkEnabled,
          numOfDevices: deviceCountMap[WifiType.iot] ?? 0,
          signal: 0));
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

  Map<WifiType, int> getConnectionDeviceCount(List<RouterDevice>? devices) {
    Map<WifiType, int> map = {
      WifiType.main: 0,
      WifiType.guest: 0,
      WifiType.iot: 0,
    };
    int mainCount = 0;
    int guestCount = 0;
    int iotCount = 0;
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (device.connections.isNotEmpty &&
            (device.connections.first.isGuest ?? false)) {
          guestCount += 1;
        } else if (device.connections.isNotEmpty &&
            !device.isAuthority &&
            device.nodeType == null) {
          mainCount += 1;
        }
      }
      map[WifiType.main] = mainCount;
      map[WifiType.guest] = guestCount;
      map[WifiType.iot] = iotCount;
    }
    return map;
  }
}
