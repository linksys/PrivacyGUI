import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';

import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index, DashboardSettingsItem item);

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
                      (index, item) {
                        context.goNamed(item.path);
                      },
                    ),
                    const AppGap.semiBig(),
                    _section(
                      _advancedSettingsSection(),
                      (index, item) {
                        context.goNamed(item.path);
                      },
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

  Widget _section(
      DashboardSettingsSection sectionItem, OnMenuItemClick onItemClick) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.tags(
          sectionItem.title,
        ),
        const AppGap.small(),
        ...sectionItem.items.map((e) => InkWell(
              onTap: () => onItemClick(sectionItem.items.indexOf(e), e),
              child: AppSimplePanel(
                title: e.title,
                // icon: getCharactersIcons(context).getByName(e.iconId),
              ),
            )),
      ],
    );
  }

  _generalSettingsSection(BuildContext context) => DashboardSettingsSection(
        title: 'GENERAL',
        items: [
          DashboardSettingsItem(
            title: 'Notifications',
            iconId: 'notificationsDefault',
            path: 'notifications',
          ),
          DashboardSettingsItem(
            title: 'WiFi',
            iconId: 'wifiDefault',
            path: 'wifiSettings',
          ),
          DashboardSettingsItem(
            title: 'Nodes',
            iconId: 'administrationDefault',
            path: 'nodes',
          ),
          DashboardSettingsItem(
            title: 'Router Password and Hint',
            iconId: 'priorityDefault',
            path: 'routerPassword',
          ),
          DashboardSettingsItem(
            title: 'Time Zone',
            iconId: 'clockRound',
            path: 'timeZone',
          ),
        ],
      );

//
  _advancedSettingsSection() => DashboardSettingsSection(
        title: 'ADVANCED',
        items: [
          DashboardSettingsItem(
            title: 'Internet Settings',
            iconId: 'profileDefault',
            path: 'Unknown',
          ),
          DashboardSettingsItem(
            title: 'IP Details',
            iconId: 'infoRound',
            path: 'Unknown',
          ),
          DashboardSettingsItem(
            title: 'Local Network Settings',
            iconId: 'helpRound',
            path: 'Unknown',
          ),
        ],
      );
}

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<DashboardSettingsItem> items;
}

class DashboardSettingsItem {
  DashboardSettingsItem({
    required this.title,
    required this.iconId,
    required this.path,
  });

  final String title;
  final String iconId;
  final String path;
}
