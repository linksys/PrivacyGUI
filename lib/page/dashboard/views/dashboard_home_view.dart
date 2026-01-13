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
import 'package:privacy_gui/page/dashboard/strategies/custom_dashboard_layout_strategy.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
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

    // Forced Display Mode Logic
    // If Custom Layout is OFF, force all components to use Normal (Standard) mode.
    // This ensures Legacy Layouts render correctly.
    final useCustom = preferences.useCustomLayout;

    final internetMode = useCustom
        ? preferences.getMode(DashboardWidgetSpecs.internetStatus.id)
        : DisplayMode.normal;
    final networksMode = useCustom
        ? preferences.getMode(DashboardWidgetSpecs.networks.id)
        : DisplayMode.normal;
    final wifiMode = useCustom
        ? preferences.getMode(DashboardWidgetSpecs.wifiGrid.id)
        : DisplayMode.normal;
    final quickPanelMode = useCustom
        ? preferences.getMode(DashboardWidgetSpecs.quickPanel.id)
        : DisplayMode.normal;
    final portAndSpeedMode = useCustom
        ? preferences.getMode(DashboardWidgetSpecs.portAndSpeed.id)
        : DisplayMode.normal;

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
        // Note: We use keys combining mode and useCustom to force rebuilds when switching strategies.
        final layoutContext = DashboardLayoutContext(
          context: childContext,
          ref: ref,
          state: state,
          hasLanPort: hasLanPort,
          isHorizontalLayout: isHorizontalLayout,
          widgetConfigs: preferences.widgetConfigs,
          title: const DashboardHomeTitle(),
          internetWidget: InternetConnectionWidget(
            key: ValueKey('internet-$internetMode-$useCustom'),
            displayMode: internetMode,
          ),
          networksWidget: DashboardNetworks(
            key: ValueKey('networks-$networksMode-$useCustom'),
            displayMode: networksMode,
          ),
          wifiGrid: DashboardWiFiGrid(
            key: ValueKey('wifi-$wifiMode-$useCustom'),
            displayMode: wifiMode,
          ),
          quickPanel: DashboardQuickPanel(
            key: ValueKey('quick-$quickPanelMode-$useCustom'),
            displayMode: quickPanelMode,
          ),
          vpnTile: isSupportVPN ? const VPNStatusTile() : null,
          buildPortAndSpeed: (config) => DashboardHomePortAndSpeed(
            key: ValueKey('port-$portAndSpeedMode-$useCustom'),
            config: config,
            displayMode: portAndSpeedMode,
          ),
        );

        // 3. Delegate to strategy
        final strategy = useCustom
            ? const CustomDashboardLayoutStrategy()
            : DashboardLayoutFactory.create(variant);
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
