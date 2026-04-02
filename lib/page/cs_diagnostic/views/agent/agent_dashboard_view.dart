import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/flow_analysis_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/health_bar_widget.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/report_summary_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/signal_table_view.dart';

class AgentDashboardView extends ConsumerStatefulWidget {
  const AgentDashboardView({super.key});

  @override
  ConsumerState<AgentDashboardView> createState() => _AgentDashboardViewState();
}

class _AgentDashboardViewState extends ConsumerState<AgentDashboardView> {
  int _selectedComplaint = 0;
  Timer? _autoRefreshTimer;
  int _autoRefreshSeconds = 0; // 0 = off

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(csDiagnosticProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _setAutoRefresh(int seconds) {
    _autoRefreshTimer?.cancel();
    setState(() => _autoRefreshSeconds = seconds);
    if (seconds > 0) {
      _autoRefreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
        ref.read(csDiagnosticProvider.notifier).fetch();
      });
    }
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
            PopupMenuButton<int>(
              icon: Icon(
                Icons.refresh,
                color: _autoRefreshSeconds > 0
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: _autoRefreshSeconds > 0
                  ? 'Auto-refresh: ${_autoRefreshSeconds}s'
                  : 'Refresh',
              onSelected: (value) {
                if (value == -1) {
                  ref.read(csDiagnosticProvider.notifier).fetch();
                } else {
                  _setAutoRefresh(value);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: -1, child: Text('Refresh now')),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 0,
                  child: Row(children: [
                    if (_autoRefreshSeconds == 0)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('Auto-refresh off'),
                  ]),
                ),
                for (final secs in [15, 30, 60])
                  PopupMenuItem(
                    value: secs,
                    child: Row(children: [
                      if (_autoRefreshSeconds == secs)
                        const Icon(Icons.check, size: 16)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text('Every ${secs}s'),
                    ]),
                  ),
              ],
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
          Icon(Icons.error_outline, size: 48,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Spacing.medium),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.large3),
            child: Text(state.errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: Spacing.medium),
          ElevatedButton(
            onPressed: () => ref.read(csDiagnosticProvider.notifier).fetch(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CsDiagnosticState state) {
    final isDesktop = ResponsiveLayout.isDesktopLayout(context);

    return SelectionArea(
      child: Column(
        children: [
          HealthBarWidget(state: state),
          if (_hasAlerts(state)) _buildAlertBanner(context, state),
          _buildComplaintSelector(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.medium),
              child: isDesktop
                  ? _buildDesktopLayout(context, state)
                  : _buildMobileLayout(context, state),
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop: two-column layout ──────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, CsDiagnosticState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Flow analysis + signal table
        Expanded(
          flex: 7,
          child: Column(
            children: [
              FlowAnalysisView(
                complaintIndex: _selectedComplaint,
                state: state,
              ),
              const SizedBox(height: Spacing.medium),
              _buildDevicesCard(context, state),
            ],
          ),
        ),
        const SizedBox(width: Spacing.medium),
        // Right: Info panels
        Expanded(
          flex: 5,
          child: Column(
            children: _buildInfoPanels(context, state),
          ),
        ),
      ],
    );
  }

  // ── Mobile: single-column layout ────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, CsDiagnosticState state) {
    return Column(
      children: [
        FlowAnalysisView(
          complaintIndex: _selectedComplaint,
          state: state,
        ),
        const SizedBox(height: Spacing.medium),
        ..._buildInfoPanels(context, state),
        const SizedBox(height: Spacing.medium),
        _buildDevicesCard(context, state),
      ],
    );
  }

  // ── Info panels (right column on desktop, below on mobile) ──────────

  List<Widget> _buildInfoPanels(BuildContext context, CsDiagnosticState state) {
    return [
      _buildSpeedTestCard(context, state),
      const SizedBox(height: Spacing.medium),
      _buildNetworkOverviewCard(context, state),
      const SizedBox(height: Spacing.medium),
      if (state.radioInfo != null) ...[
        _buildRadioConfigCard(context, state),
        const SizedBox(height: Spacing.medium),
      ],
      _buildRouterStabilityCard(context, state),
      const SizedBox(height: Spacing.medium),
      _buildConnectionCapacityCard(context, state),
      if (state.firmwareUpdateAvailable) ...[
        const SizedBox(height: Spacing.medium),
        _buildFirmwareCard(context, state),
      ],
      if (state.backhaulInfo != null) ...[
        const SizedBox(height: Spacing.medium),
        _buildBackhaulCard(context, state),
      ],
    ];
  }

  // ── Connected Devices card ──────────────────────────────────────────

  Widget _buildDevicesCard(BuildContext context, CsDiagnosticState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.devices, 'Connected Devices'),
          const SizedBox(height: Spacing.medium),
          SignalTableView(clients: state.clients),
        ],
      ),
    );
  }

  // ── Speed Test ──────────────────────────────────────────────────────

  Widget _buildSpeedTestCard(BuildContext context, CsDiagnosticState state) {
    final step = state.speedTestStep;
    final isRunning = state.isSpeedTestRunning;
    final isComplete = step == 'complete';
    final isError = step == 'error';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader(context, Icons.speed, 'Speed Test'),
              const Spacer(),
              if (isRunning)
                TextButton.icon(
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Stop', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => ref.read(csDiagnosticProvider.notifier).stopSpeedTest(),
                )
              else
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    icon: Icon(isComplete ? Icons.refresh : Icons.play_arrow, size: 16),
                    label: Text(isComplete ? 'Retest' : 'Run', style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => ref.read(csDiagnosticProvider.notifier).runSpeedTest(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.medium),
          if (step == 'idle')
            Text('Tap Run to measure WAN speed via router.',
                style: TextStyle(fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (isRunning) ...[
            _speedTestProgress(context, step),
            const SizedBox(height: 8),
            if (state.speedTestLatencyMs != null)
              _kvRow(context, 'Latency', '${state.speedTestLatencyMs} ms'),
            if (state.speedTestDownloadKbps != null)
              _kvRow(context, 'Download',
                  '${state.speedTestDownloadMbps!.toStringAsFixed(1)} Mbps'),
            if (state.speedTestUploadKbps != null)
              _kvRow(context, 'Upload',
                  '${state.speedTestUploadMbps!.toStringAsFixed(1)} Mbps'),
          ],
          if (isComplete) ...[
            _kvRow(context, 'Latency',
                state.speedTestLatencyMs != null ? '${state.speedTestLatencyMs} ms' : '—'),
            _kvRow(context, 'Download',
                state.speedTestDownloadMbps != null
                    ? '${state.speedTestDownloadMbps!.toStringAsFixed(1)} Mbps'
                    : '—',
                valueColor: _speedColor(context, state.speedTestDownloadMbps)),
            _kvRow(context, 'Upload',
                state.speedTestUploadMbps != null
                    ? '${state.speedTestUploadMbps!.toStringAsFixed(1)} Mbps'
                    : '—',
                valueColor: _speedColor(context, state.speedTestUploadMbps)),
          ],
          if (isError)
            _kvRow(context, 'Error', state.speedTestError ?? 'Unknown error',
                valueColor: Theme.of(context).colorScheme.error),
        ],
      ),
    );
  }

  Widget _speedTestProgress(BuildContext context, String step) {
    final progress = switch (step) {
      'latency' => 0.15,
      'download' => 0.5,
      'upload' => 0.85,
      _ => 0.0,
    };
    final label = switch (step) {
      'latency' => 'Testing latency...',
      'download' => 'Testing download...',
      'upload' => 'Testing upload...',
      _ => 'Starting...',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ],
    );
  }

  Color? _speedColor(BuildContext context, double? mbps) {
    if (mbps == null) return null;
    if (mbps >= 50) return _successColor(context);
    if (mbps >= 25) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  // ── Network Overview ────────────────────────────────────────────────

  Widget _buildNetworkOverviewCard(BuildContext context, CsDiagnosticState state) {
    final wanConn = state.wanStatus?['wanConnection'] as Map<String, dynamic>?;
    final wanIp = wanConn?['ipAddress'] as String? ??
        state.wanStatus?['wanIPAddress'] as String?;
    final on24 = state.clients.where((c) => c.band == '2.4GHz').length;
    final on5 = state.clients.where((c) => c.band == '5GHz').length;
    final on6 = state.clients.where((c) => c.band == '6GHz').length;
    final wired = state.clients.where((c) => !c.isWireless).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.lan, 'Network Overview'),
          const SizedBox(height: Spacing.medium),
          _kvRow(context, 'WAN Status', state.wanConnected ? 'Connected' : 'Disconnected',
              valueColor: state.wanConnected
                  ? _successColor(context)
                  : Theme.of(context).colorScheme.error),
          if (wanIp != null) _kvRow(context, 'WAN IP', wanIp),
          _kvRow(context, 'Total Devices', '${state.clients.length}'),
          _kvRow(context, 'Band Split',
              '2.4G: $on24  |  5G: $on5${on6 > 0 ? '  |  6G: $on6' : ''}  |  Wired: $wired'),
        ],
      ),
    );
  }

  // ── Radio Configuration ─────────────────────────────────────────────

  Widget _buildRadioConfigCard(BuildContext context, CsDiagnosticState state) {
    final radios = state.radioInfo?['radios'] as List? ?? [];
    final selectedChannels = state.channelInfo?['selectedChannels'] as List? ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.cell_tower, 'Radio Configuration'),
          const SizedBox(height: Spacing.medium),
          _kvRow(context, 'Band Steering',
              state.bandSteeringEnabled ? 'Enabled' : 'Disabled'),
          for (final radio in radios) _buildRadioRow(context, radio, selectedChannels),
        ],
      ),
    );
  }

  Widget _buildRadioRow(BuildContext context, dynamic radio, List selectedChannels) {
    final band = radio['band'] as String? ??
        radio['radioID'] as String? ??
        radio['physicalRadioID'] as String? ?? '?';
    final channelRaw = radio['settings']?['channel'] ?? radio['channel'];
    final isAuto = channelRaw == 0 || channelRaw == '0';
    final width = radio['settings']?['channelWidth'] ?? radio['channelWidth'] ?? '?';
    final mode = radio['settings']?['mode'] ?? radio['mode'] ?? '?';

    String channelDisplay;
    if (isAuto) {
      // Try to find actual selected channel from GetSelectedChannels
      final radioId = radio['radioID'] as String? ?? '';
      final actual = selectedChannels.isEmpty ? null :
          selectedChannels.cast<Map<String, dynamic>?>().firstWhere(
            (ch) => ch?['radioID'] == radioId,
            orElse: () => null,
          );
      final actualCh = actual?['channel'];
      channelDisplay = actualCh != null && actualCh != 0 ? 'Auto (ch $actualCh)' : 'Auto';
    } else {
      channelDisplay = 'Ch $channelRaw';
    }
    final widthDisplay = width == 'Auto' ? '' : ' ($width)';
    return _kvRow(context, band, '$channelDisplay$widthDisplay — $mode');
  }

  // ── Router Stability ────────────────────────────────────────────────

  Widget _buildRouterStabilityCard(BuildContext context, CsDiagnosticState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.monitor_heart, 'Router Stability'),
          const SizedBox(height: Spacing.medium),
          _kvRow(context, 'Uptime', _formatUptime(state.routerUptimeSeconds)),
          if (state.routerHealth?['cpuLoad'] != null)
            _kvRow(context, 'CPU Load', '${state.routerHealth!['cpuLoad']}%'),
          if (state.routerHealth?['memoryLoad'] != null)
            _kvRow(context, 'Memory', '${state.routerHealth!['memoryLoad']}%'),
          _kvRow(context, 'Firmware', state.deviceInfo?['firmwareVersion'] ?? 'Unknown'),
        ],
      ),
    );
  }

  // ── Connection Capacity ─────────────────────────────────────────────

  Widget _buildConnectionCapacityCard(BuildContext context, CsDiagnosticState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.settings_ethernet, 'Connection Capacity'),
          const SizedBox(height: Spacing.medium),
          _kvRow(context, 'DHCP',
              '${state.dhcpLeasesCount}/${state.dhcpPoolLimit} (${(state.dhcpUtilization * 100).toInt()}%)',
              valueColor: state.dhcpUtilization >= 0.8
                  ? Theme.of(context).colorScheme.error
                  : null),
          _kvRow(context, 'Connected', '${state.clients.length} devices'),
          _kvRow(context, 'Guest Network',
              state.guestNetworkEnabled ? 'Enabled' : 'Disabled'),
        ],
      ),
    );
  }

  // ── Firmware Update ─────────────────────────────────────────────────

  Widget _buildFirmwareCard(BuildContext context, CsDiagnosticState state) {
    return AppCard(
      borderColor: Theme.of(context).colorScheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.system_update, 'Firmware Update Available'),
          const SizedBox(height: Spacing.medium),
          _kvRow(context, 'Current', state.deviceInfo?['firmwareVersion'] ?? 'Unknown'),
          _kvRow(context, 'Available', state.availableFirmwareVersion ?? 'Unknown'),
        ],
      ),
    );
  }

  // ── Mesh Backhaul ───────────────────────────────────────────────────

  Widget _buildBackhaulCard(BuildContext context, CsDiagnosticState state) {
    final nodes = state.backhaulInfo?['backhaulDevices'] as List? ??
        state.backhaulInfo?['nodeBackhaulStatus'] as List? ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, Icons.hub, 'Mesh Backhaul'),
          const SizedBox(height: Spacing.medium),
          for (final node in nodes)
            _buildBackhaulRow(context, node),
        ],
      ),
    );
  }

  Widget _buildBackhaulRow(BuildContext context, dynamic node) {
    final id = node['deviceID'] as String? ?? node['deviceUUID'] as String? ?? 'Node';
    final type = node['connectionType'] as String? ?? 'Unknown';
    final speed = node['speedMbps'] as int?;
    return _kvRow(context,
        id.length > 12 ? '${id.substring(0, 12)}...' : id,
        '$type${speed != null ? ' @ $speed Mbps' : ''}');
  }

  // ── Alert Banner ────────────────────────────────────────────────────

  bool _hasAlerts(CsDiagnosticState state) {
    return state.flaggedClients.isNotEmpty ||
        !state.wanConnected ||
        (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 7200) ||
        state.dhcpUtilization >= 0.8;
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
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.medium, vertical: Spacing.medium / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: Border(bottom: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        )),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: messages.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.warning_amber, size: 16,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 6),
            Expanded(child: Text(m, style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ))),
          ]),
        )).toList(),
      ),
    );
  }

  // ── Complaint Selector Chips ────────────────────────────────────────

  Widget _buildComplaintSelector(BuildContext context) {
    final complaints = [
      'Slow Internet',
      'Slow Device',
      'Drops',
      "Can't Connect",
      'Dead Spots',
      'Offline',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.medium, vertical: Spacing.medium / 2),
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

  // ── Shared Helpers ──────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _kvRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ),
          Expanded(
            child: Text(value, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            )),
          ),
        ],
      ),
    );
  }

  Color _successColor(BuildContext context) {
    // Use theme green if available, fall back to Material green
    try {
      return (Theme.of(context).extension<_GreenColor>()?.color) ?? Colors.green;
    } catch (_) {
      return Colors.green;
    }
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return 'Unknown';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}

// Placeholder extension for green color — avoids hard dependency on ColorSchemeExt
class _GreenColor extends ThemeExtension<_GreenColor> {
  final Color color;
  const _GreenColor(this.color);

  @override
  ThemeExtension<_GreenColor> copyWith({Color? color}) =>
      _GreenColor(color ?? this.color);

  @override
  ThemeExtension<_GreenColor> lerp(covariant ThemeExtension<_GreenColor>? other, double t) {
    if (other is! _GreenColor) return this;
    return _GreenColor(Color.lerp(color, other.color, t)!);
  }
}
