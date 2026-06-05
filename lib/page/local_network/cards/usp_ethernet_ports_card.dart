import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/ethernet_port_detail_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspEthernetPortsCard extends ConsumerWidget {
  final List<EthernetPortUIModel>? ports;

  const UspEthernetPortsCard({super.key, this.ports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ports = this.ports ??
        ref.watch(ethernetDataProvider).valueOrNull?.ethernetPortModels;
    if (ports == null) return const CardSkeleton.info(rows: 3);
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final lanPorts = ports.where((p) => !p.isWan).toList();
    final wanPorts = ports.where((p) => p.isWan).toList();
    final lanConnected = lanPorts.where((p) => p.isUp).length;
    final wanConnected = wanPorts.where((p) => p.isUp).length;

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(title: 'Ethernet Ports'),
            AppGap.md(),
            // Summary tiles - WAN first
            Row(
              children: [
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon.font(
                            Icons.public,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        AppGap.md(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(wanConnected > 0
                                ? 'Connected'
                                : 'Disconnected'),
                            AppText.bodySmall(
                              'WAN',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AppGap.sm(),
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (appColors?.semanticSuccess ?? Colors.green)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon.font(
                            Icons.lan,
                            color: appColors?.semanticSuccess ?? Colors.green,
                            size: 20,
                          ),
                        ),
                        AppGap.md(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(
                                '$lanConnected / ${lanPorts.length}'),
                            AppText.bodySmall(
                              'LAN Connected',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppGap.lg(),
            // Port icons
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
