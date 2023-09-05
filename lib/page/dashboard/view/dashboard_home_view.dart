import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/network.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/smart_device_prefs_helper.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/container/stacked_listview.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardHomeView extends ConsumerStatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends ConsumerState<DashboardHomeView> {
  @override
  void initState() {
    super.initState();
    _pushNotificationCheck();
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(deviceManagerProvider);
    //TODO: Replace the data source with the one from device manager
    final state = ref.watch(networkProvider);
    return AppPageView(
      appBar: LinksysAppBar(
        trailing: [
          AppIconButton.noPadding(
              icon: getCharactersIcons(context).refreshDefault)
        ],
      ),
      scrollable: true,
      padding: const AppEdgeInsets.only(
        top: AppGapSize.big,
        left: AppGapSize.regular,
        right: AppGapSize.regular,
        bottom: AppGapSize.regular,
      ),
      child: Stack(
        children: [
          Image(
            image: AppTheme.of(context).images.dashboardBg,
            fit: BoxFit.cover, // to cover the entire screen
          ),
          EnabledOpacityWidget(
            enabled: state.selected?.deviceInfo != null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _homeTitle(state),
                const AppGap.big(),
                _networkInfoTiles(state),
                const AppGap.extraBig(),
                _speedTestTile(state),
              ],
            ),
          ),
          if (state.selected?.devices == null) const AppFullScreenSpinner(),
        ],
      ),
    );
  }

  Widget _homeTitle(NetworkState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppText.displaySmall(
          state.selected?.radioInfo?.first.settings.ssid ?? 'Home',
        ),
        AppGap.regular(),
        const Row(
          children: [
            AppText.titleLarge(
              'Internet ',
            ),
            AppText.titleLarge(
              'online', //TODO: XXXXXX Get online status
              color: ConstantColors.primaryLinksysBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _networkInfoTiles(NetworkState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wifiInfoTile(state),
          const AppGap.regular(),
          _nodesInfoTile(state),
          const AppGap.regular(),
          _devicesInfoTile(state),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(NetworkState state) {
    if (state.selected?.radioInfo == null) {
      return CircularProgressIndicator();
    }

    int wifiCount = _getWifiCount(state.selected);
    List<Widget> icons = [];
    for (int i = 0; i < wifiCount; i++) {
      icons.add(_circleIcon(
          //TODO: XXXXXX Get wifi signal
          image: const AssetImage('assets/images/wifi_signal_3.png')));
    }
    return _infoTile(
      iconData: getCharactersIcons(context).wifiDefault,
      text: 'WiFi ($wifiCount)',
      onTap: () {
        context.pushNamed(RouteNamed.wifiShare);
      },
    );
  }

  Widget _nodesInfoTile(NetworkState state) {
    if (state.selected?.devices == null) {
      return CircularProgressIndicator();
    }

    final nodes = _getRouters(state.selected?.devices);
    List<Widget> icons = [];

    final image = AppTheme.of(context).images.devices.getByName(routerIconTest(
          modelNumber: nodes.first.model.modelNumber ?? '',
          hardwareVersion: nodes.first.model.hardwareVersion,
        ));
    return _infoTile(
      image: image,
      text: 'Nodes (${nodes.length})',
      onTap: () {
        context.pushNamed(RouteNamed.settingsNodes);
      },
    );
  }

  Widget _devicesInfoTile(NetworkState state) {
    if (state.selected?.devices == null) {
      return CircularProgressIndicator();
    }

    List<RouterDevice> connectedDevices =
        _getConnectedDevice(state.selected?.devices);

    return _infoTile(
      text:
          '${connectedDevices.length} devices online', //TODO: XXXXXX which online deivce??
      iconData: getCharactersIcons(context).devicesDefault,
      onTap: () {
        context.goNamed(RouteNamed.dashboardDevices);
      },
    );
  }

  Widget _circleIcon({ImageProvider? image, SvgPicture? svgPicture}) {
    // Check input only one kind of image
    assert(image != null || svgPicture != null);
    assert(!(image != null && svgPicture != null));

    Widget child = Container();
    final image0 = image;
    if (image0 != null) {
      child = Image(
        image: image0,
        width: 30,
        height: 30,
      );
    } else {
      child = svgPicture!;
    }
    return CircleAvatar(
      radius: 23,
      backgroundColor: ConstantColors.secondaryClearBlue,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: child,
      ),
    );
  }

  Widget _iconStack(List<Widget> widgets) {
    return LinksysStackedListView(
      itemExtent: 48,
      widthFactor: 0.5,
      items: widgets,
    );
  }

  Widget _infoTile({
    required String text,
    IconData? iconData,
    ImageProvider? image,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          AppCard(
            iconData: iconData,
            image: image,
          ),
          const AppGap.regular(),
          AppText.labelLarge(text)
        ],
      ),
    );
  }

  Widget _speedTestTile(NetworkState state) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: AppPadding(
          padding: const AppEdgeInsets.symmetric(
              horizontal: AppGapSize.regular, vertical: AppGapSize.semiSmall),
          child: _speedResult(state),
        ),
      ),
    );
  }

  Widget _speedResult(NetworkState state) {
    final healthCheckResults = state.selected?.healthCheckResults;
    int uploadBandwidth = 0;
    int downloadBandwidth = 0;
    if (healthCheckResults != null && healthCheckResults.isNotEmpty) {
      final result = ref
          .read(networkProvider.notifier)
          .getLatestHealthCheckResult(healthCheckResults);
      uploadBandwidth = result.speedTestResult?.uploadBandwidth ?? 0;
      downloadBandwidth = result.speedTestResult?.downloadBandwidth ?? 0;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: _speedItem(
                      uploadBandwidth,
                      AppIcon(
                        icon: getCharactersIcons(context).arrowUp,
                        color: ConstantColors.secondaryCyberPurple,
                      ))),
              Expanded(
                  child: _speedItem(
                      downloadBandwidth,
                      AppIcon(
                        icon: getCharactersIcons(context).arrowDown,
                        color: ConstantColors.secondaryCyberPurple,
                      ))),
              GestureDetector(
                onTap: () {
                  // GoRouter helath check
                },
                child: const CircleAvatar(
                  radius: 21,
                  backgroundColor: ConstantColors.primaryLinksysBlue,
                  child: AppText.labelLarge(
                    'Go',
                    color: ConstantColors.primaryLinksysWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _speedItem(int speed, AppIcon icon) {
    String num = '0';
    String text = 'b';
    // The speed is in kilobits per second
    String speedText = Utils.formatBytes(speed * 1024);
    num = speedText.split(' ').first;
    text = speedText.split(' ').last;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const AppGap.semiSmall(),
            AppText.titleLarge(num),
          ],
        ),
        Text('${text}ps'),
      ],
    );
  }

  int _getWifiCount(MoabNetwork? network) {
    if (network == null) return 0;

    int count = 0;
    final radioInfo = network.radioInfo;
    if (radioInfo != null && radioInfo.isNotEmpty) {
      Map<String, bool> wifiMap = {};
      for (RouterRadioInfo info in radioInfo) {
        wifiMap[info.settings.ssid] = true;
      }
      count = wifiMap.length;
    }
    if (network.guestRadioSetting != null &&
        network.guestRadioSetting!.isGuestNetworkEnabled) {
      count += 1;
    }
    if (network.iotNetworkSetting != null &&
        network.iotNetworkSetting!.isIoTNetworkEnabled) {
      count += 1;
    }
    return count;
  }

  List<RouterDevice> _getRouters(List<RouterDevice>? devices) {
    List<RouterDevice> list = [];
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (device.isAuthority || device.nodeType != null) {
          list.add(device);
        }
      }
    }
    return list;
  }

  List<RouterDevice> _getConnectedDevice(List<RouterDevice>? devices) {
    List<RouterDevice> connectedDevices = [];
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (!device.isAuthority && device.nodeType == null) {
          if (device.connections.isNotEmpty) {
            connectedDevices.add(device);
          }
        }
      }
    }

    return connectedDevices;
  }

  void _pushNotificationCheck() {
    if (!mounted) {
      return;
    }
    if (GoRouter.of(context).routerDelegate.currentConfiguration.fullPath !=
        RoutePath.dashboardHome) {
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      final isPushPromptShown = prefs.getBool(
              SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt)) ??
          false;
      if (!isPushPromptShown) {
        prefs.setBool(
            SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt),
            true);
        showAdaptiveDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: AppText.bodyLarge('Push Notification'),
            content: AppText.bodyLarge(
                'Do you want to receive Linksys push notifications?'),
            actions: [
              AppTertiaryButton(
                'Yes',
                onTap: () {
                  final deviceToken = prefs.getString(pDeviceToken);
                  if (deviceToken != null) {
                    ref
                        .read(smartDeviceProvider.notifier)
                        .registerSmartDevice(deviceToken);
                  } else {}
                  context.pop();
                },
              ),
              AppTertiaryButton('No', onTap: () {
                context.pop();
              })
            ],
          ),
        );
      }
    });
  }
}
