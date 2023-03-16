import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_moab/page/components/shortcuts/profiles.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/chart/LineChartSample.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
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
              child: EnabledOpacityWidget(
                enabled: state.selected?.deviceInfo != null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _homeTitle(state),
                    const LinksysGap.semiBig(),
                    _basicTiles(state),
                    const LinksysGap.semiBig(),
                    _speedTestTile(state),
                    const LinksysGap.semiBig(),
                    GestureDetector(
                      onTap: () {
                        NavigationCubit.of(context).push(DeviceListPath());
                      },
                      child: _usageTile(
                          getConnectionDeviceCount(state.selected?.devices)),
                    ),
                    const LinksysGap.big(),
                    const LinksysText.textLinkSmall(
                      "Send feedback",
                    ),
                    const LinksysText.descriptionMain(
                      "We love hearing from you",
                    ),
                  ],
                ),
              ),
            ));
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
              child: LinksysText.screenName(
                state.selected?.radioInfo?.first.settings.ssid ?? 'Home',
              ),
            ),
            AppIcon(
              icon: getCharactersIcons(context).bellDefault,
              size: AppIconSize.big,
            ),
          ],
        ),
        const LinksysText.descriptionMain(
          'Internet looks good!',
        )
      ],
    );
  }

  Widget _basicTiles(NetworkState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _blockTile(
              'WIFI',
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  NavigationCubit.of(context).push(WifiListPath());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinksysText.subhead(
                      getWifiCount(state.selected),
                    ),
                    const LinksysText.subhead(
                      'active',
                    )
                  ],
                ),
              ),
            ),
            _blockTile(
              'ROUTER + NODES',
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  NavigationCubit.of(context).push(TopologyPath());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinksysText.subhead(
                      getRouterCount(state.selected?.devices),
                    ),
                    const LinksysText.subhead(
                      'online',
                    )
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _speedTestTile(NetworkState state) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        NavigationCubit.of(context).push(SpeedCheckPath());
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinksysText.label('SPEED TEST'),
          const LinksysGap.semiSmall(),
          SizedBox(
            width: double.infinity,
            height: 100,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _speedResult(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedResult(NetworkState state) {
    final healthCheckResults = state.selected?.healthCheckResults;
    if (healthCheckResults != null && healthCheckResults.isNotEmpty) {
      final result = context
          .read<NetworkCubit>()
          .getLatestHealthCheckResult(healthCheckResults);
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
                        result.speedTestResult?.downloadBandwidth ?? 0,
                        AppIcon(icon: getCharactersIcons(context).arrowDown))),
                Expanded(
                    child: _speedItem(
                        result.speedTestResult?.uploadBandwidth ?? 0,
                        AppIcon(icon: getCharactersIcons(context).arrowUp))),
              ],
            ),
          ),
          LinksysText.label(
            DateFormat("yyyy-MM-dd hh:mm:ss").format(
              DateFormat("yyyy-MM-ddThh:mm:ssZ")
                  .parseUTC(result.timestamp)
                  .toLocal(),
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: LinksysText.textLinkLarge('Run Speed Test'),
      );
    }
  }

  Widget _speedItem(int speed, AppIcon icon) {
    return Row(
      children: [
        icon,
        LinksysText.label(
          Utils.formatBytes(speed),
        )
      ],
    );
  }

  Widget _blockTile(String title, Widget content) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinksysText.label(title),
          const LinksysGap.semiSmall(),
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageTile(int deviceCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LinksysText.label('USAGE & DEVICES'),
        const LinksysGap.semiSmall(),
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            children: [
              LineChartSample(),
              Container(
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.only(left: 10, bottom: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinksysText.mainTitle(
                      '$deviceCount',
                    ),
                    LinksysText.subhead(
                      'Devices online',
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileTile() {
    final authBloc = context.read<AuthBloc>();
    return authBloc.isCloudLogin()
        ? BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROFILES'),
                box8(),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    itemBuilder: (context, index) => InkWell(
                        onTap: () {
                          if (index == state.profileList.length) {
                            logger.d('add profile clicked: $index');
                            //TODO: Check the next args
                            NavigationCubit.of(context)
                                .push(CreateProfileNamePath());
                          } else {
                            logger.d('profile clicked: $index');
                            context
                                .read<ProfilesCubit>()
                                .selectProfile(state.profileList[index]);
                            NavigationCubit.of(context)
                                .push(ProfileOverviewPath());
                          }
                        },
                        child: index == state.profileList.length
                            ? _profileAdd()
                            : _profileItem(state.profileList[index])),
                    separatorBuilder: (_, __) => box16(),
                    itemCount: state.profileList.length + 1,
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                  ),
                ),
              ],
            );
          })
        : const Center();
  }

  Widget _profileAdd() {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: MoabColor.dashboardTileBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add),
    );
  }

  Widget _profileItem(UserProfile profile) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
          color: MoabColor.dashboardTileBackground,
          borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: profileTileShort(context, profile),
      ),
    );
  }

  String getWifiCount(MoabNetwork? network) {
    if (network == null) return '0';

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
    return count.toString();
  }

  String getRouterCount(List<RouterDevice>? devices) {
    int routerCount = 0;
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (device.isAuthority || device.nodeType != null) {
          routerCount += 1;
        }
      }
    }
    return routerCount.toString();
  }

  int getConnectionDeviceCount(List<RouterDevice>? devices) {
    int deviceCount = 0;
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (!device.isAuthority && device.nodeType == null) {
          if (device.connections.isNotEmpty) {
            deviceCount += 1;
          }
        }
      }
    }

    return deviceCount;
  }
}
