import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/ip_form_field.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'bloc/cubit.dart';
import 'bloc/state.dart';

class LANView extends ArgumentsConsumerStatelessView {
  const LANView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => LANCubit(context.read<RouterRepository>()),
      child: LANContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class LANContentView extends ArgumentsConsumerStatefulView {
  const LANContentView({super.key, super.next, super.args});

  @override
  ConsumerState<LANContentView> createState() => _LANContentViewState();
}

class _LANContentViewState extends ConsumerState<LANContentView> {
  late final LANCubit _cubit;

  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _subnetMaskController = TextEditingController();
  final TextEditingController _firstIPController = TextEditingController();
  final TextEditingController _maxNumUserController = TextEditingController();
  final TextEditingController _clientLeaseController = TextEditingController();
  final TextEditingController _dns1Controller = TextEditingController();
  final TextEditingController _dns2Controller = TextEditingController();

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LANCubit, LANState>(builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).ip_details,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {},
          )
        ],
        child: AppBasicLayout(
          content: Column(
            children: [
              administrationSection(
                title: getAppLocalizations(context).router_details,
                content: Column(
                  children: [
                    IPFormField(
                      header: AppText.descriptionMain(
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
                    const AppGap.semiBig(),
                    IPFormField(
                      header: AppText.descriptionMain(
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
                    const AppGap.semiBig(),
                    AppPanelWithSwitch(
                      value: state.isDHCPEnabled,
                      title: getAppLocalizations(context).dhcp_server,
                      onChangedEvent: (value) {},
                    ),
                    IPFormField(
                      header: AppText.descriptionMain(
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
                    const AppGap.semiBig(),
                    AppTextField(
                      controller: _maxNumUserController,
                      width: 116,
                      headerText:
                          getAppLocalizations(context).max_number_of_users,
                      hintText:
                          getAppLocalizations(context).max_number_of_users,
                      descriptionText: getAppLocalizations(context)
                          .dhcp_users_limit(state.maxNumUsers),
                      onFocusChanged: (focused) {
                        if (!focused) {
                          _cubit.setMaxUsers(_maxNumUserController.text);
                        }
                      },
                    ),
                    const AppGap.semiSmall(),
                    AppText.descriptionSub(
                      getAppLocalizations(context).dhcp_ip_range(
                          state.firstIPAddress, state.lastIPAddress),
                      color: ConstantColors.baseTertiaryGray,
                    ),
                    const AppGap.semiBig(),
                    AppTextField(
                      controller: _clientLeaseController,
                      width: 116,
                      headerText:
                          getAppLocalizations(context).client_lease_time,
                      hintText: getAppLocalizations(context).client_lease_time,
                      descriptionText: getAppLocalizations(context).minutes,
                      onFocusChanged: (focused) {
                        if (!focused) {
                          _cubit.setLeaseTime(_clientLeaseController.text);
                        }
                      },
                    ),
                    const AppGap.semiBig(),
                  ],
                ),
              ),
              administrationSection(
                enabled: state.isDHCPEnabled,
                title: getAppLocalizations(context).dns_settings,
                content: Column(
                  children: [
                    AppPanelWithInfo(
                      title: getAppLocalizations(context).dns,
                      infoText: state.isAutoDNS
                          ? getAppLocalizations(context).auto
                          : getAppLocalizations(context).manual,
                      onTap: () async {
                        String? result = await ref
                            .read(navigationsProvider.notifier)
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
                    AppPanelWithInfo(
                      title: getAppLocalizations(context).dhcp_reservations,
                      infoText: ' ',
                      onTap: () {
                        ref
                            .read(navigationsProvider.notifier)
                            .push(DHCPReservationsPath());
                      },
                    ),
                  ],
                ),
              ),
              const AppGap.extraBig(),
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
          header: AppText.descriptionMain(
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
        const AppGap.semiBig(),
        IPFormField(
          header: AppText.descriptionMain(
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
        const AppGap.semiBig(),
      ];
    }
  }
}
