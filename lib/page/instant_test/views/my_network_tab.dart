import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/topology/cards/usp_network_topology_card.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

class MyNetworkTab extends ConsumerWidget {
  const MyNetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantTestProvider);
    final wan = state.wanStatus;
    final childNodes =
        state.meshNodes.where((n) => !n.isMaster).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── WAN status ────────────────────────────────────────────────────
          Text(loc(context).instantTestInternetSection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.public,
                color: (wan?.isUp == true) ? Colors.green : Colors.red,
              ),
              title: Text(loc(context).instantTestInternetSection),
              subtitle: Text(wan?.isUp == true
                  ? 'Connected · ${wan?.ipAddress ?? ''}'
                  : 'Not connected'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Topology card ─────────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: const UspNetworkTopologyCard(),
          ),

          // ── Backhaul health section ───────────────────────────────────────
          if (childNodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(loc(context).instantTestBackhaulHealthSection,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final node in state.meshNodes)
              _NodeHealthRow(node: node),
          ],

          // ── Ethernet ports ────────────────────────────────────────────────
          if (state.ethernetPorts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(loc(context).instantTestEthernetSection,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final port in state.ethernetPorts)
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.settings_ethernet,
                  color: port.isUp ? Colors.green : Colors.grey,
                ),
                title:
                    Text(port.label.isNotEmpty ? port.label : port.name),
                subtitle: port.isUp && port.currentBitRate > 0
                    ? Text(
                        '${(port.currentBitRate / 1000000).toStringAsFixed(0)} Mbps')
                    : Text(port.isUp ? 'Up' : 'No link'),
              ),
          ],

          // ── Speed legs summary ────────────────────────────────────────────
          _SpeedLegsCard(state: ref.watch(instantTestProvider)),
        ],
      ),
    );
  }
}

class _NodeHealthRow extends StatelessWidget {
  final NodeUIModel node;

  const _NodeHealthRow({required this.node});

  @override
  Widget build(BuildContext context) {
    final signal = node.backhaulSignalStrength;
    final isWeak = !node.isMaster &&
        signal != null &&
        signal < -70;
    final isWired = node.backhaulMediaType.toLowerCase().contains('ethernet');

    Color indicatorColor;
    String subtitle;
    if (node.isMaster) {
      indicatorColor = Colors.green;
      subtitle = 'Gateway';
    } else if (isWired) {
      indicatorColor = Colors.green;
      subtitle = loc(context).instantTestNodeConnectedWired;
    } else if (isWeak) {
      indicatorColor = Colors.orange;
      // isWeak guarantees signal != null
      subtitle = '${loc(context).instantTestNodeConnectedWeak} ($signal dBm)';
    } else {
      indicatorColor = Colors.green;
      subtitle = loc(context).instantTestNodeConnectedStrong +
          (signal != null ? ' ($signal dBm)' : '');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.router, color: indicatorColor),
        title: Text(node.displayName),
        subtitle: Text(subtitle),
        trailing: node.isMaster
            ? const Chip(label: Text('Main'))
            : null,
      ),
    );
  }
}

/// Shows the three-leg speed summary when data is available.
class _SpeedLegsCard extends StatelessWidget {
  final InstantTestState state;

  const _SpeedLegsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final clientInternet = state.speedTest?.downloadMbps;
    final routerInternet = state.routerInternetResult?.downloadMbps;
    final routerSpeed = state.routerSpeed?.throughputMbps;

    if (clientInternet == null && routerInternet == null && routerSpeed == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(loc(context).instantTestRouterSpeed,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (routerInternet != null)
                  _speedRow(
                    context,
                    loc(context).instantTestRouterSpeedLeg,
                    routerInternet,
                  ),
                if (clientInternet != null)
                  _speedRow(
                    context,
                    loc(context).instantTestClientInternetLeg,
                    clientInternet,
                  ),
                if (routerSpeed != null)
                  _speedRow(
                    context,
                    loc(context).instantTestClientRouterLeg,
                    routerSpeed,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _speedRow(BuildContext context, String label, double mbps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '${mbps.toStringAsFixed(0)} Mbps',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
