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
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/internet_status.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/wifi_grid.dart';
import 'package:privacy_gui/page/dashboard/views/sliver_dashboard_view.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
import 'package:privacy_gui/page/dashboard/providers/sliver_dashboard_controller_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    // LISTEN for dynamic constraints changes (Decoupled from SliverDashboardView)
    ref.listen(
      dashboardHomeProvider.select((s) => s.lanPortConnections.isNotEmpty),
      (_, __) => _updatePortsConstraints(),
    );
    ref.listen(
      dashboardHomeProvider.select((s) => s.isHorizontalLayout),
      (_, __) => _updatePortsConstraints(),
    );

    // Forced Display Mode Logic
    // If Custom Layout is OFF, force all components to use Normal (Standard) mode.
    // This ensures Legacy Layouts render correctly.
    final useCustom = preferences.useCustomLayout;

    if (useCustom) {
      // SliverDashboardView now contains TopBar and SafeArea internally
      // using DashboardOverlay + CustomScrollView + SliverDashboard architecture
      return const SliverDashboardView();
    }

    // Standard Layout: use strategy pattern
    return UiKitPageView.withSliver(
      scrollable: true,
      onRefresh: () async {
        await ref.read(pollingProvider.notifier).forcePolling();
      },
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
      child: (childContext, constraints) {
        // 1. Determine layout variant (Standard only)
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
          widgetConfigs: preferences.widgetConfigs,
          title: const DashboardHomeTitle(),
          internetWidget: FixedInternetConnectionWidget(
            key: const ValueKey('internet'),
            displayMode: DisplayMode.normal,
            useAppCard: true,
          ),
          networksWidget: FixedDashboardNetworks(
            key: const ValueKey('networks'),
            displayMode: DisplayMode.normal,
            useAppCard: true,
          ),
          wifiGrid: FixedDashboardWiFiGrid(
            key: const ValueKey('wifi'),
            displayMode: DisplayMode.normal,
          ),
          quickPanel: FixedDashboardQuickPanel(
            key: const ValueKey('quick'),
            displayMode: DisplayMode.normal,
            useAppCard: true,
          ),
          vpnTile: isSupportVPN ? const VPNStatusTile() : null,
          buildPortAndSpeed: (config) => FixedDashboardHomePortAndSpeed(
            key: const ValueKey('port'),
            config: config,
            displayMode: DisplayMode.normal,
            useAppCard: true,
          ),
        );

        // 3. Delegate to strategy (Standard only)
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

  /// Helper to get spec with dynamic constraints based on state
  WidgetSpec? _getDynamicSpec(String id) {
    if (id == DashboardWidgetSpecs.ports.id) {
      final state = ref.read(dashboardHomeProvider);
      return DashboardWidgetSpecs.getPortsSpec(
        hasLanPort: state.lanPortConnections.isNotEmpty,
        isHorizontal: state.isHorizontalLayout,
      );
    }
    return DashboardWidgetSpecs.getById(id);
  }

  /// Update constraints for Ports widget when layout context changes
  void _updatePortsConstraints() {
    final id = DashboardWidgetSpecs.ports.id;
    final spec = _getDynamicSpec(id);
    if (spec == null) return;

    final preferences = ref.read(dashboardPreferencesProvider);
    final mode = preferences.getMode(id);

    ref.read(sliverDashboardControllerProvider.notifier).updateItemConstraints(
          id,
          mode,
          overrideConstraints: spec.constraints[mode],
        );
  }
}
