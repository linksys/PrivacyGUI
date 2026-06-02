import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/views/components/pill_chip.dart';
import 'package:privacy_gui/route/constants.dart';

class MyDevicesTab extends ConsumerWidget {
  /// Called to navigate to Help Me Fix It tab and launch Flow 3 for a device.
  final ValueChanged<DeviceUIModel?>? onGoToFlow3;

  const MyDevicesTab({super.key, this.onGoToFlow3});

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
      builder: (ctx) => _TroubleshootSheet(
        device: device,
        score: score,
        onGoToFlow3: onGoToFlow3,
      ),
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
/// Shows signal/rate context, targeted fix advice, Disconnect (USP pending),
/// and a CTA to Help Me Fix It → Flow 3.
class _TroubleshootSheet extends ConsumerStatefulWidget {
  final DeviceUIModel device;
  final DeviceScore score;
  /// Called to open Help Me Fix It tab Flow 3 for this device.
  final ValueChanged<DeviceUIModel?>? onGoToFlow3;

  const _TroubleshootSheet({
    required this.device,
    required this.score,
    this.onGoToFlow3,
  });

  @override
  ConsumerState<_TroubleshootSheet> createState() => _TroubleshootSheetState();
}

class _TroubleshootSheetState extends ConsumerState<_TroubleshootSheet> {
  bool _isDisconnecting = false;

  DeviceUIModel get device => widget.device;
  DeviceScore get score => widget.score;

  @override
  Widget build(BuildContext context) {
    final signal = device.signalStrength;
    final rateMbps =
        device.downlinkRate != null ? device.downlinkRate! / 1000000 : null;
    final colors = Theme.of(context).colorScheme;
    final isWeak = signal != null && signal < -75;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device header with meta chips
          Row(children: [
            const Icon(Icons.devices, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(device.displayName, style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (device.band != null) PillChip(device.band!),
            if (signal != null) PillChip('$signal dBm'),
            if (rateMbps != null) PillChip('↑${rateMbps.toStringAsFixed(0)} Mbps'),
          ]),
          const SizedBox(height: 16),
          // Targeted advice
          _adviceText(context, signal, rateMbps),
          const SizedBox(height: 16),
          // Reconnect — USP deauth not available yet; shown disabled with note
          if (device.isWifi) ...[
            _isDisconnecting
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    label: const Text('Disconnecting…'),
                  )
                : OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.wifi_off_outlined, size: 18),
                    label: Text(loc(context).instantTestDisconnectReconnect),
                  ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isWeak
                    ? loc(context).instantTestDisconnectWeakNote
                    : loc(context).instantTestDisconnectComingSoon,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Go to Help Me Fix It Flow 3
          OutlinedButton.icon(
            // Passes the specific device so InstantTestPage can fire flow 30
          onPressed: widget.onGoToFlow3 != null
                ? () {
                    Navigator.of(context).pop();
                    widget.onGoToFlow3!(widget.device);
                  }
                : null,
            icon: const Icon(Icons.build_outlined, size: 18),
            label: Text(loc(context).instantTestGoToHelpMeFixIt),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed(
                RouteNamed.uspDeviceDetail,
                queryParameters: {'mac': device.mac},
              );
            },
            child: Text(loc(context).instantTestViewDeviceDetails),
          ),
        ],
      ),
    );
  }

  Widget _adviceText(BuildContext context, int? signal, double? rateMbps) {
    if (signal != null && signal < -75) {
      final critical = signal < -82;
      return Text(
        critical
            ? loc(context).instantTestAdviceVeryWeak(signal)
            : loc(context).instantTestAdviceWeak(signal),
      );
    }
    if (rateMbps != null && rateMbps < 10) {
      return Text(loc(context).instantTestAdviceSlowRate);
    }
    return Text(loc(context).instantTestAdviceGeneric);
  }
}
