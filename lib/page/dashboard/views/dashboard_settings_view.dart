import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
// import 'package:linksys_app/firebase/notification_helper.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/topology/_topology.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';

import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:linksys_widgets/widgets/panel/switch_trigger_tile.dart';
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
            _section(
              _othersSettingsSection(),
            ),
            // const AppGap.semiBig(),
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
            const AppGap.semiBig(),
            AppSwitchTriggerTile(
              value: isFwAutoUpdate,
              title: AppText.bodyLarge('Auto Firmware Update'),
              subtitle: AppText.bodySmall(
                'Enable/Disable auto firmware update',
                color: Colors.grey,
              ),
              onChanged: (value) {},
              event: (value) async {
                await ref
                    .read(firmwareUpdateProvider.notifier)
                    .setFirmwareUpdatePolicy(value
                        ? FirmwareUpdateSettings.firmwareUpdatePolicyAuto
                        : FirmwareUpdateSettings.firmwareUpdatePolicyManual);
              },
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

  _generalSettingsSection(
    BuildContext context,
  ) =>
      DashboardSettingsSection(
        title: 'GENERAL',
        items: [
          AppSectionItemData(
            title: 'WiFi',
            iconData: LinksysIcons.wifi,
            onTap: () => context.goNamed(RouteNamed.settingsWifi),
          ),
          AppSectionItemData(
            title: 'WiFi Advanced',
            iconData: LinksysIcons.wifi,
            onTap: () => context.goNamed(RouteNamed.wifiAdvancedSettings),
          ),
          AppSectionItemData(
            title: 'Nodes',
            iconData: LinksysIcons.router,
            onTap: () {
              ref.read(topologySelectedIdProvider.notifier).state = '';
              context.pushNamed(RouteNamed.settingsNodes);
            },
          ),
          AppSectionItemData(
            title: 'Router Password and Hint',
            // iconData: getCharactersIcons(context).smsDefault,
            onTap: () => context.goNamed(RouteNamed.settingsRouterPassword),
          ),
          AppSectionItemData(
            title: 'Time Zone',
            // iconData: getCharactersIcons(context).smsDefault,
            onTap: () => context.goNamed(RouteNamed.settingsTimeZone),
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
            onTap: () => context.goNamed(RouteNamed.settingsInternet),
          ),
          AppSectionItemData(
            title: 'IP Details',
            // iconData: getCharactersIcons(context).infoRound,
            onTap: () => context.goNamed(RouteNamed.settingsIpDetails),
          ),
          AppSectionItemData(
            title: 'Local Network Settings',
            // iconData: getCharactersIcons(context).nodesDefault,
            onTap: () => context.goNamed(RouteNamed.settingsLocalNetwork),
          ),
          AppSectionItemData(
            title: 'Port',
            // iconData: getCharactersIcons(context).nodesDefault,
            onTap: () => context.goNamed(RouteNamed.settingsPort),
          ),
        ],
      );

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
