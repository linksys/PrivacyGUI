import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/panel_bases.dart';

import 'common_widget.dart';

class AdministrationView extends ArgumentsConsumerStatefulView {
  const AdministrationView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<AdministrationView> createState() => _AdministrationViewState();
}

class _AdministrationViewState extends ConsumerState<AdministrationView> {
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
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(RouterPasswordViewPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).time_zone,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(TimeZoneViewPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).ip_details,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(IpDetailsViewPath()),
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
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(InternetSettingsPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).lan,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(LANSettingsPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).port_forwarding,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(PortForwardingPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).mac_filtering,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(MacFilteringPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).vlan,
                    infoText: 'OFF',
                    infoTextColor: ConstantColors.textBoxTextGray,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).advanced_routing,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
                  ),
                  AppSimplePanel(
                    title: getAppLocalizations(context).other,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
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
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).remote_access,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
                  ),
                  AppPanelWithInfo(
                    title: getAppLocalizations(context).web_ui,
                    infoText: 'ON',
                    infoTextColor: ConstantColors.secondaryElectricGreen,
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
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
                    onTap: () => ref
                        .read(navigationsProvider.notifier)
                        .push(UnknownPath()),
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
