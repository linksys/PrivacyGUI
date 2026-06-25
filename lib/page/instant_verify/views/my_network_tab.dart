import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/restart_helper.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

/// PRD v0.7 Tab 2: My Network
///
/// 5 sections: Internet Connection, Your Router, Satellite Nodes (mesh only),
/// WiFi Overview, Guest Network.
class MyNetworkTab extends ConsumerWidget {
  const MyNetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);

    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(instantVerifyPivotProvider.notifier).fetch(forceSpeedTest: true),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your Network',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: state.phase == PivotLoadPhase.loading
                    ? null
                    : () => ref
                        .read(instantVerifyPivotProvider.notifier)
                        .fetch(forceSpeedTest: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InternetConnectionCard(state: state, ref: ref),
          const SizedBox(height: 12),
          _YourRouterCard(state: state, ref: ref),
          if (state.isMeshNetwork) ...[
            const SizedBox(height: 12),
            _SatelliteNodesSection(state: state),
          ],
          const SizedBox(height: 12),
          _WifiOverviewCard(state: state),
          // Only show guest network card when it's enabled — not a config screen
          if (state.guestNetwork != null &&
              state.guestNetwork!['isGuestNetworkEnabled'] == true) ...[
            const SizedBox(height: 12),
            _GuestNetworkCard(state: state, ref: ref),
          ],
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 1: Internet Connection
// ═══════════════════════════════════════════════════════════════════════════

class _InternetConnectionCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final WidgetRef ref;
  const _InternetConnectionCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final connected = state.wanConnected;
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.cloud_done : Icons.cloud_off,
                  color: connected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Internet Connection',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(context, 'Status',
                connected ? 'Connected' : 'Not Connected',
                valueColor: connected ? Colors.green : Colors.red),
            if (state.wanConnectionType != null)
              _infoRow(context, 'Type', state.wanConnectionType!),
            if (connected && state.wanIpAddress != null)
              _infoRow(context, 'IP Address', state.wanIpAddress!),
            if (!connected && !state.hasRestartedThisSession) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => confirmAndRestart(context, ref),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart Router'),
                ),
              ),
            ],
            if (!connected && state.hasRestartedThisSession) ...[
              const SizedBox(height: 12),
              Text(
                'You already restarted — if it\'s still disconnected, contact Linksys Support.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════
// Section 2: Your Router
// ═══════════════════════════════════════════════════════════════════════════

class _YourRouterCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final WidgetRef ref;
  const _YourRouterCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final uptimeDays = state.uptimeSeconds ~/ 86400;
    final showUptime = uptimeDays >= 30;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  // Show the controller's custom name when available.
                  state.meshNodes.any((n) => n.isController)
                      ? state.meshNodes.firstWhere((n) => n.isController).name
                      : 'Your Router',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.routerModel != null)
              _infoRow(context, 'Model', state.routerModel!),
            _infoRow(
              context,
              'Firmware',
              state.firmwareUpdateAvailable
                  ? 'Update available'
                  : 'Up to date',
              valueColor:
                  state.firmwareUpdateAvailable ? Colors.orange : Colors.green,
            ),
            if (state.firmwareUpdateAvailable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(instantVerifyPivotProvider.notifier).triggerFirmwareUpdate();
                  },
                  icon: const Icon(Icons.system_update),
                  label: const Text('Update Now'),
                ),
              ),
            ],
            if (showUptime) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Running for $uptimeDays days — a restart may help',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (!state.hasRestartedThisSession) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => confirmAndRestart(context, ref),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart Router'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 3: Satellite Nodes (mesh only)
// ═══════════════════════════════════════════════════════════════════════════

class _SatelliteNodesSection extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _SatelliteNodesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final satellites = state.meshNodes.where((n) => !n.isController).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Your Child Nodes',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        for (int i = 0; i < satellites.length; i++)
          _SatelliteNodeCard(
            node: satellites[i],
            index: i + 1,
            deviceCount: state.clientCountForNode(satellites[i].deviceId),
          ),
      ],
    );
  }
}

class _SatelliteNodeCard extends StatelessWidget {
  final MeshNodeInfo node;
  final int index;
  final int deviceCount;
  const _SatelliteNodeCard({
    required this.node,
    required this.index,
    required this.deviceCount,
  });

