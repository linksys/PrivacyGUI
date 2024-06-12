import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
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
        top: Spacing.big,
        left: Spacing.regular,
        right: Spacing.regular,
        bottom: Spacing.regular,
      ),
      child: ResponsiveLayout(
        desktop: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const DashboardHomeTitle(),
            const AppGap.big(),
            horizontalLayout
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            DashboardHomePortAndSpeed(),
                            DashboardWiFiGrid(),
                          ],
                        ),
                      ),
                      Expanded(
                          child: Column(
                        children: [
                          DashboardNetworks(),
                          // _networkInfoTiles(state, isLoading),
                        ],
                      )),
                    ],
                  )
                : const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: DashboardHomePortAndSpeed(),
                      ),
                      AppGap.regular(),
                      Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              DashboardNetworks(),
                              DashboardWiFiGrid(),

                              // _networkInfoTiles(state, isLoading),
                            ],
                          )),
                    ],
                  ),
          ],
        ),
        mobile: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHomeTitle(),

            AppGap.extraBig(),
            DashboardNetworks(),
            AppGap.extraBig(),
            Spacer(),
            DashboardHomePortAndSpeed(),
            DashboardWiFiGrid(),
            // const AppGap.extraBig(),
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

  // Widget _speedTestTile(DashboardHomeState state, bool isLoading) {
  //   return GestureDetector(
  //       onTap: () => context.goNamed(RouteNamed.dashboardSpeedTest),
  //       child: SizedBox(
  //         width: double.infinity,
  //         height: 160,
  //         child: Card(
  //           elevation: 10,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10.0),
  //           ),
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(
  //                 horizontal: Spacing.regular, vertical: Spacing.regular),
  //             child: isLoading
  //                 ? Shimmer(
  //                     gradient: _shimmerGradient,
  //                     child: _speedResult(state),
  //                   )
  //                 : _speedResult(state),
  //           ),
  //         ),
  //       ));
  // }

  // Widget _speedResult(DashboardHomeState state) {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.start,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       AppText.titleLarge('Speed'),
  //       Expanded(
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       const AppGap.semiSmall(),
  //                       AppText.titleLarge(state.uploadResult.value),
  //                     ],
  //                   ),
  //                   Text('${state.uploadResult.unit}ps'),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       const AppGap.semiSmall(),
  //                       AppText.titleLarge(state.downloadResult.value),
  //                     ],
  //                   ),
  //                   Text('${state.downloadResult.unit}ps'),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
