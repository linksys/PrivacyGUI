import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/internet_status.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/assign_ip/web_assign_ip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

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
    ref.read(menuController).setTo(NaviType.home);
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final horizontalLayout =
        ref.watch(dashboardHomeProvider).isHorizontalLayout;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;

    return StyledAppPageView.withSliver(
      scrollable: true,
      onRefresh: () async {
        await ref.read(pollingProvider.notifier).forcePolling();
      },
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      padding: const EdgeInsets.only(
        top: Spacing.large3,
        bottom: Spacing.medium,
      ),
      child: (context, constraints) => ResponsiveLayout(
        desktop: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const DashboardHomeTitle(),
            const AppGap.large1(),
            !hasLanPort
                ? _desktopNoLanPortsLayout()
                : horizontalLayout
                    ? _desktopHorizontalLayout()
                    : _desktopVerticalLayout(),
          ],
        ),
        mobile: _mobileLayout(),
      ),
    );
  }

  Widget _desktopNoLanPortsLayout() {
    return Column(
      children: [
        SizedBox(
          height: 256,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 8.col, child: InternetConnectionWidget()),
              AppGap.gutter(),
              SizedBox(width: 4.col, child: DashboardHomePortAndSpeed()),
            ],
          ),
        ),
        const AppGap.medium(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 4.col,
              child: Column(
                children: const [
                  DashboardNetworks(),
                  AppGap.medium(),
                  DashboardQuickPanel(),
                  // _networkInfoTiles(state, isLoading),
                ],
              ),
            ),
            AppGap.gutter(),
            SizedBox(
                width: 8.col,
                child: Column(
                  children: [
                    if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                      VPNStatusTile(),
                      AppGap.medium(),
                    ],
                    DashboardWiFiGrid(),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Widget _desktopHorizontalLayout() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: Column(
              children: [
                InternetConnectionWidget(),
                AppGap.medium(),
                DashboardHomePortAndSpeed(),
                AppGap.medium(),
                DashboardWiFiGrid(),
              ],
            ),
          ),
          const AppGap.gutter(),
          SizedBox(
              width: 4.col,
              child: Column(
                children: [
                  DashboardNetworks(),
                  AppGap.medium(),
                  if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                    VPNStatusTile(),
                    AppGap.medium(),
                  ],
                  DashboardQuickPanel(),
                  // _networkInfoTiles(state, isLoading),
                ],
              )),
        ],
      ),
    );
  }

  Widget _desktopVerticalLayout() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 3.col,
            child: const Column(
              children: [
                DashboardHomePortAndSpeed(),
                AppGap.medium(),
                DashboardQuickPanel(),
              ],
            ),
          ),
          const AppGap.gutter(),
          Expanded(
            child: Column(
              children: [
                InternetConnectionWidget(),
                AppGap.medium(),
                DashboardNetworks(),
                AppGap.medium(),
                if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                  VPNStatusTile(),
                  AppGap.medium(),
                ],
                DashboardWiFiGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardHomeTitle(),
        AppGap.large1(),
        InternetConnectionWidget(),
        AppGap.medium(),
        DashboardHomePortAndSpeed(),
        AppGap.medium(),
        DashboardNetworks(),
        if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
          AppGap.medium(),
          VPNStatusTile(),
        ],
        AppGap.medium(),
        DashboardQuickPanel(),
        AppGap.medium(),
        DashboardWiFiGrid(),
        AppGap.medium(),
      ],
    );
  }

  void _showFirmwareUpdateCountdownDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _FirmwareUpdateCountdownDialog(onFinish: reload);
      },
    );
  }

  void _firmwareUpdateCheck() {
    Future.doWhile(() => !mounted).then((_) {
      SharedPreferences.getInstance().then((pref) {
        final fwUpdated = pref.getBool(pFWUpdated) ?? false;
        if (!fwUpdated) {
          firmware.fetchAvailableFirmwareUpdates();
        } else {
          pref.setBool(pFWUpdated, false);
          _showFirmwareUpdateCountdownDialog();
        }
      });
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

class _FirmwareUpdateCountdownDialog extends StatefulWidget {
  final VoidCallback onFinish;
  const _FirmwareUpdateCountdownDialog({required this.onFinish});

  @override
  State<_FirmwareUpdateCountdownDialog> createState() =>
      _FirmwareUpdateCountdownDialogState();
}

class _FirmwareUpdateCountdownDialogState
    extends State<_FirmwareUpdateCountdownDialog> {
  int _seconds = 5;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 1) {
        _timer.cancel();
        Navigator.of(context).pop();
        widget.onFinish();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleLarge(loc(context).firmwareUpdated),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSpinner(),
          AppGap.medium(),
          AppText.labelLarge(
            loc(context).firmwareUpdateCountdownMessage(_seconds),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
