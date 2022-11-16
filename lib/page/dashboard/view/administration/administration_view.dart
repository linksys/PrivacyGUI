import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

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
    return BasePageView(
      padding: EdgeInsets.zero,
      scrollable: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          getAppLocalizations(context).administration,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      child: BasicLayout(
        content: Column(
          children: [
            box16(),
            administrationSection(
              title: getAppLocalizations(context).general.toUpperCase(),
              content: Column(
                children: [
                  administrationTile(
                    title: title(
                        getAppLocalizations(context).router_password_and_hint),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () => NavigationCubit.of(context)
                        .push(RouterPasswordViewPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).time_zone),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(TimeZoneViewPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).ip_details),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(IpDetailsViewPath()),
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).advanced.toUpperCase(),
              content: Column(
                children: [
                  administrationTile(
                    title:
                        title(getAppLocalizations(context).internet_settings),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () => NavigationCubit.of(context)
                        .push(InternetSettingsPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).lan),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(LANSettingsPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).port_forwarding),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(PortForwardingPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).mac_filtering),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).vlan),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  administrationTile(
                    title:
                        title(getAppLocalizations(context).advanced_routing),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                  administrationTile(
                    title: title(getAppLocalizations(context).other),
                    value: const Text(''),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () =>
                        NavigationCubit.of(context).push(UnknownPath()),
                  ),
                ],
              ),
            ),
            administrationSection(
              title: getAppLocalizations(context).firmware.toUpperCase(),
              content: Column(
                children: [
                  administrationTile(
                    title: title(getAppLocalizations(context)
                        .automatic_firmware_update),
                    value: const Text('On'),
                    icon: Image.asset('assets/images/icon_chevron.png'),
                    onPress: () => NavigationCubit.of(context)
                        .push(RouterPasswordViewPath()),
                  ),
                  administrationTileDesc(
                    title: title(getAppLocalizations(context)
                        .node_detail_label_firmware_version),
                    value: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        subTitle(
                            getAppLocalizations(context).up_to_date),
                        Image.asset(
                            'assets/images/icon_check_green.png')
                      ],
                    ),
                    description: subTitle(context.read<NetworkCubit>().state.selected!.deviceInfo?.firmwareVersion ?? ''),
                  )
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
