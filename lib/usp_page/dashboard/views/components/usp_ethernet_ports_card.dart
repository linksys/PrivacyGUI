import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/ethernet_port_detail_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspEthernetPortsCard extends ConsumerWidget {
  final List<EthernetPortUIModel>? ports;

  const UspEthernetPortsCard({super.key, this.ports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ports = this.ports ??
        ref.watch(uspDashboardProvider).valueOrNull?.ethernetPortModels ??
        [];
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Ethernet Ports'),
            AppGap.xl(),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.lg,
              children: ports.map((p) => _PortItem(port: p)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortItem extends StatelessWidget {
  final EthernetPortUIModel port;

  const _PortItem({required this.port});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor =
        theme.extension<AppColorScheme>()?.semanticSuccess ?? Colors.green;
    final inactiveColor = theme.colorScheme.surfaceContainerHighest;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () => showEthernetPortDetailDialog(context, port),
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.imgPortOn.svg(
              width: 40,
              height: 38,
              colorFilter: ColorFilter.mode(
                port.isUp ? successColor : inactiveColor,
                BlendMode.srcIn,
              ),
            ),
            AppGap.sm(),
            AppText.labelMedium(port.label),
            AppGap.xs(),
            AppText.bodySmall(
              port.speedLabel,
              color: secondaryTextColor,
            ),
            if (port.connectedDevices.isNotEmpty) ...[
              AppGap.xs(),
              AppText.bodySmall(
                port.connectedDevices.length == 1
                    ? port.connectedDevices.first.displayName
                    : '${port.connectedDevices.first.displayName} +${port.connectedDevices.length - 1}',
                color: secondaryTextColor,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
