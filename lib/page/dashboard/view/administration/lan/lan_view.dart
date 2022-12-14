import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/ip_form_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/lan/dhcp_reservations/dhcp_reservations_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';
import 'bloc/state.dart';

class LANView extends ArgumentsStatelessView {
  const LANView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LANCubit(context.read<RouterRepository>()),
      child: LANContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class LANContentView extends ArgumentsStatefulView {
  const LANContentView({super.key, super.next, super.args});

  @override
  State<LANContentView> createState() => _LANContentViewState();
}

class _LANContentViewState extends State<LANContentView> {
  late final LANCubit _cubit;

  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _subnetMaskController = TextEditingController();
  final TextEditingController _firstIPController = TextEditingController();
  final TextEditingController _maxNumUserController = TextEditingController();
  final TextEditingController _clientLeaseController = TextEditingController();
  final TextEditingController _dns1Controller = TextEditingController();
  final TextEditingController _dns2Controller = TextEditingController();
  final TextEditingController _dns3Controller = TextEditingController();
  final TextEditingController _winsController = TextEditingController();

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<LANCubit>();
    _cubit.fetch().then((state) {
      // init text field
      _ipAddressController.text = state.ipAddress;
      _subnetMaskController.text = state.subnetMask;
      _firstIPController.text = state.firstIPAddress;
      _maxNumUserController.text = '${state.maxNumUsers}';
      _clientLeaseController.text = '${state.clientLeaseTime}';
    });
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.behindManaged;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.behindManaged;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LANCubit, LANState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
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
              administrationSection(
                enabled: false,
                title: getAppLocalizations(context).router_details,
                contentPadding: EdgeInsets.all(24),
                content: Column(
                  children: [
                    IPFormField(
                      header: Text(
                        getAppLocalizations(context).ip_address,
                      ),
                      controller: _ipAddressController,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          _cubit.setIPAddress(_ipAddressController.text);
                        }
                      },
                      isError: state.errors['ipAddress'] != null,
                    ),
                    box24(),
                    IPFormField(
                      header: Text(
                        getAppLocalizations(context).subnet_mask,
                      ),
                      controller: _subnetMaskController,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          _cubit.setSubnetMask(_subnetMaskController.text);
                        }
                      },
                      isError: state.errors['subnetMask'] != null,
                    ),
                  ],
                ),
              ),
              administrationSection(
                title: getAppLocalizations(context).dhcp_server,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box24(),
                    administrationTile(
                        title: Text(getAppLocalizations(context).dhcp_server),
                        value: Switch.adaptive(
                            value: state.isDHCPEnabled, onChanged: (value) {})),
                    IPFormField(
                      header: Text(
                        getAppLocalizations(context).start_ip_address,
                      ),
                      controller: _firstIPController,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          _cubit.setFirstIPAddress(_firstIPController.text);
                        }
                      },
                      isError: state.errors['firstIPAddress'] != null,
                    ),
                    box24(),
                    administrationTwoLineTile(
                      tileHeight: null,
                      title: Text(
                          getAppLocalizations(context).max_number_of_users),
                      value: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            child: InputField(
                              titleText: '',
                              controller: _maxNumUserController,
                              customPrimaryColor: Colors.black,
                              onFocusChanged: (focused) {
                                if (!focused) {
                                  _cubit
                                      .setMaxUsers(_maxNumUserController.text);
                                }
                              },
                            ),
                          ),
                          box24(),
                          Text(getAppLocalizations(context)
                              .dhcp_users_limit(state.maxNumUsers)),
                        ],
                      ),
                      description: getAppLocalizations(context).dhcp_ip_range(
                          state.firstIPAddress, state.lastIPAddress),
                    ),
                    box24(),
                    administrationTwoLineTile(
                      tileHeight: null,
                      title:
                          Text(getAppLocalizations(context).client_lease_time),
                      value: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            child: InputField(
                              titleText: '',
                              controller: _clientLeaseController,
                              customPrimaryColor: Colors.black,
                              onFocusChanged: (focused) {
                                if (!focused) {
                                  _cubit.setLeaseTime(
                                      _clientLeaseController.text);
                                }
                              },
                            ),
                          ),
                          box24(),
                          Text(getAppLocalizations(context).minutes),
                        ],
                      ),
                    ),
                    box24(),
                  ],
                ),
              ),
              administrationSection(
                enabled: state.isDHCPEnabled,
                title: getAppLocalizations(context).dns_settings,
                content: Column(
                  children: [
                    administrationTile(
                      title: Text(getAppLocalizations(context).dns),
                      value: Text(state.isAutoDNS
                          ? getAppLocalizations(context).auto
                          : getAppLocalizations(context).manual),
                      onPress: () async {
                        String? result = await NavigationCubit.of(context)
                            .pushAndWait(SimpleItemPickerPath()
                              ..args = {
                                'items': [
                                  const Item(title: 'Auto', id: 'Auto'),
                                  const Item(title: 'Manual', id: 'Manual'),
                                ],
                                'selected': state.isAutoDNS ? 'Auto' : 'Manual',
                              });
                        if (result != null) {
                          _cubit.setAutoDNS(result == 'Auto');
                        }
                      },
                    ),
                    ..._buildDNSInputFields(state),
                    administrationTile(
                      title:
                          Text(getAppLocalizations(context).dhcp_reservations),
                      value: Center(),
                      onPress: () {
                        NavigationCubit.of(context).push(DHCPReservationsPath());
                      },
                    ),
                  ],
                ),
              ),
              box48(),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildDNSInputFields(
    LANState state,
  ) {
    if (state.isAutoDNS) {
      return [];
    } else {
      return [
        IPFormField(
          header: Text(
            getAppLocalizations(context).static_dns1,
          ),
          controller: _dns1Controller,
          onFocusChanged: (focused) {
            if (!focused) {
              _cubit.setStaticDns1(_dns1Controller.text);
            }
          },
          isError: state.errors['dns1'] != null,
        ),
        box24(),
        IPFormField(
          header: Text(
            getAppLocalizations(context).static_dns2_optional,
          ),
          controller: _dns2Controller,
          onFocusChanged: (focused) {
            if (!focused) {
              _cubit.setStaticDns2(_dns2Controller.text);
            }
          },
          isError: state.errors['dns2'] != null,
        ),
        box24(),
      ];
    }
  }
}
