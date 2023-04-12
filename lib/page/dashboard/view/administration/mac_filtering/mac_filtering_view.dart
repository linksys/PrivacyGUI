import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'bloc/cubit.dart';

class MacFilteringView extends ArgumentsStatelessView {
  const MacFilteringView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MacFilteringCubit(context.read<RouterRepository>()),
      child: MacFilteringContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class MacFilteringContentView extends ArgumentsStatefulView {
  const MacFilteringContentView({super.key, super.next, super.args});

  @override
  State<MacFilteringContentView> createState() =>
      _MacFilteringContentViewState();
}

class _MacFilteringContentViewState extends State<MacFilteringContentView> {
  late final MacFilteringCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<MacFilteringCubit>();

    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
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
    return BlocBuilder<MacFilteringCubit, MacFilteringState>(
      builder: (context, state) {
        return StyledLinksysPageView(
          scrollable: true,
          title: getAppLocalizations(context).ip_details,
          child: LinksysBasicLayout(
            content: Column(
              children: [
                const LinksysGap.semiBig(),
                AppPanelWithSwitch(
                  value: state.status != MacFilterStatus.off,
                  title: getAppLocalizations(context).wifi_mac_filters,
                  onChangedEvent: (value) {
                    _cubit.setEnable(value);
                  },
                ),
                const LinksysGap.semiBig(),
                ..._buildEnabledContent(state)
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildEnabledContent(MacFilteringState state) {
    return state.status != MacFilterStatus.off
        ? [
            AppPanelWithInfo(
              title: getAppLocalizations(context).access,
              infoText: state.status.name,
              onTap: () async {
                final String? selected = await NavigationCubit.of(context)
                    .pushAndWait(SimpleItemPickerPath()
                      ..args = {
                        'items': [
                          Item(
                            title: getAppLocalizations(context).allow_access,
                            description: getAppLocalizations(context)
                                .allow_access_description,
                            id: MacFilterStatus.allow.name,
                          ),
                          Item(
                            title: getAppLocalizations(context).deny_access,
                            description: getAppLocalizations(context)
                                .deny_access_description,
                            id: MacFilterStatus.deny.name,
                          ),
                        ],
                        'selected': state.status.name,
                      });
                if (selected != null) {
                  _cubit.setAccess(selected);
                }
              },
            ),
            AppPanelWithTrailWidget(
              title: getAppLocalizations(context).device_ip_address,
              trailing: LinksysTertiaryButton.noPadding(
                getAppLocalizations(context).select_device,
                onTap: () async {
                  // String? deviceIp = await NavigationCubit.of(context)
                  //     .pushAndWait(SelectDevicePtah());
                },
              ),
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).enter_mac_address,
              onTap: () async {
                String? macAddress = await NavigationCubit.of(context)
                    .pushAndWait(MacFilteringInputPath());
                if (macAddress != null) {
                  // TODO query devices name and save device
                  // showSuccessSnackBar(context, 'message');
                }
              },
            ),
            _buildFilteredDevices(state),
          ]
        : [];
  }

  Widget _buildFilteredDevices(MacFilteringState state) {
    return state.selectedDevices.isEmpty
        ? Expanded(
            child: Center(
              child: LinksysText.descriptionSub(
                  getAppLocalizations(context).no_filtered_devices_yet),
            ),
          )
        : Column(
            children: [
              LinksysText.tags(getAppLocalizations(context).filtered_devices),
              // Add filtered devices
            ],
          );
  }
}
