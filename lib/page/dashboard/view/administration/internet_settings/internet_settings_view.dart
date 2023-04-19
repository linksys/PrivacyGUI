import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/string_mapping.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'bloc/cubit.dart';
import 'bloc/state.dart';

enum InternetSettingsViewType {
  ipv4,
  ipv6,
}

class InternetSettingsView extends ArgumentsConsumerStatelessView {
  const InternetSettingsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class InternetSettingsContentView extends ArgumentsConsumerStatefulView {
  const InternetSettingsContentView({super.key, super.next, super.args});

  @override
  ConsumerState<InternetSettingsContentView> createState() =>
      _InternetSettingsContentViewState();
}

class _InternetSettingsContentViewState
    extends ConsumerState<InternetSettingsContentView> {
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

  InternetSettingsViewType _selected = InternetSettingsViewType.ipv4;
  bool _isBehindRouter = false;

  @override
  void initState() {
    _cubit = context.read<InternetSettingsCubit>();
    _cubit.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityProvider);
    _isBehindRouter = connectivityState.connectivityInfo.routerType ==
        RouterType.behindManaged;
    return BlocBuilder<InternetSettingsCubit, InternetSettingsState>(
        builder: (context, state) {
      return StyledLinksysPageView(
        padding: const LinksysEdgeInsets.zero(),
        scrollable: true,
        title: getAppLocalizations(context).ip_details,
        actions: [
          LinksysTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {},
          ),
        ],
        child: LinksysBasicLayout(
          content: Column(
            children: [
              if (!_isBehindRouter)
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                      color: AppTheme.of(context).colors.ctaPrimaryDisable),
                  alignment: Alignment.center,
                  child: LinksysText.descriptionMain(
                    'To change these settings. connect to ${context.read<NetworkCubit>().state.selected?.radioInfo?.first.settings.ssid ?? ' '}',
                  ),
                ),
              AppPadding(
                padding: const LinksysEdgeInsets.semiBig(),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildSegmentController(state),
                        const LinksysGap.semiBig(),
                        _buildSegment(state),
                        const LinksysGap.semiBig(),
                        _buildAdditionalSettings(state),
                      ],
                    ),
                    if (!_isBehindRouter)
                      Container(
                        decoration:
                            const BoxDecoration(color: Color(0x88aaaaaa)),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSegmentController(InternetSettingsState state) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<InternetSettingsViewType>(
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
          InternetSettingsViewType.ipv4: AppPadding.semiSmall(
            child: LinksysText.descriptionMain(
                getAppLocalizations(context).label_ipv4),
          ),
          InternetSettingsViewType.ipv6: AppPadding.semiSmall(
            child: LinksysText.descriptionMain(
                getAppLocalizations(context).label_ipv6),
          ),
        },
      ),
    );
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
          AppPanelWithInfo(
            title: getAppLocalizations(context).mtu,
            description: state.mtu == 0
                ? getAppLocalizations(context).auto
                : getAppLocalizations(context).manual,
            infoText: ' ',
            onTap: () async {
              int? value = await ref
                  .read(navigationsProvider.notifier)
                  .pushAndWait(MTUPickerPath()
                    ..args = {
                      'selected': state.mtu,
                    });
              if (value != null) {
                _cubit.setMtu(value);
              }
            },
          ),
          AppPanelWithInfo(
            title: getAppLocalizations(context).mac_address_clone,
            description: state.macClone
                ? getAppLocalizations(context).on
                : getAppLocalizations(context).off,
            infoText: ' ',
            onTap: () async {
              String? mac = await ref
                  .read(navigationsProvider.notifier)
                  .pushAndWait(MACClonePath()
                    ..args = {
                      'enabled': state.macClone,
                      'macAddress': state.macCloneAddress
                    });
              if (mac != null) {
                final enabled = mac.isEmpty;
                final macAddress = mac;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIPv4Segment(InternetSettingsState state) {
    return Column(
      children: [
        AppPanelWithInfo(
          title: getAppLocalizations(context).connection_type,
          description:
              toConnectionTypeData(context, state.ipv4ConnectionType).title,
          infoText: ' ',
          onTap: () async {
            String? select = await ref
                .read(navigationsProvider.notifier)
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
    return const Center();
  }

  Widget _buildPPPoESettings(InternetSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _pppoeUsernameController,
        ),
        const LinksysGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _pppoePasswordController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).vlan_id,
          hintText: getAppLocalizations(context).vlan_id,
          controller: _pppoeVLANIDController,
        ),
        const LinksysGap.semiSmall(),
        LinksysText.descriptionSub(getAppLocalizations(context).vlan_id_desc),
      ],
    );
  }

  Widget _buildStaticSettings(InternetSettingsState state) {
    return Column(
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).internet_ipv4_address,
          hintText: getAppLocalizations(context).internet_ipv4_address,
          controller: _staticIpAddressController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).subnet_mask,
          hintText: getAppLocalizations(context).subnet_mask,
          controller: _staticSubnetController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).default_gateway,
          hintText: getAppLocalizations(context).default_gateway,
          controller: _staticGatewayController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).dns1,
          hintText: getAppLocalizations(context).dns1,
          controller: _staticDns1Controller,
        ),
      ],
    );
  }

  Widget _buildPPTPSettings(InternetSettingsState state) {
    return Column(
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _pptpUsernameController,
        ),
        const LinksysGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _pptpPasswordController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).server_ipv4_address,
          hintText: getAppLocalizations(context).server_ipv4_address,
          controller: _pptpServerIpController,
        ),
      ],
    );
  }

  Widget _buildL2TPSettings(InternetSettingsState state) {
    return Column(
      children: [
        AppTextField(
          headerText: getAppLocalizations(context).username,
          hintText: getAppLocalizations(context).username,
          controller: _l2tpUsernameController,
        ),
        const LinksysGap.semiSmall(),
        AppPasswordField(
          headerText: getAppLocalizations(context).password,
          hintText: getAppLocalizations(context).password,
          controller: _l2tpPasswordController,
        ),
        const LinksysGap.semiSmall(),
        AppTextField(
          headerText: getAppLocalizations(context).server_ipv4_address,
          hintText: getAppLocalizations(context).server_ipv4_address,
          controller: _l2tpServerIpController,
        ),
      ],
    );
  }

  Widget _buildBridgeModeSettings(InternetSettingsState state) {
    return const Center();
  }

  Widget _buildIPv6Segment(InternetSettingsState state) {
    return Column(
      children: [
        AppPanelWithInfo(
          title: getAppLocalizations(context).connection_type,
          description:
              toConnectionTypeData(context, state.ipv6ConnectionType).title,
          infoText: ' ',
          onTap: () async {
            final disabled = state.supportedIPv6ConnectionType
                .where((ipv6) => !state.supportedWANCombinations.any(
                    (combine) =>
                        combine.wanType == state.ipv4ConnectionType &&
                        combine.wanIPv6Type == ipv6))
                .toList();
            String? select = await ref
                .read(navigationsProvider.notifier)
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
        AppPanelWithInfo(
          title: getAppLocalizations(context).ipv6_automatic,
          description: state.isIPv6AutomaticEnabled
              ? getAppLocalizations(context).enabled
              : getAppLocalizations(context).disabled,
          infoText: ' ',
          onTap: () {},
        ),
        AppPanelWithInfo(
          title: getAppLocalizations(context).duid,
          description: state.duid,
          infoText: ' ',
          onTap: () {},
        ),
        AppPanelWithInfo(
          title: getAppLocalizations(context).sixth_tunnel,
          description: 'Disabled',
          infoText: ' ',
          onTap: () {},
        ),
      ],
    );
  }
}
