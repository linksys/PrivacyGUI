import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';


class ChangeDeviceAvatarView extends ArgumentsConsumerStatefulView {
  const ChangeDeviceAvatarView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ChangeDeviceAvatarView> createState() =>
      __ChangeDeviceAvatarViewState();
}

class __ChangeDeviceAvatarViewState
    extends ConsumerState<ChangeDeviceAvatarView> {
  bool isChanged = false;
  // late List<dynamic> avatars;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalDeviceDetailProvider);
    // avatars = getAllDeviceAvatars();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width >= 700
          ? 5
          : width >= 500
              ? 4
              : 3;
      return StyledAppPageView(
        title: getAppLocalizations(context).device_name,
        child: AppBasicLayout(
          content: Column(children: [
            _deviceAvatar(state.item.icon),
            const AppGap.big(),
            _deviceAvatarGrid(crossAxisCount: crossAxisCount),
          ]),
        ),
      );
    });
  }

  Widget _deviceAvatar(String iconName) {
    return AppDeviceAvatar.extraLarge(
      image: CustomTheme.of(context).images.devices.getByName(iconName),
    );
  }

  Widget _deviceAvatarGrid({required int crossAxisCount}) {
    return Expanded(
        child: GridView.builder(
      physics: const ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, childAspectRatio: (3 / 2)),
      itemCount: deviceAvatarNameList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            context.pop(deviceAvatarNameList[index]);
          },
          child: AppDeviceAvatar.large(
              image: CustomTheme.of(context)
                  .images
                  .devices
                  .getByName(deviceAvatarNameList[index])),
        );
      },
    ));
  }

  // List<dynamic> getAllDeviceAvatars() {
  //   var list = [];
  //   for (var element in deviceAvatarNameList) {
  //     list.add(AppTheme.of(context).images.devices.getByName(element));
  //   }
  //   return list;
  // }
}

const deviceAvatarNameList = [
  'amazonShow',
  'dvr',
  'desktopMac',
  'tabletEreader',
  'smartSmokeDetector',
  'routerNodes',
  'linksysVelop',
  'smartphoneAndroid',
  'wemoDimmer',
  'application',
  'wemoSocket',
  'gameConsoles',
  'ipadProBlack',
  'wemoMini',
  'photoFrame',
  'genericCamera',
  'serverPc',
  'appleHomepod',
  'soundformElite',
  'amazonTap',
  'smartphoneMac',
  'phynPlus',
  'genericDisplay',
  'petFeeder',
  'smartLock',
  'routerWhw01',
  'routerEa2700',
  'digitalCamera',
  'wemoDevice',
  'tabletPc',
  'printerLaser',
  'amazonEcho',
  'powerStrip',
  'fanCeiling',
  'printer3D',
  'appleTimeCapsule',
  'routerMr7350',
  'routerEa8300',
  'wiredBridge',
  'smartCrockpot',
  'genericDevice',
  'amazonSpot',
  'printerInkjet',
  'mediaAdapter',
  'smartphone',
  'linksysExtender',
  'routerEa6100',
  'smartMrcoffee',
  'routerMx6200',
  'routerEa8500',
  'appleWatch',
  'routerEa4500',
  'amazonFiretvCube',
  'routerWhw03b',
  'amazonDot',
  'routerEa9350',
  'genericTablet',
  'nodeIcon',
  'setTopBox',
  'smartValve',
  'netDrive',
  'smartThermostat',
  'routerEa6300',
  'vrHeadset',
  'routerEa9200',
  'routerEa7500v3',
  'androidWhite',
  'wemoLedbulb',
  'node',
  'googleHomeMini',
  'mediaStick',
  'soundformEliteWhite',
  'wemoLink',
  'routerEa2750',
  'automationHub',
  'genericRemote',
  'appleTv',
  'ipadProWhite',
  'genericRobot',
  'routerWhw01p',
  'fanSmall',
  'genericDrone',
  'laptopMac',
  'routerMx5300',
  'wemoMaker',
  'phynAssistant',
  'desktopPc',
  'routerEa6900',
  'voipPhone',
  'routerEa3500',
  'routerEa7200',
  'nestCam',
  'printServer',
  'smartSprinkler',
  'serverMac',
  'routerDefault',
  'routerWrt1900ac',
  'genericTabletWhite',
  'smartVacuum',
  'wemoLightswitch',
  'routerWhw01b',
  'routerEa7500',
  'soundBar',
  'gateway',
  'routerWrt1200ac',
  'googleHome',
  'laptopPc',
  'smartSpeaker',
  'whirlpoolFridge',
  'routerMr7500',
  'wemoInsight',
  'routerMr6350',
  'tvHdtv',
  'deviceRouter',
  'doorbellCam',
  'wemoNetcam',
  'routerEa9300',
  'group2',
  'routerEa6350',
  'chromecast',
  'printerPhoto',
  'smartCar',
  'digitalMediaPlayer',
  'wemoOutdoorPlug',
  'securitySystem',
  'tabletMac',
  'routerEa9500',
  'smartScale',
  'group5',
  'linksysBridge',
  'smartWatch',
  'routerEa6350v4',
  'genericCellphone',
  'airPurifier',
  'wemoSensor',
  'netCamera',
  'nestHello',
];