  @override
  Widget build(BuildContext context) {
    final isWeak = node.hasWeakBackhaul;
    final isWired = node.hasWiredBackhaul;
    // A node with backhaul telemetry is provably reachable; otherwise trust the
    // online flag derived from GetDevices3 `connections`.
    final isOnline = node.isOnline || node.hasBackhaulData;

    final speedSuffix = node.backhaulSpeedMbps != null ? ' (${node.backhaulSpeedMbps} Mbps)' : '';
    String backhaulLabel;
    Color? backhaulColor;
    if (!isOnline) {
      backhaulLabel = 'Offline — not responding';
      backhaulColor = Colors.red;
    } else if (isWired) {
      backhaulLabel = 'Connected by Ethernet$speedSuffix';
    } else if (isWeak) {
      backhaulLabel = 'Connected wirelessly — Weak$speedSuffix';
      backhaulColor = Colors.orange;
    } else if (node.hasBackhaulData) {
      backhaulLabel = 'Connected wirelessly — Good$speedSuffix';
      backhaulColor = Colors.green;
    } else {
      // Online but no backhaul health data — don't assert "Good".
      backhaulLabel = 'Connected wirelessly';
    }

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: !isOnline
                      ? Colors.red
                      : isWeak
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Show the node's custom name (was hardcoded "Child Node N").
                    node.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!isOnline)
                  const Icon(Icons.error_outline, color: Colors.red, size: 18)
                else if (isWeak)
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              backhaulLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: backhaulColor,
                  ),
            ),
            Text(
              '$deviceCount device${deviceCount == 1 ? '' : 's'} connected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (isWeak) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This node has a weak connection to your router. Move it closer or connect it with an Ethernet cable.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 4: WiFi Overview
// ═══════════════════════════════════════════════════════════════════════════

class _WifiOverviewCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _WifiOverviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final count24 = state.twoPointFourGhzCount;
    final count5 = state.fiveGhzCount;
    final wirelessTotal = state.wirelessDeviceCount;
    final isOvercrowded =
        wirelessTotal >= 4 && count24 > 0 && (count24 / wirelessTotal) >= 0.6;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'WiFi Overview',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bandRow(context, '$count24 device${count24 == 1 ? '' : 's'} on 2.4 GHz',
                'slower, longer range'),
            const SizedBox(height: 4),
            _bandRow(context, '$count5 device${count5 == 1 ? '' : 's'} on 5 GHz',
                'faster, shorter range'),
            if (isOvercrowded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Many of your devices are on the slower 2.4 GHz band. '
                  'Connect fast devices like phones and laptops to the '
                  '5 GHz network for better speeds.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bandRow(BuildContext context, String label, String hint) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          '($hint)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 5: Guest Network
// ═══════════════════════════════════════════════════════════════════════════

class _GuestNetworkCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final WidgetRef ref;
  const _GuestNetworkCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final guestEnabled = _isGuestEnabled();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guest Network',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: guestEnabled,
                  onChanged: (value) {
                    if (!value) {
                      _showDisableConfirmation(context);
                    } else {
                      ref.read(instantVerifyPivotProvider.notifier).setGuestNetworkEnabled(true);
                    }
                  },
                ),
              ],
            ),
            if (guestEnabled) ...[
              const SizedBox(height: 4),
              Text(
                '${_guestDeviceCount()} guest device${_guestDeviceCount() == 1 ? '' : 's'} connected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isGuestEnabled() {
    if (state.guestNetwork == null) return false;
    return state.guestNetwork!['isGuestNetworkEnabled'] == true;
  }

  int _guestDeviceCount() {
    // Guest device count — clients not mapped to any node in mesh,
    // or reported by guest network JNAP response
    if (state.guestNetwork == null) return 0;
    final count = state.guestNetwork!['guestDeviceCount'] as int?;
    if (count != null) return count;
    // Fallback: count unmapped clients in mesh mode
    if (state.isMeshNetwork) {
      final mapped = state.clientToNodeId.keys.toSet();
      return state.clients.where((c) => !mapped.contains(c.macAddress)).length;
    }
    return 0;
  }

  void _showDisableConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off guest network?'),
        content: const Text('This will disconnect your guests. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _disableGuestNetwork();
            },
            child: const Text('Turn Off'),
          ),
        ],
      ),
    );
  }

  void _disableGuestNetwork() {
    ref.read(instantVerifyPivotProvider.notifier).setGuestNetworkEnabled(false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared helper
// ═══════════════════════════════════════════════════════════════════════════

Widget _infoRow(BuildContext context, String label, String value,
    {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.w600 : null,
                ),
          ),
        ),
      ],
    ),
  );
}
