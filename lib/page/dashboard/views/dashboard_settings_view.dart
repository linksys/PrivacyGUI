import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

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
    return StyledAppPageView(
      scrollable: true,
      child: (context, constraints) => SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            _title(),
            const AppGap.large2(),
            _section(
              _othersSettingsSection(),
            ),
          ],
        ),
      ),
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

  _othersSettingsSection() => DashboardSettingsSection(
        title: 'OTHERS(TBC)',
        items: [
          AppSectionItemData(
              title: 'Troubleshooting',
              description: 'This is a description for this tile',
              onTap: () {
                context.goNamed(RouteNamed.troubleshooting);
              }),
          AppSectionItemData(
              title: 'DDNS Settings',
              description: 'This is a description for this tile',
              onTap: () {
                context.goNamed(RouteNamed.settingsDDNS);
              }),
          AppSectionItemData(
              title: 'Ipv6 Port Service',
              description: 'This is a description for this tile',
              onTap: () {
                context.goNamed(RouteNamed.ipv6PortServiceList);
              }),
          AppSectionItemData(
              title: 'Channel Finder',
              description: 'This is a description for this tile',
              onTap: () {
                context.goNamed(RouteNamed.channelFinderOptimize);
              }),
        ],
      );
}

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<AppSectionItemData> items;
}
