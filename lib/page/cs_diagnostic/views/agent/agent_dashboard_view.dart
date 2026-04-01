import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/flow_analysis_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/health_bar_widget.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/report_summary_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/router_info_card.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/signal_table_view.dart';

class AgentDashboardView extends ConsumerStatefulWidget {
  const AgentDashboardView({super.key});

  @override
  ConsumerState<AgentDashboardView> createState() => _AgentDashboardViewState();
}

class _AgentDashboardViewState extends ConsumerState<AgentDashboardView> {
  int _selectedComplaint = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(csDiagnosticProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(csDiagnosticProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant-Help'),
        actions: [
          if (state.loadState == DiagnosticLoadState.loaded)
            IconButton(
              icon: const Icon(Icons.description),
              tooltip: 'Generate report',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportSummaryView(state: state)),
              ),
            ),
          if (state.loadState == DiagnosticLoadState.loaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(csDiagnosticProvider.notifier).fetch(),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Exit agent mode',
            onPressed: () => ref.read(diagnosticAuthProvider.notifier).logout(),
          ),
        ],
      ),
      body: switch (state.loadState) {
        DiagnosticLoadState.loading || DiagnosticLoadState.idle =>
          const Center(child: CircularProgressIndicator()),
        DiagnosticLoadState.error => _buildError(context, state),
        DiagnosticLoadState.loaded => _buildDashboard(context, state),
      },
      floatingActionButton: _buildMockFab(context),
    );
  }

  Widget? _buildMockFab(BuildContext context) {
    final notifier = ref.read(csDiagnosticProvider.notifier);
    if (!notifier.useMock) return null;

    return FloatingActionButton.extended(
      onPressed: () => notifier.toggleDegraded(),
      icon: Icon(notifier.useDegraded ? Icons.check_circle : Icons.warning),
      label: Text(notifier.useDegraded ? 'Healthy' : 'Degraded'),
      tooltip: 'Toggle mock data scenario',
      backgroundColor: notifier.useDegraded
          ? Colors.orange.shade300
          : Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildError(BuildContext context, CsDiagnosticState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(state.errorMessage ?? 'Unknown error', textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(csDiagnosticProvider.notifier).fetch(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CsDiagnosticState state) {
    return SelectionArea(child: Column(
      children: [
        HealthBarWidget(state: state),
        if (state.flaggedClients.isNotEmpty || !state.wanConnected || state.routerUptimeSeconds < 7200)
          _buildAlertBanner(context, state),
        _buildComplaintSelector(context),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FlowAnalysisView(
                  complaintIndex: _selectedComplaint,
                  state: state,
                ),
                const SizedBox(height: 4),
                // Contextual data section per tab
                _buildContextualData(context, state),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  /// Shows different supporting data depending on which complaint tab is selected.
  Widget _buildContextualData(BuildContext context, CsDiagnosticState state) {
    return switch (_selectedComplaint) {
      0 => _contextSlowInternet(context, state),
      1 => _contextSlowDevice(context, state),
      2 => _contextDrops(context, state),
      3 => _contextCantConnect(context, state),
      4 => _contextDeadSpots(context, state),
      5 => _contextOffline(context, state),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Slow Internet: WAN details + band distribution + DHCP + radio ──
  Widget _contextSlowInternet(BuildContext context, CsDiagnosticState state) {
    final wanConn = state.wanStatus?['wanConnection'] as Map<String, dynamic>?;
    final wanIp = wanConn?['ipAddress'] as String? ?? state.wanStatus?['wanIPAddress'] as String?;
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    final on5 = state.clients.where((c) => c.band == '5GHz').length;
    final on6 = state.clients.where((c) => c.band == '6GHz').length;
    final wired = state.clients.where((c) => !c.isWireless).length;

    return Column(children: [
      _infoCard(context, 'Network Overview', Icons.lan, [
        _infoItem('WAN Status', state.wanConnected ? 'Connected' : 'Disconnected'),
        if (wanIp != null) _infoItem('WAN IP', wanIp),
        _infoItem('Devices', '${state.clients.length} total'),
        _infoItem('Band Split', '2.4G: $on24 | 5G: $on5${on6 > 0 ? ' | 6G: $on6' : ''} | Wired: $wired'),
        _infoItem('DHCP', '${state.dhcpLeasesCount}/${state.dhcpPoolLimit} (${(state.dhcpUtilization * 100).toInt()}%)'),
        _infoItem('Uptime', _formatUptime(state.routerUptimeSeconds)),
      ]),
      if (state.radioInfo != null)
        _buildRadioInfoCard(context, state),
      if (state.firmwareUpdateAvailable)
        _infoCard(context, 'Firmware Update Available', Icons.system_update, [
          _infoItem('Current', state.deviceInfo?['firmwareVersion'] ?? 'Unknown'),
          _infoItem('Available', state.availableFirmwareVersion ?? 'Unknown'),
        ]),
    ]);
  }

  // ── Slow Device: Signal table + radio config ───────────────────────
  Widget _contextSlowDevice(BuildContext context, CsDiagnosticState state) {
    return Column(children: [
      SignalTableView(clients: state.clients),
      if (state.radioInfo != null)
        _buildRadioInfoCard(context, state),
    ]);
  }

  // ── Drops: Router stability + radio config + signal table (marginal) ──
  Widget _contextDrops(BuildContext context, CsDiagnosticState state) {
    final marginalOrWorse = state.clients.where((c) =>
        c.isWireless && c.signalDecibels != null && c.signalDecibels! < -65).toList();

    return Column(children: [
      _infoCard(context, 'Router Stability', Icons.router, [
        _infoItem('Uptime', _formatUptime(state.routerUptimeSeconds)),
        _infoItem('CPU Load', '${state.routerHealth?['cpuLoad'] ?? 'N/A'}%'),
        _infoItem('Memory', '${state.routerHealth?['memoryLoad'] ?? 'N/A'}%'),
        _infoItem('Firmware', state.deviceInfo?['firmwareVersion'] ?? 'Unknown'),
        _infoItem('WAN', state.wanConnected ? 'Connected' : 'Disconnected'),
      ]),
      if (state.radioInfo != null)
        _buildRadioInfoCard(context, state),
      if (marginalOrWorse.isNotEmpty)
        SignalTableView(clients: marginalOrWorse),
    ]);
  }

  // ── Can't Connect: DHCP + radio config + guest network ─────────────
  Widget _contextCantConnect(BuildContext context, CsDiagnosticState state) {
    return Column(children: [
      _infoCard(context, 'Connection Capacity', Icons.settings_ethernet, [
        _infoItem('DHCP Used', '${state.dhcpLeasesCount}/${state.dhcpPoolLimit} (${(state.dhcpUtilization * 100).toInt()}%)'),
        _infoItem('Connected Devices', '${state.clients.length}'),
        _infoItem('Guest Network', state.guestNetworkEnabled ? 'Enabled' : 'Disabled'),
        if (state.radioInfo != null)
          _infoItem('Band Steering', state.bandSteeringEnabled ? 'Enabled' : 'Disabled'),
      ]),
      if (state.radioInfo != null)
        _buildRadioInfoCard(context, state),
    ]);
  }

  // ── Dead Spots: Full signal table + backhaul info ──────────────────
  Widget _contextDeadSpots(BuildContext context, CsDiagnosticState state) {
    return Column(children: [
      SignalTableView(clients: state.clients),
      if (state.backhaulInfo != null)
        _buildBackhaulCard(context, state),
    ]);
  }

  // ── Offline: Router info card + firmware ───────────────────────────
  Widget _contextOffline(BuildContext context, CsDiagnosticState state) {
    return Column(children: [
      RouterInfoCard(state: state),
      _infoCard(context, 'System Health', Icons.monitor_heart, [
        _infoItem('CPU Load', '${state.routerHealth?['cpuLoad'] ?? 'N/A'}'),
        _infoItem('Memory Load', '${state.routerHealth?['memoryLoad'] ?? 'N/A'}'),
        _infoItem('Uptime', _formatUptime(state.routerUptimeSeconds)),
      ]),
    ]);
  }

  Widget _buildRadioInfoCard(BuildContext context, CsDiagnosticState state) {
    final radios = state.radioInfo?['radios'] as List? ?? [];
    final items = <_InfoItem>[];
    items.add(_infoItem('Band Steering', state.bandSteeringEnabled ? 'Enabled' : 'Disabled'));
    for (final radio in radios) {
      // Prefer 'band' (e.g. "2.4GHz") over 'physicalRadioID' (e.g. "ath0")
      final band = radio['band'] as String? ??
          radio['radioID'] as String? ??
          radio['physicalRadioID'] as String? ?? '?';
      final channelRaw = radio['settings']?['channel'] ?? radio['channel'];
      final channel = (channelRaw == 0 || channelRaw == '0') ? 'Auto' : '$channelRaw';
      final width = radio['settings']?['channelWidth'] ?? radio['channelWidth'] ?? '?';
      final mode = radio['settings']?['mode'] ?? radio['mode'] ?? '?';
      items.add(_infoItem(band, 'Ch $channel ($width) — $mode'));
    }
    return _infoCard(context, 'Radio Configuration', Icons.cell_tower, items);
  }

  Widget _buildBackhaulCard(BuildContext context, CsDiagnosticState state) {
    final nodes = state.backhaulInfo?['backhaulDevices'] as List? ??
        state.backhaulInfo?['nodeBackhaulStatus'] as List? ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();

    final items = <_InfoItem>[];
    for (final node in nodes) {
      final id = node['deviceID'] as String? ?? node['deviceUUID'] as String? ?? 'Node';
      final type = node['connectionType'] as String? ?? 'Unknown';
      final speed = node['speedMbps'] as int?;
      items.add(_infoItem(id.length > 12 ? '${id.substring(0, 12)}...' : id,
          '$type${speed != null ? ' @ $speed Mbps' : ''}'));
    }
    return _infoCard(context, 'Mesh Backhaul', Icons.hub, items);
  }

  Widget _buildAlertBanner(BuildContext context, CsDiagnosticState state) {
    final messages = <String>[];
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 7200) {
      messages.add('Router rebooted recently — check firmware version');
    }
    if (state.dhcpUtilization >= 0.8) {
      messages.add('DHCP pool is ${(state.dhcpUtilization * 100).toInt()}% full');
    }
    if (!state.wanConnected && state.wanStatus != null) {
      messages.add('WAN link is down — ISP or modem issue');
    }
    if (state.flaggedClients.length >= 3) {
      messages.add('${state.flaggedClients.length} devices with poor signal — coverage gap likely');
    }
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: messages.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Expanded(child: Text(m, style: TextStyle(fontSize: 13, color: Colors.red.shade900, fontWeight: FontWeight.w500))),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildComplaintSelector(BuildContext context) {
    final complaints = ['Slow Internet', 'Slow Device', 'Drops', "Can't Connect", 'Dead Spots', 'Offline'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(complaints.length, (i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(complaints[i]),
            selected: _selectedComplaint == i,
            onSelected: (_) => setState(() => _selectedComplaint = i),
          ),
        )),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────

  Widget _infoCard(BuildContext context, String title, IconData icon, List<_InfoItem> items) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                SizedBox(
                  width: 110,
                  child: Text(item.label,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                Expanded(
                  child: Text(item.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  _InfoItem _infoItem(String label, String value) => _InfoItem(label, value);

  String _formatUptime(int seconds) {
    if (seconds <= 0) return 'Unknown';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
