import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_test/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_test/views/my_network_tab.dart';
import 'package:privacy_gui/page/instant_test/views/overview_tab.dart';

class InstantTestPage extends ConsumerStatefulWidget {
  const InstantTestPage({super.key});

  @override
  ConsumerState<InstantTestPage> createState() => _InstantTestPageState();
}

class _InstantTestPageState extends ConsumerState<InstantTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // -1 = reset to landing menu; positive int = launch that flow
  final _helpMeFlowNotifier = ValueNotifier<int?>(null);
  // Carries the specific device selected in My Devices into Flow 3 (case 30)
  final _pendingFlowDeviceNotifier = ValueNotifier<DeviceUIModel?>(null);

  static const int _tabCount = 4;
  static const int _helpMeFixItTabIndex = 3;
  static const int _myDevicesTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    // Re-tap on Tab 3 while already active → reset flow to landing menu
    int _previousTab = 0;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == _helpMeFixItTabIndex &&
            _previousTab == _helpMeFixItTabIndex) {
          _helpMeFlowNotifier.value = -1;
        }
        _previousTab = _tabController.index;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instantTestProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _helpMeFlowNotifier.dispose();
    _pendingFlowDeviceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Taller toolbar so the 3-line stacked router info fits.
        toolbarHeight: 64,
        title: Text(loc(context).instantTest),
        actions: [
          Consumer(builder: (ctx, r, _) {
            final s = r.watch(instantTestProvider);
            final colors = Theme.of(ctx).colorScheme;
            final hasInfo = s.routerModel != null ||
                s.firmwareVersion != null ||
                s.routerSerial != null;
            if (!hasInfo) {
              return IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                tooltip: 'Router info',
                onPressed: () => _showRouterInfo(ctx, s),
              );
            }
            Widget line(String label, String value) => Text(
                  '$label $value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface),
                );
            return InkWell(
              onTap: () => _showRouterInfo(ctx, s),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (s.routerModel != null) line('Model:', s.routerModel!),
                      if (s.firmwareVersion != null)
                        line('Ver:', s.firmwareVersion!),
                      if (s.routerSerial != null)
                        line('Serial:', s.routerSerial!),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: loc(context).instantTestTabOverview),
            Tab(text: loc(context).instantTestTabDevices),
            Tab(text: loc(context).instantTestTabNetwork),
            Tab(text: loc(context).instantTestTabHelpFix),
          ],
        ),
      ),
      body: SelectionArea(
        child: TabBarView(
        controller: _tabController,
        children: [
          const OverviewTab(),
          MyDevicesTab(
            // Carries device into Flow 3 (case 30 = device-specific path)
            onGoToFlow3: (DeviceUIModel? device) {
              _pendingFlowDeviceNotifier.value = device;
              // Use case 30 (device-specific slow path) when device is known,
              // case 3 (generic) when no device context
              _helpMeFlowNotifier.value = device != null ? 30 : 3;
              _tabController.animateTo(_helpMeFixItTabIndex);
            },
          ),
          const MyNetworkTab(),
          HelpMeFixItTab(
            pendingFlowNotifier: _helpMeFlowNotifier,
            pendingFlowDeviceNotifier: _pendingFlowDeviceNotifier,
            onNavigateToMyDevices: () =>
                _tabController.animateTo(_myDevicesTabIndex),
          ),
        ],
      ),
      ),
    );
  }

  /// Bottom sheet with full router details (model, firmware, serial, uptime,
  /// WAN). Opened by tapping the AppBar router-info header.
  void _showRouterInfo(BuildContext context, InstantTestState state) {
    final scheme = Theme.of(context).colorScheme;
    final upDays = state.uptimeSeconds != null && state.uptimeSeconds! > 0
        ? '${state.uptimeSeconds! ~/ 86400}d ${(state.uptimeSeconds! % 86400) ~/ 3600}h'
        : null;
    final rows = <(String, String)>[
      if (state.routerModel != null) ('Model', state.routerModel!),
      if (state.firmwareVersion != null) ('Firmware', state.firmwareVersion!),
      if (state.routerSerial != null) ('Serial', state.routerSerial!),
      if (upDays != null) ('Uptime', upDays),
      if (state.wanStatus?.ipAddress.isNotEmpty == true)
        ('WAN IP', state.wanStatus!.ipAddress),
    ];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Router Details',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: scheme.onSurface)),
            const SizedBox(height: 16),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(
                      width: 90,
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant))),
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
