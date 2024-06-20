import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
// import 'package:privacy_gui/firebase/notification_helper.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef OnMenuItemClick = void Function(int index, AppSectionItemData item);

class DashboardSettingsView extends ConsumerStatefulWidget {
  const DashboardSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardSettingsView> createState() =>
      _DashboardSettingsViewState();
}

class _DashboardSettingsViewState extends ConsumerState<DashboardSettingsView> {
  bool _pushEnabled = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _pushEnabled = prefs.getString(pDeviceToken) != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFwAutoUpdate = ref.watch(firmwareUpdateProvider
            .select((value) => value.settings.updatePolicy)) ==
        FirmwareUpdateSettings.firmwareUpdatePolicyAuto;
    return StyledAppPageView(
      scrollable: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large1(),
            _title(),
            const AppGap.large1(),
            _section(
              _othersSettingsSection(),
            ),
            // const AppGap.large1(),
            // AppSwitchTriggerTile(
            //   value: _pushEnabled,
            //   title: AppText.bodyLarge('Enable Push Notification'),
            //   subtitle: AppText.bodySmall(
            //     'Experiential',
            //     color: Colors.grey,
            //   ),
            //   onChanged: (value) {},
            //   event: (value) async {
            //     if (value) {
            //       await initCloudMessage((_){});
            //     } else {
            //       await removeCloudMessage();
            //     }
            //     SharedPreferences.getInstance().then((prefs) {
            //       setState(() {
            //         _pushEnabled = prefs.getString(pDeviceToken) != null;
            //       });
            //     });
            //   },
            // ),
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
