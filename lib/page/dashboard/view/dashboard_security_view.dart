import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/bloc/security/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';

import '../../../bloc/subscription/subscription_cubit.dart';
import '../../../bloc/subscription/subscription_state.dart';

class DashboardSecurityView extends StatefulWidget {
  const DashboardSecurityView({Key? key}) : super(key: key);

  @override
  State<DashboardSecurityView> createState() => _DashboardSecurityViewState();
}

class _DashboardSecurityViewState extends State<DashboardSecurityView> {
  String serialNumber = '';

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionCubit>().queryProductsFromCloud();
    context.read<SecurityBloc>().add(SetTrialActiveEvent());
  }

  Widget _unsubscribedView(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _subscriptionStatus(state),
        ),
        _subscriptionPrompt(state),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cyberthreatTile(),
                _divider(),
                _contentFilterTile(),
                _contentFilterInfo(state),
                _lastUpdate(state),
              ],
            )),
      ],
    );
  }

  Widget _trialActiveView(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _subscriptionStatus(state),
        ),
        _subscriptionPrompt(state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cyberthreatTile(),
              _cyberthreatGrid(state),
              _performedInspectionInfo(state),
              _divider(),
              _contentFilterTile(),
              _contentFilterInfo(state),
              _lastUpdate(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formalActiveView(SecurityState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subscriptionStatus(state),
          _cyberthreatTile(),
          _cyberthreatGrid(state),
          _performedInspectionInfo(state),
          _divider(),
          _contentFilterTile(),
          _contentFilterInfo(state),
          _lastUpdate(state),
        ],
      ),
    );
  }

  Widget _trialExpiredView(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _subscriptionStatus(state),
        ),
        _subscriptionPrompt(state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cyberthreatTile(),
              _divider(),
              _contentFilterTile(),
              _contentFilterInfo(state),
              _lastUpdate(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expiredView(SecurityState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _subscriptionStatus(state),
        ),
        _subscriptionPrompt(state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cyberthreatTile(),
              _divider(),
              _contentFilterTile(),
              _contentFilterInfo(state),
              _lastUpdate(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _turnedOffView(SecurityState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subscriptionStatus(state),
          _cyberthreatTile(),
          _cyberthreatGrid(state),
          _divider(),
          _contentFilterTile(),
          _contentFilterInfo(state),
          _lastUpdate(state),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      child: BlocBuilder<SecurityBloc, SecurityState>(
        builder: (context, state) {
          switch (state.subscriptionStatus) {
            case SubscriptionStatus.unsubscribed:
              return _unsubscribedView(state);
            case SubscriptionStatus.trialActive:
              return _trialActiveView(state);
            case SubscriptionStatus.active:
              return _formalActiveView(state);
            case SubscriptionStatus.trialExpired:
              return _trialExpiredView(state);
            case SubscriptionStatus.expired:
              return _expiredView(state);
            case SubscriptionStatus.turnedOff:
              return _turnedOffView(state);
          }
        },
      ),
    );
  }

  Widget _subscriptionStatus(SecurityState state) {
    return Row(
      children: [
        Text(
          'Linksys Secure',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(fontSize: 23, fontWeight: FontWeight.w700),
          textAlign: TextAlign.start,
        ),
        box8(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _getSubscriptionStatusImage(),
            box4(),
            Text(
              state.subscriptionStatus.displayTitle,
              style: Theme.of(context)
                  .textTheme
                  .headline3
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getSubscriptionStatusImage() {
    String imageName;
    switch (context.read<SecurityBloc>().state.subscriptionStatus) {
      case SubscriptionStatus.unsubscribed:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
      case SubscriptionStatus.trialActive:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
      case SubscriptionStatus.active:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
      case SubscriptionStatus.trialExpired:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
      case SubscriptionStatus.expired:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
      case SubscriptionStatus.turnedOff:
        imageName = 'assets/images/icon_checked_circle.png';
        break;
    }
    return Image.asset(imageName, width: 16, height: 16);
  }

  Widget _subscriptionPrompt(SecurityState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box24(),
        GestureDetector(
          child: Container(
            alignment: Alignment.centerLeft,
            height: 52,
            color: MoabColor.dashboardBottomBackground,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _getSubscriptionPromptText(state),
                style: Theme.of(context)
                    .textTheme
                    .headline3
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          onTap: () {
            NavigationCubit.of(context).push(SecurityMarketingPath());
          },
        ),
        box16(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BlocListener<SubscriptionCubit, SubscriptionState>(
                listener: (context, state) {
                  if (state.subscriptionOrderResponse != null &&
                      state.networkEntitlementResponse == null) {
                    context.read<SubscriptionCubit>().getNetworkEntitlement(
                        context
                            .read<NetworkCubit>()
                            .state
                            .selected!
                            .deviceInfo!
                            .serialNumber);
                  } else if (state.networkEntitlementResponse != null) {
                    context.read<SecurityBloc>().add(SetFormalActiveEvent());
                  }
                },
                child: PrimaryButton(
                  text: 'Subscribe',
                  onPress: () {
                    final item =
                        context.read<SubscriptionCubit>().state.products?.first;
                    logger.d(
                        'subscription products : ${context.read<SubscriptionCubit>().state.products?.length}');
                    String serialNumber = context
                        .read<NetworkCubit>()
                        .state
                        .selected!
                        .deviceInfo
                        .serialNumber;
                    if (item != null) {
                      context.read<SubscriptionCubit>().buy(item, serialNumber);
                      // context.read<SubscriptionCubit>().getNetworkEntitlement('54J10M28C00028');
                    }
                  },
                ))),
      ],
    );
  }

  String _getSubscriptionPromptText(SecurityState state) {
    switch (state.subscriptionStatus) {
      case SubscriptionStatus.unsubscribed:
        return 'Get enterprise-level security for your home';
      case SubscriptionStatus.active:
        return ''; // The subscription prompt will not display
      case SubscriptionStatus.trialActive:
        final numOfDays = (state as TrialActiveState).remainingTrialDays;
        return '$numOfDays days left on Linksys Secure trial';
      case SubscriptionStatus.trialExpired:
        return 'Get enterprise-level security for your home';
      case SubscriptionStatus.expired:
        return 'Get enterprise-level security for your home';
      case SubscriptionStatus.turnedOff:
        return ''; // The subscription prompt will not display
    }
  }

  Widget _cyberthreatTile() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: TitleWithIcons(
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
    );
  }

  Widget _cyberthreatGrid(SecurityState state) {
    final isGridEnabled =
        state.subscriptionStatus != SubscriptionStatus.turnedOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box16(),
        Visibility(
          visible: state.hasBlockedThreat,
          replacement: Text(
            'No one has tried any funny business yet, but we are monitoring 24/7',
            style: Theme.of(context).textTheme.headline3?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InfoBlockWidget(
                  count: context.read<SecurityBloc>().state.numOfBlockedVirus,
                  text: CyberthreatType.virus.displayTitle,
                  isEnabled: isGridEnabled,
                  height: 96,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.virus});
                  },
                ),
              ),
              box8(),
              Expanded(
                child: InfoBlockWidget(
                  count: context.read<SecurityBloc>().state.numOfBlockedBotnet,
                  text: CyberthreatType.botnet.displayTitle,
                  isEnabled: isGridEnabled,
                  height: 96,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.botnet});
                  },
                ),
              ),
              box8(),
              Expanded(
                child: InfoBlockWidget(
                  count: context.read<SecurityBloc>().state.numOfBlockedWebsite,
                  text: CyberthreatType.website.displayTitle,
                  isEnabled: isGridEnabled,
                  height: 96,
                  onPress: () {
                    NavigationCubit.of(context).push(SecurityCyberThreatPath()
                      ..args = {'type': CyberthreatType.website});
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _performedInspectionInfo(SecurityState state) {
    return Offstage(
      offstage: !(state.numOfInspection > 0),
      child: Column(
        children: [
          box8(),
          Text(
            '${state.numOfInspection} total inspections performed',
            style: Theme.of(context)
                .textTheme
                .headline3
                ?.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(top: 32),
      child: Divider(
        height: 1,
        color: MoabColor.black,
      ),
    );
  }

  Widget _contentFilterTile() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: TitleWithIcons(
        text: Text(
          'Content filtered',
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(fontWeight: FontWeight.w700),
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
    );
  }

  Widget _contentFilterInfo(SecurityState state) {
    if (state is UnsubscribedState) {
      return Text(
        'Create healthy digital lifestyle for your family and feel safe with the content on your network. Filter out categories and apps you don’t want.',
        style: Theme.of(context)
            .textTheme
            .headline3
            ?.copyWith(fontWeight: FontWeight.w500),
      );
    } else {
      return Visibility(
        visible: state.hasFilterCreated,
        child: Visibility(
          visible: state.numOfIncidents > 0,
          child: _incidentsOnProfiles(),
          replacement: Text(
            'No incidents yet',
            style: Theme.of(context)
                .textTheme
                .headline3
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        replacement: _createFilter(),
      );
    }
  }

  Widget _createFilter() {
    return Column(
      children: [
        Text(
          'Create healthy digital lifestyle for your family and feel safe with the content on your network. Filter out categories and apps you don’t want.',
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        box24(),
        PrimaryButton(
          text: 'Create filter',
          onPress: () {
            //TODO: Go to next page
            context.read<SecurityBloc>().add(ContentFilterCreatedEvent());
          },
        ),
      ],
    );
  }

  Widget _incidentsOnProfiles() {
    final _mockProfiles = context.read<ProfilesCubit>().state.profileList;
    final status = context.read<SecurityBloc>().state.subscriptionStatus;
    final range = context.read<SecurityBloc>().state.evaluatedRange;
    final double listHeight = _mockProfiles.length * 80;
    return Column(
      children: [
        InfoBlockWidget(
          count: context.read<SecurityBloc>().state.numOfIncidents,
          text: 'Blocked content this ${range.displayTitle}',
          isEnabled: status != SubscriptionStatus.turnedOff,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _lastUpdate(SecurityState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box48(),
        Text(
          'Fortinet threat database',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'Last updated on ${state.latestUpdateDate}',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(fontWeight: FontWeight.w500),
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
  }) : super(key: key) {
    if (leadingIcon != null) {
      _widgets.add(leadingIcon!);
      _widgets.add(box8());
    }
    _widgets.add(Expanded(
      child: text,
    ));
    if (trailingIcon != null) {
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

  final int count;
  final String text;
  final bool isEnabled;
  final Color color;
  final Color disabledColor;
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
                mainAxisAlignment: MainAxisAlignment.start,
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
