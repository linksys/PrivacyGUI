import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moab_poc/design/colors.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/utils.dart';

class Profile {
  const Profile({required this.name, required this.icon});

  final String name;
  final String icon;
}

final _mockProfiles = [
  Profile(
    name: 'Eric',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  Profile(
    name: 'Timmy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  Profile(
    name: 'Mandy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  Profile(
    name: 'Dad',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  Profile(
    name: 'Peter',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  Profile(
    name: 'Austin',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
];

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      padding: EdgeInsets.zero,
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
          _usageTile(28),
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
                    ?.copyWith(fontSize: 32, fontWeight: FontWeight.w400),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2',
                      style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('active', style: Theme.of(context).textTheme.headline3)
                ],
              ),
            ),
            _blockTile(
              'NODES',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3',
                      style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('online', style: Theme.of(context).textTheme.headline3)
                ],
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
          height: 160,
          child: Card(
            color: MoabColor.dashboardTileBackground,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('assets/images/img_fake_usage.png'),
                fit: BoxFit.cover,
              )),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$deviceCount',
                      style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w500)),
                  Text('Devices online',
                      style: Theme.of(context)
                          .textTheme
                          .headline3
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700))
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileTile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROFILES'),
        SizedBox(
          height: 8,
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            itemBuilder: (context, index) => _profileItem(_mockProfiles[index]),
            separatorBuilder: (_, __) => SizedBox(
              width: 16,
            ),
            itemCount: _mockProfiles.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _profileItem(Profile profile) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
          color: MoabColor.dashboardTileBackground,
          borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Image.asset(
                profile.icon,
                width: 32,
                height: 32,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.bodyText1,
              )
            ],
          ),
        ),
      ),
    );
  }
}
