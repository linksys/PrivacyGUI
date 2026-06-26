import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/device_actions.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

/// PRD v0.7 Tab 1: My Devices
///
/// Shows all connected devices with signal quality badges, grouped by mesh node
/// when applicable. Guest devices separated. Tapping a device opens a detail
/// sheet with tailored advice.
class MyDevicesTab extends ConsumerWidget {
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const MyDevicesTab({super.key, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);

    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.clients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No devices found. Run Instant-Test first to discover connected devices.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalCount = state.clients.length;
    final wirelessCount = state.wirelessDeviceCount;
    final wiredCount = state.wiredDeviceCount;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(instantVerifyPivotProvider.notifier).fetch(forceSpeedTest: true),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalCount device${totalCount == 1 ? '' : 's'} connected',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$wirelessCount wireless, $wiredCount wired',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // Re-scan for devices (e.g. a device that joined after the last test)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh devices',
                onPressed: state.phase == PivotLoadPhase.loading
                    ? null
                    : () => ref
                        .read(instantVerifyPivotProvider.notifier)
                        .fetch(forceSpeedTest: true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Device list ─────────────────────────────────────────────
          if (state.isMeshNetwork)
            _MeshGroupedList(state: state, onNavigateToFlow: onNavigateToFlow)
          else
            _FlatDeviceList(state: state, onNavigateToFlow: onNavigateToFlow),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRD signal quality badge — uses PRD v0.7 thresholds, NOT DeviceScore buckets
// ═══════════════════════════════════════════════════════════════════════════

enum _SignalBadge { good, weak, poor, wired }

_SignalBadge _badgeFor(DiagnosticClient client) {
  if (!client.isWireless) return _SignalBadge.wired;
  final signal = client.signalDecibels;
  final rate = client.txRateMbps;

  // Poor: signal < -75 dBm OR data rate < 10 Mbps
  if (signal != null && signal < -75) return _SignalBadge.poor;
  if (rate != null && rate < 10) return _SignalBadge.poor;

  // Weak: signal -70 to -75 dBm OR data rate 10-30 Mbps
  if (signal != null && signal <= -70) return _SignalBadge.weak;
  if (rate != null && rate < 30) return _SignalBadge.weak;

  // Good: signal >= -70 dBm AND data rate >= 30 Mbps
  return _SignalBadge.good;
}

String _badgeLabel(_SignalBadge badge) {
  switch (badge) {
    case _SignalBadge.good:
      return 'Good';
    case _SignalBadge.weak:
      return 'Weak';
    case _SignalBadge.poor:
      return 'Poor';
    case _SignalBadge.wired:
      return 'Wired';
  }
}

Color _badgeColor(_SignalBadge badge, ColorScheme colors) {
  switch (badge) {
    case _SignalBadge.good:
      return Colors.green;
    case _SignalBadge.weak:
      return Colors.orange;
    case _SignalBadge.poor:
      return Colors.red;
    case _SignalBadge.wired:
      return colors.onSurfaceVariant;
  }
}

IconData _deviceIcon(DiagnosticClient client) {
  if (!client.isWireless) return Icons.cable;
  final name = (client.hostname ?? '').toLowerCase();
  final mfr = (client.manufacturer ?? '').toLowerCase();
  if (name.contains('iphone') || name.contains('android') || name.contains('pixel') || name.contains('galaxy')) {
    return Icons.phone_android;
  }
  if (name.contains('ipad') || name.contains('tablet')) return Icons.tablet;
  if (name.contains('tv') || name.contains('roku') || name.contains('shield') || mfr.contains('roku') || mfr.contains('nvidia')) {
    return Icons.tv;
  }
  if (name.contains('echo') || name.contains('nest') || name.contains('sonos') || mfr.contains('sonos') || mfr.contains('amazon')) {
    return Icons.speaker;
  }
  if (name.contains('macbook') || name.contains('laptop') || name.contains('surface')) {
    return Icons.laptop;
  }
  if (name.contains('desktop') || name.contains('pc') || mfr.contains('dell') || mfr.contains('hp')) {
    return Icons.computer;
  }
  if (mfr.contains('espressif') || mfr.contains('tuya') || mfr.contains('wyze')) {
    return Icons.sensors;
  }
  if (mfr.contains('nintendo') || mfr.contains('sony/ps') || mfr.contains('xbox')) {
    return Icons.sports_esports;
  }
  return Icons.devices;
}

// ═══════════════════════════════════════════════════════════════════════════
// Sort order: Issues (Poor → Weak) first, then alphabetical within each tier
// ═══════════════════════════════════════════════════════════════════════════

int _sortOrder(_SignalBadge badge) {
  switch (badge) {
    case _SignalBadge.poor:
      return 0;
    case _SignalBadge.weak:
      return 1;
    case _SignalBadge.good:
      return 2;
    case _SignalBadge.wired:
      return 3;
  }
}

List<DiagnosticClient> _sorted(List<DiagnosticClient> clients) {
  final sorted = List<DiagnosticClient>.from(clients);
  sorted.sort((a, b) {
    final badgeA = _badgeFor(a);
    final badgeB = _badgeFor(b);
    final cmp = _sortOrder(badgeA).compareTo(_sortOrder(badgeB));
    if (cmp != 0) return cmp;
    return a.displayNameWithOui
        .toLowerCase()
        .compareTo(b.displayNameWithOui.toLowerCase());
  });
  return sorted;
}

// ═══════════════════════════════════════════════════════════════════════════
// Flat list (non-mesh)
// ═══════════════════════════════════════════════════════════════════════════

class _FlatDeviceList extends StatelessWidget {
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _FlatDeviceList({required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted(state.clients);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final client in sorted)
            _DeviceRow(client: client, state: state, onNavigateToFlow: onNavigateToFlow),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mesh-grouped list
// ═══════════════════════════════════════════════════════════════════════════

class _MeshGroupedList extends StatelessWidget {
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _MeshGroupedList({required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    // Identify guests by the router's `isGuest` flag — not by lack of node
    // mapping, which mislabeled mapped guests and un-mapped main clients (Q-08).
    final guestClients = state.clients.where((c) => c.isGuest == true).toList();
    final mainClients = state.clients.where((c) => c.isGuest != true).toList();

    // Group clients by node
    final controller = state.meshNodes.where((n) => n.isController).toList();
    final satellites = state.meshNodes.where((n) => !n.isController).toList();
    final allNodes = [...controller, ...satellites];

    // Bucket main clients by their node; any without a mapping are attributed
    // to the controller so they are never dropped.
    final controllerId =
        controller.isNotEmpty ? controller.first.deviceId : null;
    final byNode = <String, List<DiagnosticClient>>{};
    for (final c in mainClients) {
      final nodeId = state.clientToNodeId[c.macAddress] ?? controllerId;
      if (nodeId == null) continue;
      byNode.putIfAbsent(nodeId, () => []).add(c);
    }

    return Column(
      children: [
        for (int i = 0; i < allNodes.length; i++)
          _NodeGroup(
            node: allNodes[i],
            clients: _sorted(byNode[allNodes[i].deviceId] ?? []),
            // Show the user-assigned node name (was hardcoded, ignoring it).
            label: allNodes[i].name,
            state: state,
            onNavigateToFlow: onNavigateToFlow,
          ),
        if (guestClients.isNotEmpty)
          _NodeGroup(
            node: null,
            clients: _sorted(guestClients),
            label: 'Guest Devices',
            state: state,
            onNavigateToFlow: onNavigateToFlow,
          ),
      ],
    );
  }
}

class _NodeGroup extends StatefulWidget {
  final MeshNodeInfo? node;
  final List<DiagnosticClient> clients;
  final String label;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;

  const _NodeGroup({
    required this.node,
    required this.clients,
    required this.label,
    required this.state,
    this.onNavigateToFlow,
  });

  @override
  State<_NodeGroup> createState() => _NodeGroupState();
}

class _NodeGroupState extends State<_NodeGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true; // always expanded
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clientCount = widget.clients.length;

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$clientCount device${clientCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  if (widget.node?.hasWeakBackhaul == true) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (widget.clients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No devices connected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              )
            else
              for (final client in widget.clients)
                _DeviceRow(client: client, state: widget.state, onNavigateToFlow: widget.onNavigateToFlow),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Device row
// ═══════════════════════════════════════════════════════════════════════════

class _DeviceRow extends StatelessWidget {
  final DiagnosticClient client;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _DeviceRow({required this.client, required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(client);
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showDeviceDetail(context, client, state, onNavigateToFlow: onNavigateToFlow),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(_deviceIcon(client), size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: client.hostname == null && client.manufacturer != null
                  ? Tooltip(
                      message: 'Name from device hardware ID — many smart home brands show unfamiliar names',
                      child: Text(
                        client.displayNameWithOui,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : Text(
                      client.displayNameWithOui,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
            ),
            const SizedBox(width: 4),
            if (client.isWireless)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  client.band,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _badgeColor(badge, colors).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _badgeLabel(badge),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _badgeColor(badge, colors),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (badge == _SignalBadge.poor || badge == _SignalBadge.weak)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.warning_amber, size: 14, color: _badgeColor(badge, colors)),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Device detail bottom sheet
// ═══════════════════════════════════════════════════════════════════════════

void _showDeviceDetail(
  BuildContext context,
  DiagnosticClient client,
  InstantVerifyPivotState state, {
  void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SelectionArea(
      child: _DeviceDetailSheet(
        client: client,
        state: state,
        onNavigateToFlow: onNavigateToFlow,
      ),
    ),
  );
}

class _DeviceDetailSheet extends ConsumerStatefulWidget {
  final DiagnosticClient client;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _DeviceDetailSheet({required this.client, required this.state, this.onNavigateToFlow});

  @override
  ConsumerState<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends ConsumerState<_DeviceDetailSheet> {
  bool _isDisconnecting = false;
  bool _isChangingChannel = false;

  DiagnosticClient get client => widget.client;
  InstantVerifyPivotState get state => widget.state;
  void Function(int flow, {DiagnosticClient? device})? get onNavigateToFlow => widget.onNavigateToFlow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badge = _badgeFor(client);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device name + icon
            Row(
              children: [
                Icon(_deviceIcon(client), size: 32, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    client.displayNameWithOui,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connection info
            _connectionInfo(context),
            const SizedBox(height: 16),

            // IP + MAC (selectable for copy)
            _deviceMeta(context, colors),
            const SizedBox(height: 16),

            // Signal quality bar (wireless only)
            if (client.isWireless) ...[
              _signalBar(context, badge, colors),
              const SizedBox(height: 16),
            ],

            // Advice
            _advice(context, badge),
            const SizedBox(height: 16),

            // Actions
            _actions(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _connectionInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!client.isWireless) {
      return Row(
        children: [
          Icon(Icons.cable, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connected by Ethernet cable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      );
    }

    // Determine which node this device is connected to
    final nodeId = state.clientToNodeId[client.macAddress];
    String connectionLabel;
    if (nodeId != null && state.meshNodes.isNotEmpty) {
      final node = state.meshNodes
          .cast<MeshNodeInfo?>()
          .firstWhere((n) => n!.deviceId == nodeId, orElse: () => null);
      if (node != null) {
        if (node.isController) {
          connectionLabel = 'Connected to router on ${client.band}';
        } else {
          final satellites = state.meshNodes.where((n) => !n.isController).toList();
          final idx = satellites.indexOf(node) + 1;
          connectionLabel = 'Connected to Child Node $idx on ${client.band}';
        }
      } else {
        connectionLabel = 'Connected on ${client.band}';
      }
    } else {
      connectionLabel = 'Connected on ${client.band}';
    }

    return Row(
      children: [
        Icon(Icons.wifi, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            connectionLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _signalBar(BuildContext context, _SignalBadge badge, ColorScheme colors) {
    final color = _badgeColor(badge, colors);
    final fraction = badge == _SignalBadge.good
        ? 1.0
        : badge == _SignalBadge.weak
            ? 0.55
            : 0.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Signal: ${_badgeLabel(badge)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _advice(BuildContext context, _SignalBadge badge) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    if (!client.isWireless) {
      // Wired device advice — PRD spec: checklist + restart option
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('If this device has connection issues:',
              style: textStyle?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _checklistItem(context, 'Check that the Ethernet cable is firmly plugged in at both ends'),
          _checklistItem(context, 'Try a different cable if available'),
          _checklistItem(context, 'Try a different port on your router'),
        ],
      );
    }

    switch (badge) {
      case _SignalBadge.poor:
        return Text(
          'Move this device closer to your router, or move your router to a more central location.',
          style: textStyle,
        );
      case _SignalBadge.weak:
        if (client.band.contains('2.4')) {
          return Text(
            'Connect to the 5 GHz network for faster speeds — it has the same name and password.',
            style: textStyle,
          );
        }
        final rate = client.txRateMbps;
        if (rate != null && rate < 30 && (client.signalDecibels ?? -90) >= -70) {
          return Text(
            'Thick walls, metal objects, or appliances may be blocking the signal between this device and your router.',
            style: textStyle,
          );
        }
        return Text(
          'Move this device closer to your router, or move your router to a more central location.',
          style: textStyle,
        );
      case _SignalBadge.good:
        return Text(
          'This device has a strong WiFi connection.',
          style: textStyle,
        );
      case _SignalBadge.wired:
        return const SizedBox.shrink(); // handled above
    }
  }

  Widget _deviceMeta(BuildContext context, ColorScheme colors) {
    final rows = <Widget>[];
    if (client.ipAddress != null) {
      rows.add(_metaRow(context, colors, 'IP', client.ipAddress!));
    }
    rows.add(_metaRow(context, colors, 'MAC', client.macAddress));
    final leaseMin = widget.state.dhcpLeaseMinutes;
    if (leaseMin != null && leaseMin > 0) {
      final hours = (leaseMin / 60).ceil();
      rows.add(_metaRow(context, colors, 'Connected',
          'Within the last ${hours == 1 ? "hour" : "$hours hours"}'));
    } else {
      rows.add(_metaRow(context, colors, 'Status', 'Connected now'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: rows),
    );
  }

  Widget _metaRow(BuildContext context, ColorScheme colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme colors) {
    final badge = _badgeFor(client);
    final isWeak = badge == _SignalBadge.poor || badge == _SignalBadge.weak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Troubleshoot
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            if (onNavigateToFlow != null) {
              onNavigateToFlow!(30, device: client); // 30 = Flow 3 pre-connected
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Help Me Fix It → Device connectivity issues'),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.build_outlined, size: 18),
          label: const Text('Troubleshoot this device'),
        ),

        // Disconnect/Reconnect — useful for weak signal devices and all wireless
        if (client.isWireless) ...[
          const SizedBox(height: 8),
          _isDisconnecting
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  label: const Text('Disconnecting…'),
                )
              : OutlinedButton.icon(
                  onPressed: () => _disconnectDevice(context),
                  icon: const Icon(Icons.wifi_off_outlined, size: 18),
                  label: const Text('Disconnect and reconnect this device'),
                ),
          if (isWeak)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reconnecting forces the device to re-select its WiFi connection, '
                'which can improve a weak signal.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant),
              ),
            ),
        ],

        // Channel change — shown when channel data is available and signal is weak
        if (isWeak && state.channelInfo != null) ...[
          const SizedBox(height: 8),
          _isChangingChannel
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  label: const Text('Changing channel…'),
                )
              : OutlinedButton.icon(
                  onPressed: () => _triggerChannelRescan(context),
                  icon: const Icon(Icons.wifi_tethering, size: 18),
                  label: const Text('Try a cleaner WiFi channel'),
                ),
        ],
      ],
    );
  }

  Future<void> _disconnectDevice(BuildContext context) async {
    await confirmAndDeauth(
      context,
      ref,
      mac: client.macAddress,
      displayName: client.displayNameWithOui,
      onProgress: (busy) {
        if (mounted) setState(() => _isDisconnecting = busy);
      },
    );
  }

  Future<void> _triggerChannelRescan(BuildContext context) async {
    // Real firmware RF scan picks the clearest channels (not a hardcoded 6/36).
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optimize WiFi channels?'),
        content: const Text(
            'Your router will scan for the clearest WiFi channels and switch '
            'automatically. This takes about a minute, and devices may briefly '
            'disconnect and reconnect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Optimize'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isChangingChannel = true);
    final result = await ref
        .read(instantVerifyPivotProvider.notifier)
        .optimizeChannels();
    if (!mounted) return;
    setState(() => _isChangingChannel = false);
    final msg = switch (result.status) {
      ChannelOptimizeStatus.optimized =>
        'WiFi channels optimized. Devices will reconnect in a moment.',
      ChannelOptimizeStatus.alreadyOptimal =>
        'Your WiFi is already on the clearest channels.',
      ChannelOptimizeStatus.error =>
        'Couldn\'t optimize right now — please try again in a moment.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _checklistItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Non-interactive bullet. Was Icons.check_box_outline_blank, which
          // looked like a tappable checkbox but had no handler (J-09).
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
