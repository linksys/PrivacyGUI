import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/route/constants.dart';

import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

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
    final state = ref.watch(networkProvider);
    return StyledAppPageView(
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
              ],
            ),
          ),
        ));
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
            AppText.titleLarge(
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
            onTap: () => context.goNamed('notificationSettings'),
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
