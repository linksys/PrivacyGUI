import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class DashboardSecurityView extends StatefulWidget {
  const DashboardSecurityView({Key? key}) : super(key: key);

  @override
  State<DashboardSecurityView> createState() => _DashboardSecurityViewState();
}

class _DashboardSecurityViewState extends State<DashboardSecurityView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _securityStatus(),
          _cyberthreatsTile(),
          _divider(),
          _contentFilterTile(),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
          textAlign: TextAlign.start,
        ),
        const SizedBox(
          height: 32,
        ),
      ],
    );
  }

  Widget _securityStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Linksys Security',
              style: Theme.of(context)
                  .textTheme
                  .headline2
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                'assets/images/icon_checked_circle.png',
                width: 16,
                height: 16,
              ),
            ),
            Text(
              'Active',
              style: Theme.of(context)
                  .textTheme
                  .headline2
                  ?.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          'This week',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _cyberthreatsTile() {
    final screenWidth = MediaQuery.of(context).size.width - (24 * 2);
    final tileHeight = (screenWidth - 14) / 2 / 1.75 * 2 + 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleWithIcons(
          text: Text(
            'Cyberthreats blocked',
            style: Theme.of(context)
                .textTheme
                .headline3
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          leadingIcon: Image.asset('assets/images/security_good_small.png'),
          trailingIcon: IconButton(
            icon: Image.asset(
              'assets/images/icon_info.png',
              height: 26,
              width: 26,
            ),
            onPressed: () {},
          ),
        ),
        SizedBox(
          height: tileHeight,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.75,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              InfoBlockWidget(
                count: 3,
                text: 'Virus',
              ),
              InfoBlockWidget(
                count: 6,
                text: 'Ransomware & Malware',
              ),
              InfoBlockWidget(
                count: 11,
                text: 'Botnet',
              ),
              InfoBlockWidget(
                count: 4,
                text: 'Malicious websites',
              ),
            ],
          ),
        ),
        box8(),
        Text(
          '924 total inspections performed',
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _contentFilterTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleWithIcons(
          text: Text(
            'Content filtered',
            style: Theme.of(context)
                .textTheme
                .headline3
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          leadingIcon: Image.asset('assets/images/icon_block.png'),
          trailingIcon: IconButton(
            icon: Image.asset(
              'assets/images/icon_info.png',
              height: 26,
              width: 26,
            ),
            onPressed: () {},
          ),
        ),
        const InfoBlockWidget(
          count: 21,
          text: 'Blocked content this week',
          isVertical: false,
          height: 60,
        ),
        box4(),
        _buildContentFilteredProfile(),
        Text(
          'Fortinet threat database',
          style: Theme.of(context).textTheme.headline4?.copyWith(
            fontWeight: FontWeight.w700
          ),
        ),
        Text(
          'Last updated on Aug 15, 2022',
          style: Theme.of(context).textTheme.headline4?.copyWith(
              fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }

  Widget _buildContentFilteredProfile() {
    final _mockProfiles = context.read<ProfilesCubit>().state.profileList;
    final double listHeight = _mockProfiles.length * 80;
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mockProfiles.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1),
            ),
            leading: Image.asset(
              _mockProfiles[index].icon,
              width: 32,
              height: 32,
            ),
            title: Text(
              _mockProfiles[index].name,
              style: Theme.of(context).textTheme.bodyText1?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        height: 1,
        color: MoabColor.black,
      ),
    );
  }
}

class TitleWithIcons extends StatelessWidget {
  TitleWithIcons({
    Key? key,
    required this.text,
    this.leadingIcon,
    this.trailingIcon,
  }): super(key: key){
    if(leadingIcon != null) {
      _widgets.add(leadingIcon!);
      _widgets.add(box8());
    }
    _widgets.add(Expanded(
      child: text,
    ));
    if(trailingIcon != null) {
      _widgets.add(trailingIcon!);
    }
  }

  final Widget text;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final List<Widget> _widgets = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: _widgets,
      ),
    );
  }
}

class InfoBlockWidget extends StatelessWidget {
  const InfoBlockWidget({
    Key? key,
    required this.count,
    required this.text,
    this.color = MoabColor.dashboardBottomBackground,
    this.isVertical = true,
    this.height = 0,
  }) : super(key: key);

  final Color color;
  final int count;
  final String text;
  final bool isVertical;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(12),
      child: isVertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _content(context),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: _content(context,
                  space: const SizedBox(
                    width: 16,
                  )),
            ),
    );
  }

  List<Widget> _content(BuildContext context,
      {SizedBox space = const SizedBox(
        height: 0,
      )}) {
    return [
      Text('$count',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(fontSize: 25, fontWeight: FontWeight.w400)),
      space,
      Text(text,
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(fontWeight: FontWeight.w700))
    ];
  }
}
