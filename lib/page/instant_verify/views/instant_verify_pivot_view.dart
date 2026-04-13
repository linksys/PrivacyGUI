import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';

/// Main entry point for the Instant Verify pivot.
///
/// Takes over [menuInstantVerify] inside the authenticated PrivacyGUI.
/// Tab structure (PRD v0.7):
///   0: Instant-Test   — one-touch automated diagnostics + auto-fix actions
///   1: My Devices     — device list with signal quality + device-specific help
///   2: My Network     — mesh nodes, internet connection, WiFi overview
///   3: Help Me Fix It — 5 guided flows for issues needing investigation
class InstantVerifyPivotView extends ConsumerStatefulWidget {
  const InstantVerifyPivotView({super.key});

  @override
  ConsumerState<InstantVerifyPivotView> createState() =>
      _InstantVerifyPivotViewState();
}

class _InstantVerifyPivotViewState
    extends ConsumerState<InstantVerifyPivotView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  /// Notifier used to open a specific flow directly in HelpMeFixItTab.
  final _helpMeFlowNotifier = ValueNotifier<int?>(null);
  /// Carries the specific device selected in My Devices to the flow.
  final _helpMeFlowDeviceNotifier = ValueNotifier<DiagnosticClient?>(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Re-tap detection is handled via TabBar.onTap — addListener doesn't
    // fire when the user taps the already-active tab (no animation change).
  }

  @override
  void dispose() {
    _tabController.dispose();
    _helpMeFlowNotifier.dispose();
    _helpMeFlowDeviceNotifier.dispose();
    super.dispose();
  }

  void _showRouterInfo(BuildContext context, InstantVerifyPivotState state) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final upDays = state.uptimeSeconds > 0
            ? '${state.uptimeSeconds ~/ 86400}d ${(state.uptimeSeconds % 86400) ~/ 3600}h'
            : null;
        final rows = <(String, String)>[
          if (state.routerModel != null) ('Model', state.routerModel!),
          if (state.routerFirmware != null) ('Firmware', state.routerFirmware!),
          if (state.routerSerial != null) ('Serial', state.routerSerial!),
          if (state.routerMac != null) ('MAC', state.routerMac!),
          if (upDays != null) ('Uptime', upDays),
          if (state.wanIpAddress != null) ('WAN IP', state.wanIpAddress!),
          if (state.wanConnectionType != null)
            ('Connection', state.wanConnectionType!),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              Text('Router Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                      color: scheme.onSurface)),
              const SizedBox(height: 16),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 90,
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant))),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant Help'),
        actions: [
          Consumer(builder: (ctx, r, _) {
            final state = r.watch(instantVerifyPivotProvider);
            if (state.routerModel == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: 'Router info',
              onPressed: () => _showRouterInfo(ctx, state),
            );
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            // Re-tapping Help Me Fix It while already on it resets to landing
            if (index == 3 && _tabController.index == 3) {
              _helpMeFlowNotifier.value = -1;
            }
          },
          tabs: const [
            Tab(text: 'Instant-Test'),
            Tab(text: 'My Devices'),
            Tab(text: 'My Network'),
            Tab(text: 'Help Me Fix It'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            onViewClients: () => _tabController.animateTo(1),
            onNavigateToFlow: (flowIndex) {
              // flowIndex 0-4 maps to HelpMeFixIt flows 1-5
              _helpMeFlowNotifier.value = flowIndex + 1;
              _tabController.animateTo(3);
            },
          ),
          MyDevicesTab(
            onNavigateToFlow: (flowIndex, {DiagnosticClient? device}) {
              _helpMeFlowDeviceNotifier.value = device;
              _helpMeFlowNotifier.value = flowIndex;
              _tabController.animateTo(3);
            },
          ),
          const MyNetworkTab(),
          HelpMeFixItTab(
            pendingFlowNotifier: _helpMeFlowNotifier,
            pendingFlowDeviceNotifier: _helpMeFlowDeviceNotifier,
            onNavigateToMyDevices: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown for tabs not yet implemented.
class _ComingSoonTab extends StatelessWidget {
  final String label;
  final String description;

  const _ComingSoonTab({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction,
              size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
