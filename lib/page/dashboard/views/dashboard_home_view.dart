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
import 'package:privacy_gui/page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
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
    _firmwareUpdateCheck();
    ref.read(menuController).setTo(NaviType.home);
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final state = ref.watch(dashboardHomeProvider);
    final preferences = ref.watch(dashboardPreferencesProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isHorizontalLayout = state.isHorizontalLayout;
    final isSupportVPN = getIt.get<ServiceHelper>().isSupportVPN();

    // Get display modes from preferences
    final internetMode =
        preferences.getMode(DashboardWidgetSpecs.internetStatus.id);
    final networksMode = preferences.getMode(DashboardWidgetSpecs.networks.id);
    final wifiMode = preferences.getMode(DashboardWidgetSpecs.wifiGrid.id);
    final quickPanelMode =
        preferences.getMode(DashboardWidgetSpecs.quickPanel.id);
    final portAndSpeedMode =
        preferences.getMode(DashboardWidgetSpecs.portAndSpeed.id);

    return UiKitPageView.withSliver(
      scrollable: true,
      onRefresh: () async {
        await ref.read(pollingProvider.notifier).forcePolling();
      },
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      padding: EdgeInsets.only(
        top: 32.0,
        bottom: 16.0,
      ),
      child: (childContext, constraints) {
        // 1. Determine layout variant (single source of truth)
        final variant = DashboardLayoutVariant.fromContext(
          childContext,
          hasLanPort: hasLanPort,
          isHorizontalLayout: isHorizontalLayout,
        );

        // 2. Build layout context (IoC - widgets built here, passed to strategy)
        final layoutContext = DashboardLayoutContext(
          context: childContext,
          ref: ref,
          state: state,
          hasLanPort: hasLanPort,
          isHorizontalLayout: isHorizontalLayout,
          displayModes: preferences.widgetModes,
          title: const DashboardHomeTitle(),
          internetWidget: InternetConnectionWidget(displayMode: internetMode),
          networksWidget: DashboardNetworks(displayMode: networksMode),
          wifiGrid: DashboardWiFiGrid(displayMode: wifiMode),
          quickPanel: DashboardQuickPanel(displayMode: quickPanelMode),
          vpnTile: isSupportVPN ? const VPNStatusTile() : null,
          buildPortAndSpeed: (config) => DashboardHomePortAndSpeed(
            config: config,
            displayMode: portAndSpeedMode,
          ),
        );

        // 3. Delegate to strategy
        final strategy = DashboardLayoutFactory.create(variant);
        return strategy.build(layoutContext);
      },
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
