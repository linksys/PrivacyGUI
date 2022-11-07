import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/string_mapping.dart';

import 'bloc/cubit.dart';
import 'bloc/state.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

class InternetSettingsView extends ArgumentsStatelessView {
  const InternetSettingsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InternetSettingsCubit(context.read<RouterRepository>()),
      child: InternetSettingsContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class InternetSettingsContentView extends ArgumentsStatefulView {
  const InternetSettingsContentView({super.key, super.next, super.args});

  @override
  State<InternetSettingsContentView> createState() =>
      _InternetSettingsContentViewState();
}

class _InternetSettingsContentViewState
    extends State<InternetSettingsContentView> {
  late final InternetSettingsCubit _cubit;

  final TextEditingController _pppoeUsernameController =
      TextEditingController();
  final TextEditingController _pppoePasswordController =
      TextEditingController();
  final TextEditingController _pppoeVLANIDController = TextEditingController();
  final TextEditingController _staticIpAddressController =
      TextEditingController();
  final TextEditingController _staticSubnetController = TextEditingController();
  final TextEditingController _staticGatewayController =
      TextEditingController();
  final TextEditingController _staticDns1Controller = TextEditingController();
  final TextEditingController _pptpUsernameController = TextEditingController();
  final TextEditingController _pptpPasswordController = TextEditingController();
  final TextEditingController _pptpServerIpController = TextEditingController();
  final TextEditingController _l2tpUsernameController = TextEditingController();
  final TextEditingController _l2tpPasswordController = TextEditingController();
  final TextEditingController _l2tpServerIpController = TextEditingController();

  bool _isBehindRouter = false;
  InternetSettingsViewType _selected = InternetSettingsViewType.ipv4;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<InternetSettingsCubit>();
    _cubit.fetch();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      setState(() {
        _isBehindRouter =
            state.connectivityInfo.routerType == RouterType.managedMoab;
      });
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.managedMoab;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InternetSettingsCubit, InternetSettingsState>(
        builder: (context, state) {
      return BasePageView(
        padding: EdgeInsets.zero,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).ip_details,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {},
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            children: [
              if (!_isBehindRouter)
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.black26),
                  alignment: Alignment.center,
                  child:
                  Text('To change these settings. connect to {SSID}', style: Theme.of(context).textTheme.headline2,),
                ),
              Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<
                            InternetSettingsViewType>(
                          backgroundColor: const Color.fromRGBO(211, 211, 211, 1.0),
                          thumbColor: const Color.fromRGBO(248, 248, 248, 1.0),
                          groupValue: _selected,
                          onValueChanged: (InternetSettingsViewType? value) {
                            if (value != null) {
                              setState(() {
                                _selected = value;
                                switch (value) {
                                  case InternetSettingsViewType.ipv4:
                                    break;
                                  case InternetSettingsViewType.ipv6:
                                    break;
                                }
                              });
                            }
                          },
                          children: {
                            InternetSettingsViewType.ipv4: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(getAppLocalizations(context).label_ipv4),
                            ),
                            InternetSettingsViewType.ipv6: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(getAppLocalizations(context).label_ipv6),
                            ),
                          },
                        ),
                      ),
                      _buildSegment(state),
                      box24(),
                      _buildAdditionalSettings(state),
                    ],
                  ),
                  if (!_isBehindRouter) Container(decoration: BoxDecoration(color: Color(0x88aaaaaa)),)
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSegment(InternetSettingsState state) {
    return _selected == InternetSettingsViewType.ipv4
        ? _buildIPv4Segment(state)
        : _buildIPv6Segment(state);
  }

  Widget _buildAdditionalSettings(InternetSettingsState state) {
    return administrationSection(
      title: getAppLocalizations(context).additional_setting,
      content: Column(
        children: [
          administrationTwoLineTile(
            title: Text(getAppLocalizations(context).mtu),
            value: Text('Auto'),
            icon: Image.asset('assets/images/icon_chevron.png'),
            onPress: () {},
          ),
          administrationTile(
            title: Text(getAppLocalizations(context).mac_address_clone),
            value: Text('Off'),
            icon: Image.asset('assets/images/icon_chevron.png'),
            onPress: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildIPv4Segment(InternetSettingsState state) {
    return Column(
      children: [
        administrationTwoLineTile(
          title: Text(getAppLocalizations(context).connection_type),
          value: Text(
              toConnectionTypeData(context, state.ipv4ConnectionType).title),
          icon: Image.asset('assets/images/icon_chevron.png'),
          background: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 24),
          onPress: () async {
            String? select = await NavigationCubit.of(context)
                .pushAndWait(ConnectionTypeSelectionPath()
                  ..args = {
                    'supportedList': state.supportedIPv4ConnectionType,
                    'selected': state.ipv4ConnectionType,
                  });
            if (select != null) {
              _cubit.setIPv4ConnectionType(select);
            }
          },
        ),
        _buildIPv4SettingsByConnectionType(state),
      ],
    );
  }

  Widget _buildIPv4SettingsByConnectionType(InternetSettingsState state) {
    String type = state.ipv4ConnectionType;
    if (type == 'DHCP') {
      return _buildDHCPSettings(state);
    } else if (type == 'PPPoE') {
      return _buildPPPoESettings(state);
    } else if (type == 'Static') {
      return _buildStaticSettings(state);
    } else if (type == 'PPTP') {
      return _buildPPTPSettings(state);
    } else if (type == 'L2TP') {
      return _buildL2TPSettings(state);
    } else if (type == 'Bridge') {
      return _buildBridgeModeSettings(state);
    } else {
      return const Center();
    }
  }

  Widget _buildDHCPSettings(InternetSettingsState state) {
    return Center();
  }

  Widget _buildPPPoESettings(InternetSettingsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputField(
            titleText: getAppLocalizations(context).username,
            controller: _pppoeUsernameController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).password,
            controller: _pppoePasswordController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).vlan_id,
            controller: _pppoeVLANIDController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          Text(getAppLocalizations(context).vlan_id_desc),
        ],
      ),
    );
  }

  Widget _buildStaticSettings(InternetSettingsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          InputField(
            titleText: getAppLocalizations(context).internet_ipv4_address,
            controller: _staticIpAddressController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).subnet_mask,
            controller: _staticSubnetController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).default_gateway,
            controller: _staticGatewayController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).dns1,
            controller: _staticDns1Controller,
            customPrimaryColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPPTPSettings(InternetSettingsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          InputField(
            titleText: getAppLocalizations(context).username,
            controller: _pptpUsernameController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).password,
            controller: _pptpPasswordController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).server_ipv4_address,
            controller: _pptpServerIpController,
            customPrimaryColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildL2TPSettings(InternetSettingsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          InputField(
            titleText: getAppLocalizations(context).username,
            controller: _l2tpUsernameController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).password,
            controller: _l2tpPasswordController,
            customPrimaryColor: Colors.black,
          ),
          box8(),
          InputField(
            titleText: getAppLocalizations(context).server_ipv4_address,
            controller: _l2tpServerIpController,
            customPrimaryColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildBridgeModeSettings(InternetSettingsState state) {
    return Center();
  }

  Widget _buildIPv6Segment(InternetSettingsState state) {
    return Column(
      children: [
        administrationTwoLineTile(
          title: Text(getAppLocalizations(context).connection_type),
          value: Text(
              toConnectionTypeData(context, state.ipv6ConnectionType).title),
          icon: Image.asset('assets/images/icon_chevron.png'),
          padding: EdgeInsets.symmetric(horizontal: 24),
          onPress: () async {
            final disabled = state.supportedIPv6ConnectionType
                .where((ipv6) => !state.supportedWANCombinations.any(
                    (combine) =>
                        combine.wanType == state.ipv4ConnectionType &&
                        combine.wanIPv6Type == ipv6))
                .toList();
            String? select = await NavigationCubit.of(context)
                .pushAndWait(ConnectionTypeSelectionPath()
                  ..args = {
                    'supportedList': state.supportedIPv6ConnectionType,
                    'selected': state.ipv6ConnectionType,
                    'disabled': disabled
                  });
            if (select != null) {
              _cubit.setIPv6ConnectionType(select);
            }
          },
        ),
        administrationTwoLineTile(
          title: Text(getAppLocalizations(context).ipv6_automatic),
          value: Text(state.isIPv6AutomaticEnabled
              ? getAppLocalizations(context).enabled
              : getAppLocalizations(context).disabled),
          icon: Image.asset('assets/images/icon_chevron.png'),
          padding: EdgeInsets.symmetric(horizontal: 24),
          onPress: () {},
        ),
        administrationTwoLineTile(
          title: Text(getAppLocalizations(context).duid),
          value: Text(state.duid),
          icon: Image.asset('assets/images/icon_chevron.png'),
          padding: EdgeInsets.symmetric(horizontal: 24),
        ),
        administrationTwoLineTile(
          title: Text(getAppLocalizations(context).sixth_tunnel),
          value: Text('Disabled'),
          icon: Image.asset('assets/images/icon_chevron.png'),
          padding: EdgeInsets.symmetric(horizontal: 24),
        ),
      ],
    );
  }
}
