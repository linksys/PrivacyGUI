import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/panel_bases.dart';

import 'common_widget.dart';

class AdministrationView extends ArgumentsStatefulView {
  const AdministrationView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<AdministrationView> createState() => _AdministrationViewState();
}

class _AdministrationViewState extends State<AdministrationView> {
  @override
  Widget build(BuildContext context) {
    return StyledLinksysPageView(
      title: getAppLocalizations(context).administration,
      scrollable: true,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            administrationSection(
              title: getAppLocalizations(context).general.toUpperCase(),
              content: Column(
                children: [
                  AppSimplePanel(
                    title:
                        getAppLocalizations(context).router_password_and_hint,
                    onTap: () => NavigationCubit.of(context)
                        .push(RouterPasswordViewPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).time_zone,
                    onTap: () =>
                        NavigationCubit.of(context).push(TimeZoneViewPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).ip_details,
                    onTap: () =>
                        NavigationCubit.of(context).push(IpDetailsViewPath()),
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).advanced.toUpperCase(),
              content: Column(
                children: [
                  AppSimplePanel(
                    title: getAppLocalizations(context).internet_settings,
                    onTap: () => NavigationCubit.of(context)
                        .push(InternetSettingsPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).lan,
                    onTap: () =>
                        NavigationCubit.of(context).push(LANSettingsPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).port_forwarding,
                    onTap: () =>
                        NavigationCubit.of(context).push(PortForwardingPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).mac_filtering,
                    onTap: () =>
                        NavigationCubit.of(context).push(MacFilteringPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).vlan,
                    infoText: 'OFF',
                    infoTextColor: ConstantColors.textBoxTextGray,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).advanced_routing,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).other,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).administration_access,
              content: Column(
                children: [
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).local_management_access,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).remote_access,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).web_ui,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).firmware.toUpperCase(),
              content: Column(
                children: [
                  AppPanelWithInfo(
                    title:
                        getAppLocalizations(context).automatic_firmware_update,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  AppPanelWithValueCheck(
                    title:
                        getAppLocalizations(context).automatic_firmware_update,
                    description: context
                            .read<NetworkCubit>()
                            .state
                            .selected!
                            .deviceInfo
                            ?.firmwareVersion ??
                        '',
                    valueText: 'Up to date',
                    isChecked: true,
                  ),
                ],
              ),
            ),
            box36(),
          ],
        ),
      ),
    );
  }
}
