import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'bloc/cubit.dart';

class MacFilteringView extends ArgumentsConsumerStatelessView {
  const MacFilteringView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => MacFilteringCubit(context.read<RouterRepository>()),
      child: MacFilteringContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class MacFilteringContentView extends ArgumentsConsumerStatefulView {
  const MacFilteringContentView({super.key, super.next, super.args});

  @override
  ConsumerState<MacFilteringContentView> createState() =>
      _MacFilteringContentViewState();
}

class _MacFilteringContentViewState
    extends ConsumerState<MacFilteringContentView> {
  late final MacFilteringCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<MacFilteringCubit>();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MacFilteringCubit, MacFilteringState>(
      builder: (context, state) {
        return StyledAppPageView(
          scrollable: true,
          title: getAppLocalizations(context).ip_details,
          child: AppBasicLayout(
            content: Column(
              children: [
                const AppGap.semiBig(),
                AppPanelWithSwitch(
                  value: state.status != MacFilterStatus.off,
                  title: getAppLocalizations(context).wifi_mac_filters,
                  onChangedEvent: (value) {
                    _cubit.setEnable(value);
                  },
                ),
                const AppGap.semiBig(),
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
                final String? selected = await ref
                    .read(navigationsProvider.notifier)
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
              trailing: AppTertiaryButton.noPadding(
                getAppLocalizations(context).select_device,
                onTap: () async {
                  // String? deviceIp = await ref.read(navigationsProvider.notifier)
                  //     .pushAndWait(SelectDevicePtah());
                },
              ),
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).enter_mac_address,
              onTap: () async {
                String? macAddress = await ref
                    .read(navigationsProvider.notifier)
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
              child: AppText.descriptionSub(
                  getAppLocalizations(context).no_filtered_devices_yet),
            ),
          )
        : Column(
            children: [
              AppText.tags(getAppLocalizations(context).filtered_devices),
              // Add filtered devices
            ],
          );
  }
}
