import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';


enum SubscriptionStatus {
  active(displayTitle: 'Active'),
  activeTrial(displayTitle: 'Active (trial)'),
  activeTurnedOff(displayTitle: 'Active (Turned Off)'),
  expired(displayTitle: 'Expired');

  const SubscriptionStatus({required this.displayTitle});

  final String displayTitle;
}

enum CyberthreatType {
  virus, malware, botnet, maliciousWeb
}

class DashboardSecurityView extends StatefulWidget {
  const DashboardSecurityView({Key? key}) : super(key: key);

  @override
  State<DashboardSecurityView> createState() => _DashboardSecurityViewState();
}

class _DashboardSecurityViewState extends State<DashboardSecurityView> {
  //TODO: Remove dummy data
  var subscriptionPrompt = '30 days left on Linksys Secure trial';
  // var subscriptionPrompt = 'Your Linksys Secure trial expired';
  // var subscriptionPrompt = '30% off Linksys Secure subscription';
  var subscriptionStatus = SubscriptionStatus.active;
  var numOfInspection = 329;
  Map<String, int> blockedThreats = {
    'Virus': 3,
    'Ransomware & Malware': 6,
    'Botnet': 11,
    'Malicious websites': 4,
  };
  var hasFilterCreated = true;
  var numOfIncidents = 21;
  var evaluatedRange = 'This week';
  var latestUpdateDate = 'Aug 15, 2022';

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
          _updateInfo(),
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
          height: 10,
        ),
        GestureDetector(
          child: Container(
            alignment: Alignment.centerLeft,
            height: 52,
            color: MoabColor.dashboardBottomBackground,
            child: Text(
              subscriptionPrompt,
              style: Theme.of(context).textTheme.headline3?.copyWith(
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          onTap: () {
            NavigationCubit.of(context).push(SecurityMarketingPath());
          },
        ),
      ],
    );
  }

  Widget _securityStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 45,
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Linksys Secure',
              style: Theme.of(context)
                  .textTheme
                  .headline2
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                'assets/images/icon_checked_circle.png',//TODO: Remove hard code
                width: 16,
                height: 16,
              ),
            ),
            Text(
              subscriptionStatus.displayTitle,
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
          evaluatedRange,  //TODO: Remove hard code
          style: Theme.of(context)
              .textTheme
              .headline3
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
            onPressed: () {
              NavigationCubit.of(context).push(SecurityProtectionStatusPath());
            },
          ),
        ),
        Visibility(
          visible: blockedThreats.isNotEmpty,
          replacement: Text(
            'No one has tried any funny business yet, but we are monitoring 24/7',
            style: Theme.of(context).textTheme.headline3?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          child: SizedBox(
            height: tileHeight,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              children: [  //TODO: Remove hard code
                InfoBlockWidget(
                  count: 3,
                  text: 'Virus',
                  isEnabled: subscriptionStatus != SubscriptionStatus.activeTurnedOff,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.virus}
                    );
                  },
                ),
                InfoBlockWidget(
                  count: 6,
                  text: 'Ransomware & Malware',
                  isEnabled: subscriptionStatus != SubscriptionStatus.activeTurnedOff,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.malware}
                    );
                  },
                ),
                InfoBlockWidget(
                  count: 11,
                  text: 'Botnet',
                  isEnabled: subscriptionStatus != SubscriptionStatus.activeTurnedOff,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.botnet}
                    );
                  },
                ),
                InfoBlockWidget(
                  count: 4,
                  text: 'Malicious websites',
                  isEnabled: subscriptionStatus != SubscriptionStatus.activeTurnedOff,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.maliciousWeb}
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Offstage(
          offstage: !(numOfInspection > 0),
          child: Column(
            children: [
              box8(),
              Text(
                '$numOfInspection total inspections performed',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                  fontWeight: FontWeight.w400
                ),
              ),
            ],
          ),
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
            style: Theme.of(context).textTheme.headline3?.copyWith(
              fontWeight: FontWeight.w700
            ),
          ),
          leadingIcon: Image.asset(
            'assets/images/icon_block.png',
            height: 26,
            width: 26,
          ),
          trailingIcon: IconButton(
            icon: Image.asset(
              'assets/images/icon_info.png',
              height: 26,
              width: 26,
            ),
            onPressed: () {
              //TODO: Go to next page
            },
          ),
        ),
        box36(),
        Visibility(
          visible: hasFilterCreated,
          child: Visibility(
            visible: numOfIncidents > 0,
            child: _incidentsOnProfiles(),
            replacement: Text(
              'No incidents yet',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          replacement: _createFilter(),
        ),
      ],
    );
  }

  Widget _incidentsOnProfiles() {
    final _mockProfiles = context.read<ProfilesCubit>().state.profileList;
    final double listHeight = _mockProfiles.length * 80;
    return Column(
      children: [
        InfoBlockWidget(
          count: numOfIncidents,
          text: 'Blocked content $evaluatedRange',
          isEnabled: subscriptionStatus != SubscriptionStatus.activeTurnedOff,
          isVertical: false,
          height: 60,
        ),
        SizedBox(
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
                onTap: () {
                  NavigationCubit.of(context).push(CFFilteredContentPath());
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _createFilter() {
    return Column(
      children: [
        Text(
          'Create healthy digital lifestyle for your family and feel safe with the content on your network. Filter out categories and apps you don’t want.',
          style: Theme.of(context).textTheme.headline3?.copyWith(
              fontWeight: FontWeight.w500
          ),
        ),
        box24(),
        PrimaryButton(
          text: 'Create filter',
          onPress: () {
            //TODO: Go to next page
          },
        ),
      ],
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

  Widget _updateInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box48(),
        Text(
          'Fortinet threat database',
          style: Theme.of(context).textTheme.headline4?.copyWith(
              fontWeight: FontWeight.w700
          ),
        ),
        Text(
          'Last updated on $latestUpdateDate',
          style: Theme.of(context).textTheme.headline4?.copyWith(
              fontWeight: FontWeight.w500
          ),
        ),
      ],
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
    this.isEnabled = true,
    this.color = MoabColor.dashboardBottomBackground,
    this.disabledColor = MoabColor.dashboardDisabled,
    this.isVertical = true,
    this.height = 0,
    this.onPress,
  }) : super(key: key);

  final bool isEnabled;
  final Color color;
  final Color disabledColor;
  final int count;
  final String text;
  final bool isVertical;
  final double height;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        color: isEnabled ? color : disabledColor,
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
          children: _content(
            context,
            space: const SizedBox(
              width: 16,
            )
          ),
        ),
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
