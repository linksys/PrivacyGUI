import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/internet_status.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/dashboard/views/components/firmware_update_countdown_dialog.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/utils/assign_ip/base_assign_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/utils/assign_ip/web_assign_ip.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    return UiKitPageView.withSliver(
      scrollable: true,
      onRefresh: () async {
        await ref.read(pollingProvider.notifier).forcePolling();
      },
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      padding: EdgeInsets.only(
        top: 32.0, // was AppSpacing.large3
        bottom: 16.0, // was AppSpacing.medium
      ),
      child: (childContext, constraints) => AppResponsiveLayout(
        // New WidgetBuilder API: context has correct PageLayoutScope for colWidth
        desktop: (layoutContext) => Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardHomeTitle(),
            AppGap.xl(),
            !hasLanPort
                ? _desktopNoLanPortsLayout(layoutContext)
                : horizontalLayout
                    ? _desktopHorizontalLayout(layoutContext)
                    : _desktopVerticalLayout(layoutContext),
          ],
        ),
        mobile: (context) => _mobileLayout(),
      ),
    );
  }

  Widget _desktopNoLanPortsLayout(BuildContext layoutContext) {
    return Column(
      children: [
        SizedBox(
          height: 256,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  width: layoutContext.colWidth(8),
                  child: InternetConnectionWidget()),
              AppGap.gutter(),
              SizedBox(
                  width: layoutContext.colWidth(4),
                  child: DashboardHomePortAndSpeed()),
            ],
          ),
        ),
        AppGap.lg(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: layoutContext.colWidth(4),
              child: Column(
                children: [
                  DashboardNetworks(),
                  AppGap.lg(),
                  DashboardQuickPanel(),
                  // _networkInfoTiles(state, isLoading),
                ],
              ),
            ),
            AppGap.gutter(),
            SizedBox(
                width: layoutContext.colWidth(8),
                child: Column(
                  children: [
                    if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                      VPNStatusTile(),
                      AppGap.lg(),
                    ],
                    DashboardWiFiGrid(),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Widget _desktopHorizontalLayout(BuildContext layoutContext) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                InternetConnectionWidget(),
                AppGap.lg(),
                DashboardHomePortAndSpeed(),
                AppGap.lg(),
                DashboardWiFiGrid(),
              ],
            ),
          ),
          AppGap.gutter(),
          SizedBox(
              width: layoutContext.colWidth(4),
              child: Column(
                children: [
                  DashboardNetworks(),
                  AppGap.lg(),
                  if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                    VPNStatusTile(),
                    AppGap.lg(),
                  ],
                  DashboardQuickPanel(),
                  // _networkInfoTiles(state, isLoading),
                ],
              )),
        ],
      ),
    );
  }

  Widget _desktopVerticalLayout(BuildContext layoutContext) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: layoutContext.colWidth(3),
            child: Column(
              children: [
                DashboardHomePortAndSpeed(),
                AppGap.lg(),
                DashboardQuickPanel(),
              ],
            ),
          ),
          AppGap.gutter(),
          Expanded(
            child: Column(
              children: [
                InternetConnectionWidget(),
                AppGap.lg(),
                DashboardNetworks(),
                AppGap.lg(),
                if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
                  VPNStatusTile(),
                  AppGap.lg(),
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
        AppGap.xl(),
        InternetConnectionWidget(),
        AppGap.lg(),
        DashboardHomePortAndSpeed(),
        AppGap.lg(),
        DashboardNetworks(),
        if (getIt.get<ServiceHelper>().isSupportVPN()) ...[
          AppGap.lg(),
          VPNStatusTile(),
        ],
        AppGap.lg(),
        DashboardQuickPanel(),
        AppGap.lg(),
        DashboardWiFiGrid(),
        AppGap.lg(),
      ],
    );
  }

  void _showFirmwareUpdateCountdownDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FirmwareUpdateCountdownDialog(onFinish: reload);
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
}
