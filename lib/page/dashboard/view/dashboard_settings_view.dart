import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_moab/route/constants.dart';

import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index, AppSectionItemData item);

class DashboardSettingsView extends ConsumerStatefulWidget {
  const DashboardSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardSettingsView> createState() =>
      _DashboardSettingsViewState();
}

class _DashboardSettingsViewState extends ConsumerState<DashboardSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return AppPageView.noNavigationBar(
            scrollable: true,
            child: EnabledOpacityWidget(
              enabled: state.selected?.deviceInfo != null,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppGap.semiBig(),
                    _title(),
                    const AppGap.semiBig(),
                    _section(
                      _generalSettingsSection(context),
                    ),
                    const AppGap.semiBig(),
                    _section(
                      _advancedSettingsSection(),
                    ),
                    const AppGap.semiBig(),
                    AppTertiaryButton.noPadding('Log out', onTap: () {
                      ref.read(authProvider.notifier).logout();
                    }),
                    const AppGap.semiBig(),
                    FutureBuilder(
                        future: PackageInfo.fromPlatform()
                            .then((value) => value.version),
                        initialData: '-',
                        builder: (context, data) {
                          return AppText.label(
                            'version ${data.data}',
                          );
                        }),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _title() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText.screenName(
              'Settings',
            )
          ],
        ),
      ],
    );
  }

  Widget _section(DashboardSettingsSection sectionItem) {
    return AppSection.withList(
      header: AppSectionLabel(label: sectionItem.title),
      items: sectionItem.items,
    );
  }

  _generalSettingsSection(
    BuildContext context,
  ) =>
      DashboardSettingsSection(
        title: 'GENERAL',
        items: [
          AppSectionItemData(
            title: 'Notifications',
            iconData: getCharactersIcons(context).smsDefault,
            onTap: () => context.goNamed('notifications'),
          ),
          AppSectionItemData(
            title: 'WiFi',
            iconData: getCharactersIcons(context).wifiDefault,
            onTap: () => context.goNamed('wifiSettings'),
          ),
          AppSectionItemData(
            title: 'Nodes',
            iconData: getCharactersIcons(context).nodesDefault,
            onTap: () => context.pushNamed(RouteNamed.settingsNodes),
          ),
          AppSectionItemData(
            title: 'Router Password and Hint',
            // iconData: getCharactersIcons(context).smsDefault,
            onTap: () => context.goNamed('routerPassword'),
          ),
          AppSectionItemData(
            title: 'Time Zone',
            // iconData: getCharactersIcons(context).smsDefault,
            onTap: () => context.goNamed('timeZone'),
          ),
        ],
      );

//
  _advancedSettingsSection() => DashboardSettingsSection(
        title: 'ADVANCED',
        items: [
          AppSectionItemData(
            title: 'Internet Settings',
            // iconData: getCharactersIcons(context).profileDefault,
            onTap: () => context.goNamed('internetSettings'),
          ),
          AppSectionItemData(
            title: 'IP Details',
            // iconData: getCharactersIcons(context).infoRound,
            onTap: () => context.goNamed('ipDetails'),
          ),
          AppSectionItemData(
            title: 'Local Network Settings',
            // iconData: getCharactersIcons(context).nodesDefault,
            onTap: () => context.goNamed('localNetworkSettings'),
          ),
        ],
      );
}

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<AppSectionItemData> items;
}
