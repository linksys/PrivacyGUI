import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/util/logger.dart';

class WifiSettingsView extends StatefulWidget {
  const WifiSettingsView({Key? key}) : super(key: key);

  @override
  _WifiSettingsViewState createState() => _WifiSettingsViewState();
}

//TODO: The temporary data model WifiListItem will be replaced.
class WifiListItem {
  final WifiType wifiType;
  String ssid;
  String password;
  WifiSecurityType securityType;
  WifiMode mode;
  bool isWifiEnabled;
  final int numOfDevices;
  final int signal;

  WifiListItem(
    this.wifiType,
    this.ssid,
    this.password,
    this.securityType,
    this.mode,
    this.isWifiEnabled,
    this.numOfDevices,
    this.signal,
  );

  static WifiSecurityType convertToWifiSecurityType(String security) {
    switch (security) {
      case 'Enhanced-Open+None':
        return WifiSecurityType.openAndEnhancedOpen;
      case 'Enhanced-Open-Only':
        return WifiSecurityType.enhancedOpen;
      case 'None':
        return WifiSecurityType.open;
      case 'WPA2-Personal':
        return WifiSecurityType.wpa3;
      case 'WPA2/WPA3-Mixed-Personal':
        return WifiSecurityType.wpa2Wpa3Mixed;
      case 'WPA3-Personal':
        return WifiSecurityType.wpa3;
      default:
        logger.d('ERROR: convertToWifiSecurityType: security = $security');
        return WifiSecurityType.open;
    }
  }

  static WifiMode convertToWifiMode(String wifiMode) {
    switch (wifiMode) {
      case '802.11bg':
        return WifiMode.bg;
      case '802.11bgn':
        return WifiMode.bgn;
      case '802.11mixed':
        return WifiMode.mixed;
      default:
        logger.d('ERROR: convertToWifiMode: wifiMode = $wifiMode');
        return WifiMode.mixed;
    }
  }
}

class _WifiSettingsViewState extends State<WifiSettingsView> {
  //TODO: Remove dummy data
  final List<WifiListItem> items = [
    WifiListItem(WifiType.main, 'MyMainNetwork', '01234567',
        WifiSecurityType.wpa2Wpa3Mixed, WifiMode.mixed, true, 22, 100),
    WifiListItem(WifiType.guest, 'MyGuestNetwork', '12345678',
        WifiSecurityType.wpa2, WifiMode.mixed, false, 33, 100),
    WifiListItem(WifiType.iot, 'MyIotNetwork_1', '23456789',
        WifiSecurityType.openAndEnhancedOpen, WifiMode.mixed, false, 44, 100),
    WifiListItem(WifiType.iot, 'MyIotNetwork_2', '34567890',
        WifiSecurityType.open, WifiMode.mixed, true, 55, 100),
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: ListView.separated(
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                NavigationCubit.of(context).pushAndWait(
                  WifiSettingsReviewPath()..args = {'info': items[index]}
                ).then((updatedInfo) {
                  if (updatedInfo != null) {
                    setState(() => items[index] = updatedInfo);
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Text(
                      items[index].wifiType.displayTitle,
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Theme.of(context).colorScheme.surface),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        items[index].ssid,
                        style: Theme.of(context).textTheme.headline2?.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const Spacer(),
                      Text(
                        items[index].isWifiEnabled ? 'ON' : 'OFF',
                        style: Theme.of(context).textTheme.headline2?.copyWith(
                            color: Theme.of(context).colorScheme.surface),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Image.asset(
                        'assets/images/arrow_point_to_right.png',
                        height: 12,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) {
            return const Divider(
                thickness: 1, height: 1, color: MoabColor.dividerGrey);
          },
        ),
        footer: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: SimpleTextButton(
            text: 'Learn more about WiFi networks and settings',
            onPressed: () {
              //TODO: Go to next
            },
          ),
        ),
      ),
    );
  }
}

enum WifiType {
  main(displayTitle: 'MAIN'),
  guest(displayTitle: 'GUEST'),
  iot(displayTitle: 'IOT DEVICES');

  const WifiType({required this.displayTitle});

  final String displayTitle;
  List<WifiSettingOption> get settingOptions {
    List<WifiSettingOption> options = [
      WifiSettingOption.nameAndPassword,
      WifiSettingOption.mode,
    ];

    if (this == WifiType.main) {
      options.insertAll(1, [
        WifiSettingOption.securityType6G,
        WifiSettingOption.securityTypeBelow6G
      ]);
    } else {
      options.insertAll(1, [
        WifiSettingOption.securityType
      ]);
    }

    return options;
  }
}

enum WifiSettingOption {
  nameAndPassword(displayTitle: 'WiFi name and password'),
  securityType(displayTitle: 'Security type'),
  securityType6G(displayTitle: 'Security type (6GHz)'),
  securityTypeBelow6G(displayTitle: 'Security type (5GHz, 2.4GHz)'),
  mode(displayTitle: 'WiFi mode');

  const WifiSettingOption({required this.displayTitle});

  final String displayTitle;
}

enum WifiSecurityType {
  wpa2(displayTitle: 'WPA2 Personal'),
  wpa3(displayTitle: 'WPA3 Personal'),
  wpa2Wpa3Mixed(displayTitle: 'WPA2/WPA3 Mixed Personal'),
  enhancedOpen(displayTitle: 'Enhanced Open Only'),
  openAndEnhancedOpen(displayTitle: 'Open and Enhanced Open'),
  open(displayTitle: 'Open');

  const WifiSecurityType({required this.displayTitle});

  final String displayTitle;

  static List<WifiSecurityType> get allTypes {
    return [
      WifiSecurityType.wpa2,
      WifiSecurityType.wpa3,
      WifiSecurityType.wpa2Wpa3Mixed,
      WifiSecurityType.enhancedOpen,
      WifiSecurityType.openAndEnhancedOpen,
      WifiSecurityType.open,
    ];
  }
}

enum WifiMode {
  mixed(displayTitle: 'Mixed'),
  bg(displayTitle: 'bg'),
  bgn(displayTitle: 'bgn');

  const WifiMode({required this.displayTitle});

  final String displayTitle;

  static List<WifiMode> get allModes {
    return [
      WifiMode.mixed,
      WifiMode.bg,
      WifiMode.bgn,
    ];
  }
}
