import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/icons/icon_rules.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/animation/hover.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/container/stacked_listview.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class DashboardHomeView extends ConsumerStatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends ConsumerState<DashboardHomeView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) => AppPageView.noNavigationBar(
        scrollable: true,
        padding: const AppEdgeInsets.only(
          top: AppGapSize.big,
          left: AppGapSize.regular,
          right: AppGapSize.regular,
          bottom: AppGapSize.regular,
        ),
        child: Stack(
          children: [
            Hover(
              reverse: false,
              begin: const Offset(1, 0),
              end: const Offset(-1.5, 0),
              duration: const Duration(milliseconds: 5000),
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
            const AppGap.semiSmall(),
            Expanded(
              child: AppText.subhead(
                state.selected?.radioInfo?.first.settings.ssid ?? 'Home',
              ),
            ),
            AppIconButton(
              icon: getCharactersIcons(context).bellDefault,
              onTap: () {
                ref.read(navigationsProvider.notifier).push(LinkupPath());
              },
            ),
          ],
        ),
        const AppGap.big(),
        Row(
          children: const [
            AppText.screenName(
              'Internet ',
            ),
            AppText.screenName(
              'online',    //TODO: XXXXXX Get online status
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
          const AppGap.extraBig(),
          _nodesInfoTile(state),
          const AppGap.extraBig(),
          _devicesInfoTile(state),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(NetworkState state) {
    if (state.selected?.radioInfo == null) {
      return CircularProgressIndicator(
        color: AppTheme.of(context).colors.textBoxText,
      );
    }

    int wifiCount = _getWifiCount(state.selected);
    List<Widget> icons = [];
    for (int i = 0; i < wifiCount; i++) {
      icons.add(_circleIcon(
        //TODO: XXXXXX Get wifi signal
          image: const AssetImage('assets/images/wifi_signal_3.png')));
    }
    return _infoTile(
      count: wifiCount,
      descripition: 'WiFi networks active',  //TODO: XXXXXX Get active status??
      icons: icons,
      onTap: () {
        ref.read(navigationsProvider.notifier).push(WifiListPath());
      },
    );
  }

  Widget _nodesInfoTile(NetworkState state) {
    if (state.selected?.devices == null) {
      return CircularProgressIndicator(
        color: AppTheme.of(context).colors.textBoxText,
      );
    }

    final nodes = _getRouters(state.selected?.devices);
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
      descripition: 'Nodes online',  //TODO: XXXXXX Get Node online status
      icons: icons,
      onTap: () {
        ref.read(navigationsProvider.notifier).push(TopologyPath());
      },
    );
  }

  Widget _devicesInfoTile(NetworkState state) {
    if (state.selected?.devices == null) {
      return CircularProgressIndicator(
        color: AppTheme.of(context).colors.textBoxText,
      );
    }

    List<RouterDevice> connectedDevices =
        _getConnectedDevice(state.selected?.devices);
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
      descripition: 'Devices online',  //TODO: XXXXXX which online deivce??
      icons: icons,
      onTap: () {
        ref.read(navigationsProvider.notifier).push(DeviceListPath());
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
    return LinksysStackedListView(
      itemExtent: 48,
      widthFactor: 0.5,
      items: widgets,
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
              AppText.mainTitle(count.toString()),
              const AppGap.regular(),
              Expanded(child: _iconStack(icons)),
            ],
          ),
        ),
        const AppGap.semiSmall(),
        Row(
          children: [
            // const SizedBox(width: 3),
            AppIcon(
              //TODO: XXXXXX Check for what??
              icon: getCharactersIcons(context).checkRound,
              color: ConstantColors.secondaryElectricGreen,
            ),
            const AppGap.semiSmall(),
            AppText.descriptionSub(descripition),
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
                  ref.read(navigationsProvider.notifier).push(SpeedCheckPath());
                },
                child: const CircleAvatar(
                  radius: 21,
                  backgroundColor: ConstantColors.primaryLinksysBlue,
                  child: AppText.textLinkSmall(
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
            AppText.screenName(num),
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
}
