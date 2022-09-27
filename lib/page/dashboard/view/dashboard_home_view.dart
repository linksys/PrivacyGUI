import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/profiles.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/chart/LineChartSample.dart';
import 'package:linksys_moab/route/model/devices_path.dart';
import 'package:linksys_moab/route/model/nodes_path.dart';
import 'package:linksys_moab/route/model/profile_group_path.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';

import '../../../route/navigation_cubit.dart';

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _homeTitle(),
          SizedBox(height: 32),
          _basicTiles(),
          SizedBox(height: 32),
          _speedTestTile(2048000, 1024000),
          SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              NavigationCubit.of(context).push(DeviceListPath());
            },
            child: _usageTile(28),
          ),
          SizedBox(height: 32),
          _profileTile(),
          SizedBox(height: 64),
          Text(
            "Send feedback",
            style: Theme.of(context)
                .textTheme
                .headline2
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            "We love hearing from you",
            style: Theme.of(context).textTheme.headline3,
          ),
        ],
      ),
    );
  }

  Widget _homeTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/dashboard_home.png'),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                'Home',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
                textAlign: TextAlign.start,
              ),
            ),
            Image.asset(
              'assets/images/icon_noti_ring.png',
              width: 24,
              height: 24,
            )
          ],
        ),
        Text(
          'Internet looks good!',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(fontWeight: FontWeight.w700),
        )
      ],
    );
  }

  Widget _basicTiles() {
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
                    Text('2',
                        style: Theme.of(context).textTheme.headline1?.copyWith(
                            fontSize: 32, fontWeight: FontWeight.w400)),
                    Text('active', style: Theme.of(context).textTheme.headline3)
                  ],
                ),
              ),
            ),
            _blockTile(
              'NODES',
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  NavigationCubit.of(context).push(TopologyPath());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3',
                        style: Theme.of(context).textTheme.headline1?.copyWith(
                            fontSize: 32, fontWeight: FontWeight.w400)),
                    Text('online', style: Theme.of(context).textTheme.headline3)
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _speedTestTile(int downloadMbps, int uploadMbps) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SPEED TEST'),
        SizedBox(
          height: 8,
        ),
        Container(
          width: double.infinity,
          height: 100,
          child: Card(
            color: MoabColor.dashboardTileBackground,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                            child: _speedItem(
                                downloadMbps, Icon(Icons.arrow_downward))),
                        Expanded(
                            child: _speedItem(
                                uploadMbps, Icon(Icons.arrow_upward)))
                      ],
                    ),
                  ),
                  Text('a week ago',
                      style: Theme.of(context).textTheme.headline2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _speedItem(int speed, Icon icon) {
    return Row(
      children: [
        icon,
        Text(
          Utils.formatBytes(speed),
          style: Theme.of(context).textTheme.headline2,
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
          Text(title),
          SizedBox(
            height: 8,
          ),
          Container(
            width: double.infinity,
            child: Card(
              color: MoabColor.dashboardTileBackground,
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
        Text('USAGE & DEVICES'),
        SizedBox(
          height: 8,
        ),
        Container(
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
                    Text('$deviceCount',
                        style: Theme.of(context).textTheme.headline1?.copyWith(
                            fontSize: 32, fontWeight: FontWeight.w500)),
                    Text('Devices online',
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w700))
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
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
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
                      NavigationCubit.of(context).push(CreateProfileNamePath());
                    } else {
                      logger.d('profile clicked: $index');
                      context
                          .read<ProfilesCubit>()
                          .selectProfile(state.profileList[index]);
                      NavigationCubit.of(context).push(ProfileOverviewPath());
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
    });
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

  Widget _profileItem(GroupProfile profile) {
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
}
