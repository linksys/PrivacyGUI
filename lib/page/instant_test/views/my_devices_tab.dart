import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/route/constants.dart';

class MyDevicesTab extends ConsumerWidget {
  const MyDevicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantTestProvider);
    final clients = state.clients;
    final scoreByMac = {
      for (final s in state.deviceScores) s.device.mac: s,
    };

    if (clients.isEmpty) {
      return Center(child: Text(loc(context).instantTestNoDevices));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final device = clients[index];
        final score = scoreByMac[device.mac];
        return _DeviceRow(
          device: device,
          score: score,
          onTap: () => context.goNamed(
            RouteNamed.uspDeviceDetail,
            queryParameters: {'mac': device.mac},
          ),
          onTroubleshoot: score?.bucket == DeviceScoreBucket.issue
              ? () => _showTroubleshootSheet(context, device, score!)
              : null,
        );
      },
    );
  }

  void _showTroubleshootSheet(
      BuildContext context, DeviceUIModel device, DeviceScore score) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _TroubleshootSheet(device: device, score: score),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final DeviceUIModel device;
  final DeviceScore? score;
  final VoidCallback? onTap;
  final VoidCallback? onTroubleshoot;

  const _DeviceRow({
    required this.device,
    required this.score,
    required this.onTap,
    this.onTroubleshoot,
  });

  @override
  Widget build(BuildContext context) {
    final bucket = score?.bucket;
    final badge = _badge(context, bucket);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UspDeviceListTile(
          device: device,
          onTap: onTap,
          variant: DeviceListTileVariant.flat,
        ),
        if (badge != null || onTroubleshoot != null)
          Padding(
            padding: const EdgeInsets.only(left: 72, bottom: 8),
            child: Row(
              children: [
                if (badge != null) badge,
                if (badge != null && onTroubleshoot != null)
                  const SizedBox(width: 8),
                if (onTroubleshoot != null)
                  TextButton.icon(
                    onPressed: onTroubleshoot,
                    icon: const Icon(Icons.build_outlined, size: 16),
                    label: Text(
                      loc(context).instantTestTroubleshootDevice,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget? _badge(BuildContext context, DeviceScoreBucket? bucket) {
    if (bucket == null) return null;
    Color color;
    String label;
    switch (bucket) {
      case DeviceScoreBucket.good:
        color = Colors.green;
        label = loc(context).instantTestScoreGood;
      case DeviceScoreBucket.atRisk:
        color = Colors.orange;
        label = loc(context).instantTestScoreAtRisk;
      case DeviceScoreBucket.issue:
        color = Colors.red;
        label = loc(context).instantTestScoreIssue;
    }
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

/// Bottom sheet with targeted advice for Issue-bucket devices.
class _TroubleshootSheet extends StatelessWidget {
  final DeviceUIModel device;
  final DeviceScore score;

  const _TroubleshootSheet({required this.device, required this.score});

  @override
  Widget build(BuildContext context) {
    final signal = device.signalStrength;
    final rateMbps =
        device.downlinkRate != null ? device.downlinkRate! / 1000000 : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          if (signal != null)
            Text('Signal: $signal dBm',
                style: Theme.of(context).textTheme.bodySmall),
          if (rateMbps != null)
            Text('Speed: ${rateMbps.toStringAsFixed(0)} Mbps',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _adviceText(signal, rateMbps),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed(
                RouteNamed.uspDeviceDetail,
                queryParameters: {'mac': device.mac},
              );
            },
            child: const Text('View Device Details'),
          ),
        ],
      ),
    );
  }

  Widget _adviceText(int? signal, double? rateMbps) {
    if (signal != null && signal < -75) {
      return const Text(
        'This device has a weak signal. Moving it closer to your router or a '
        'mesh node will improve its connection. Walls, metal appliances, and '
        'distance all reduce WiFi signal strength.',
      );
    }
    if (rateMbps != null && rateMbps < 10) {
      return const Text(
        'This device is getting very slow WiFi speeds. Check for interference '
        'between it and your router. Moving it closer or reconnecting to the '
        '5 GHz band often helps.',
      );
    }
    return const Text(
      'This device has a weak WiFi connection. Check for walls or appliances '
      'between the device and your router.',
    );
  }
}
