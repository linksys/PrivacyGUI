import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/icons/icon_rules.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  @override
  void initState() {
    super.initState();

    context.read<NetworkCubit>().pollingData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) => LinksysPageView.noNavigationBar(
        scrollable: true,
        padding: const LinksysEdgeInsets.only(
          top: AppGapSize.big,
          left: AppGapSize.regular,
          right: AppGapSize.regular,
          bottom: AppGapSize.regular,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -0, // negative value to position the image out of screen
              top: -50, // negative value to position the image out of screen
              child: Image(
                image: AppTheme.of(context).images.dashboardBg,
                fit: BoxFit.cover, // to cover the entire screen
              ),
            ),
            EnabledOpacityWidget(
              enabled: state.selected?.deviceInfo != null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _homeTitle(state),
                  const LinksysGap.big(),
                  _networkInfoTiles(state),
                  const LinksysGap.extraBig(),
                  _speedTestTile(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTitle(NetworkState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppIcon(
              icon: getCharactersIcons(context).homeDefault,
              size: AppIconSize.big,
            ),
            const LinksysGap.semiSmall(),
            Expanded(
              child: LinksysText.subhead(
                state.selected?.radioInfo?.first.settings.ssid ?? 'Home',
              ),
            ),
            AppIcon(
              icon: getCharactersIcons(context).bellDefault,
              size: AppIconSize.big,
            ),
          ],
        ),
        const LinksysGap.big(),
        Row(
          children: const [
            LinksysText.screenName(
              'Internet ',
            ),
            LinksysText.screenName(
              'online',
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
          const LinksysGap.extraBig(),
          _nodesInfoTile(state),
          const LinksysGap.extraBig(),
          _devicesInfoTile(state),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(NetworkState state) {
    int wifiCount = getWifiCount(state.selected);
    List<Widget> icons = [];
    for (int i = 0; i < wifiCount; i++) {
      icons.add(_circleIcon(
          image: const AssetImage('assets/images/wifi_signal_3.png')));
    }
    return _infoTile(
      count: wifiCount,
      descripition: 'WiFi networks active',
      icons: icons,
      onTap: () {
        NavigationCubit.of(context).push(WifiListPath());
      },
    );
  }

  Widget _nodesInfoTile(NetworkState state) {
    final nodes = getRouters(state.selected?.devices);
    List<Widget> icons = [];
    for (int i = 0; i < nodes.length; i++) {
      final image =
          AppTheme.of(context).images.devices.getByName(routerIconTest(
                modelNumber: nodes[i].model.modelNumber ?? '',
                hardwareVersion: nodes[i].model.hardwareVersion,
              ));
      icons.add(_circleIcon(
        image: image,
      ));
    }
    return _infoTile(
      count: nodes.length,
      descripition: 'Nodes online',
      icons: icons,
      onTap: () {
        NavigationCubit.of(context).push(TopologyPath());
      },
    );
  }

  Widget _devicesInfoTile(NetworkState state) {
    List<RouterDevice> connectedDevices =
        getConnectedDevice(state.selected?.devices);
    List<Widget> icons = [];
    for (RouterDevice device in connectedDevices) {
      icons.add(_circleIcon(
          image: AppTheme.of(context)
              .images
              .devices
              .getByName(iconTest(device.toJson()))));
    }
    return _infoTile(
      count: connectedDevices.length,
      descripition: 'Devices online',
      icons: icons,
      onTap: () {
        NavigationCubit.of(context).push(DeviceListPath());
      },
    );
  }

  Widget _circleIcon({ImageProvider? image, SvgPicture? svgPicture}) {
    // Check input only one kind of image
    assert(image != null || svgPicture != null);
    assert(!(image != null && svgPicture != null));

    Widget child = Container();
    final _image = image;
    if (_image != null) {
      child = Image(
        image: _image,
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
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        for (var index = 0; index < widgets.length; index++)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              widgets[index],
              SizedBox(
                width: 23.0 * index,
              ),
            ],
          ),
      ],
    );
  }

  Widget _infoTile(
      {int count = 0,
      String descripition = '',
      List<Widget> icons = const [],
      VoidCallback? onTap}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              LinksysText.mainTitle(count.toString()),
              const LinksysGap.regular(),
              _iconStack(icons),
            ],
          ),
        ),
        const LinksysGap.semiSmall(),
        Row(
          children: [
            // const SizedBox(width: 3),
            AppIcon(
              icon: getCharactersIcons(context).checkRound,
              color: ConstantColors.secondaryElectricGreen,
            ),
            const LinksysGap.semiSmall(),
            LinksysText.descriptionSub(descripition),
          ],
        ),
      ],
    );
  }

  Widget _speedTestTile(NetworkState state) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 13.0),
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
      final result = context
          .read<NetworkCubit>()
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  NavigationCubit.of(context).push(SpeedCheckPath());
                },
                child: const CircleAvatar(
                  radius: 21,
                  backgroundColor: ConstantColors.primaryLinksysBlue,
                  child: LinksysText.textLinkSmall(
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
            const LinksysGap.semiSmall(),
            LinksysText.screenName(num),
          ],
        ),
        Text('${text}ps'),
      ],
    );
  }

  int getWifiCount(MoabNetwork? network) {
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

  List<RouterDevice> getRouters(List<RouterDevice>? devices) {
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

  List<RouterDevice> getConnectedDevice(List<RouterDevice>? devices) {
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
}
