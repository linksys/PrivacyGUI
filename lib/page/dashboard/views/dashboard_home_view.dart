import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/firmware_update/_firmware_update.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/extensions.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

import 'package:shimmer/shimmer.dart';

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
    final state = ref.watch(dashboardHomeProvider);
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;
    final master = ref
        .watch(deviceManagerProvider)
        .deviceList
        .firstWhereOrNull((device) => device.isAuthority);
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
      child: ResponsiveLayout.isMobileLayout(context)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _homeTitle(
                    state.mainWifiSsid,
                    wanStatus == NodeWANStatus.online,
                    isLoading,
                    state.isFirstPolling),
                const AppGap.extraBig(),
                _routerImage(isLoading, master),
                const AppGap.extraBig(),
                const Spacer(),
                _networkInfoTiles(state, isLoading),
                // const AppGap.extraBig(),
                // _speedTestTile(state, isLoading),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _homeTitle(
                          state.mainWifiSsid,
                          wanStatus == NodeWANStatus.online,
                          isLoading,
                          state.isFirstPolling),
                      const AppGap.extraBig(),
                      _routerImage(isLoading, master),
                    ],
                  ),
                ),
                Expanded(child: _networkInfoTiles(state, isLoading)),
              ],
            ),
    );
  }

  Widget _routerImage(bool isLoading, LinksysDevice? master) {
    final routerImage = CustomTheme.of(context).images.devicesxl.getByName(
        routerIconTestByModel(modelNumber: master?.modelNumber ?? ''));
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: isLoading || routerImage == null
            ? const AppSpinner(
                size: Size.fromWidth(300),
              )
            : Image(
                image: routerImage,
              ),
      ),
    );
  }

  Widget _homeTitle(
      String ssid, bool isOnline, bool isLoading, bool isFirstPolling) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _ssid(ssid, isLoading),
        if (isOnline) ...[
          _title(),
          const AppGap.regular(),
        ],
        Stack(
          children: [
            AnimatedOpacity(
              opacity: isFirstPolling ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(),
              ),
            ),
            AnimatedOpacity(
              opacity: isFirstPolling ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  Icon(
                    isOnline ? LinksysIcons.public : LinksysIcons.publicOff,
                    color: isOnline
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  AppText.titleLarge(
                    isOnline
                        ? loc(context).internetConnected
                        : loc(context).internetOffline,
                    color: isOnline
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLoading && !isOnline) _troubleshooting(),
        if (isOnline && hasNewFirmware()) ...[
          const AppGap.regular(),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.labelLarge(
                  loc(context).newFirmwareAvailable,
                ),
                const Icon(LinksysIcons.chevronRight)
              ],
            ),
            onTap: () {
              showFirmwareUpdateDialog(context);
            },
          ),
        ]
      ],
    );
  }

  Widget _ssid(String ssid, bool isLoading) {
    return isLoading
        ? Shimmer(
            gradient: _shimmerGradient,
            child: AppText.displaySmall(
              ssid,
            ),
          )
        : AppText.displaySmall(
            ssid,
          );
  }

  Widget _title() {
    final now = TimeOfDay.now();
    const morning = TimeOfDay(hour: 6, minute: 0);
    const noon = TimeOfDay(hour: 12, minute: 0);
    const evening = TimeOfDay(hour: 18, minute: 0);
    String text;
    if (now.compareTo(morning) > 0 && now.compareTo(noon) < 0) {
      text = loc(context).goodMorning;
    } else if (now.compareTo(evening) < 0) {
      text = loc(context).goodAfternoon;
    } else {
      text = loc(context).goodEvening;
    }
    return AppText.headlineSmall(text);
  }

  Widget _networkInfoTiles(DashboardHomeState state, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: _nodesInfoTile(state, isLoading)),
          Flexible(child: _wifiInfoTile(state.numOfWifi, isLoading)),
          Flexible(
              child: _devicesInfoTile(
                  state.numOfOnlineExternalDevices, isLoading)),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(int wifiCount, bool isLoading) {
    return _infoTile(
      iconData: LinksysIcons.wifi,
      text: loc(context).wifi,
      count: wifiCount,
      isLoading: isLoading,
      onTap: () {
        context.pushNamed(RouteNamed.wifiShare);
      },
    );
  }

  Widget _nodesInfoTile(DashboardHomeState state, bool isLoading) {
    return _infoTile(
      iconData: LinksysIcons.networkNode,
      text: loc(context).nodes,
      count: state.numOfNodes,
      isLoading: isLoading,
      sub: state.isAnyNodesOffline
          ? Icon(
              LinksysIcons.infoCircle,
              size: 24,
              color: Theme.of(context).colorScheme.error,
            )
          : null,
      onTap: () {
        ref.read(topologySelectedIdProvider.notifier).state = '';
        context.pushNamed(RouteNamed.settingsNodes);
      },
    );
  }

  Widget _devicesInfoTile(int numOfOnlineExternalDevices, bool isLoading) {
    return _infoTile(
      text: loc(context).devices,
      count: numOfOnlineExternalDevices,
      iconData: LinksysIcons.devices,
      isLoading: isLoading,
      onTap: () {
        context.goNamed(RouteNamed.dashboardDevices);
      },
    );
  }

  Widget _infoTile({
    required String text,
    required int count,
    required IconData iconData,
    Widget? sub,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        minHeight: 136,
      ),
      child: isLoading
          ? Card(
              elevation: 10,
              child: Shimmer(gradient: _shimmerGradient, child: Container()),
            )
          : AppCard(
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        iconData,
                        size: 24,
                      ),
                      if (sub != null) sub,
                    ],
                  ),
                  AppText.titleSmall(text),
                  AppText.displaySmall('$count'),
                ],
              ),
            ),
    );
  }

  Widget _troubleshooting() {
    return AppListCard(
      title: AppText.labelLarge(loc(context).troubleshoot),
      trailing: const Icon(LinksysIcons.chevronRight),
      onTap: () {},
    );
  }

  get _shimmerGradient => LinearGradient(
        colors: [
          Colors.grey,
          Colors.grey[300]!,
          Colors.grey,
        ],
        stops: const [
          0.1,
          0.3,
          0.4,
        ],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      );

  void _firmwareUpdateCheck() {
    Future.doWhile(() => !mounted).then((_) {
      firmware.checkFirmwareUpdateStatus();
    });
  }

  bool hasNewFirmware() {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
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
