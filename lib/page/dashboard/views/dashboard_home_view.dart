import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardHomeView extends ConsumerStatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends ConsumerState<DashboardHomeView> {
  late FirmwareUpdateNotifier firmware;

  @override
  void initState() {
    super.initState();
    firmware = ref.read(firmwareUpdateProvider.notifier);
    // _pushNotificationCheck();
    _firmwareUpdateCheck();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalLayout =
        ref.watch(dashboardHomeProvider).isHorizontalLayout;

    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      padding: const EdgeInsets.only(
        top: Spacing.large3,
        bottom: Spacing.medium,
      ),
      child: ResponsiveLayout(
        desktop: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const DashboardHomeTitle(),
            const AppGap.large3(),
            horizontalLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 8.col,
                        child: const Column(
                          children: [
                            DashboardHomePortAndSpeed(),
                            AppGap.medium(),
                            DashboardWiFiGrid(),
                          ],
                        ),
                      ),
                      const AppGap.gutter(),
                      SizedBox(
                          width: 4.col,
                          child: const Column(
                            children: [
                              DashboardNetworks(),
                              // _networkInfoTiles(state, isLoading),
                            ],
                          )),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 3.col,
                        child: const DashboardHomePortAndSpeed(),
                      ),
                      const AppGap.gutter(),
                      SizedBox(
                        width: 9.col,
                        child: const Column(
                          children: [
                            DashboardNetworks(),
                            AppGap.medium(),
                            DashboardWiFiGrid(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        mobile: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHomeTitle(),
            DashboardHomePortAndSpeed(),
            AppGap.medium(),
            DashboardNetworks(),
            AppGap.medium(),
            DashboardWiFiGrid(),
            // const AppGap.large5(),
            // _speedTestTile(state, isLoading),
          ],
        ),
      ),
    );
  }

  void _firmwareUpdateCheck() {
    Future.doWhile(() => !mounted).then((_) {
      firmware.checkFirmwareUpdateStatus();
    });
  }

  // void _pushNotificationCheck() {
  //   if (kIsWeb) {
  //     return;
  //   }
  //   if (!mounted) {
  //     return;
  //   }
  //   if (GoRouter.of(context).routerDelegate.currentConfiguration.fullPath !=
  //       RoutePath.dashboardHome) {
  //     return;
  //   }
  //   SharedPreferences.getInstance().then((prefs) {
  //     final isPushPromptShown = prefs.getBool(
  //             SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt)) ??
  //         false;
  //     if (!isPushPromptShown) {
  //       prefs.setBool(
  //           SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt),
  //           true);
  //       showAdaptiveDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: AppText.bodyLarge('Push Notification'),
  //           content: AppText.bodyLarge(
  //               'Do you want to receive Linksys push notifications?'),
  //           actions: [
  //             AppTextButton(
  //               'Yes',
  //               onTap: () {
  //                 final deviceToken = prefs.getString(pDeviceToken);
  //                 if (deviceToken != null) {
  //                   ref
  //                       .read(smartDeviceProvider.notifier)
  //                       .registerSmartDevice(deviceToken);
  //                 } else {}
  //                 context.pop();
  //               },
  //             ),
  //             AppTextButton('No', onTap: () {
  //               context.pop();
  //             })
  //           ],
  //         ),
  //       );
  //     }
  //   });
  // }
}
