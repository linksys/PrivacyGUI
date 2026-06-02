import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Read-only card displaying active DHCP client leases.
class UspDhcpActiveLeasesCard extends StatelessWidget {
  final List<DhcpClientUIModel> clients;

  const UspDhcpActiveLeasesCard({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    final activeCount = clients.where((c) => c.active).length;
    final sorted = List<DhcpClientUIModel>.from(clients)
      ..sort((a, b) {
        // Active first, then by displayName
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleSmall('Active Leases'),
              AppText.labelLarge('$activeCount / ${clients.length}'),
            ],
          ),
          AppGap.md(),
          if (sorted.isEmpty)
            const DetailEmptyBlock(
              icon: Icons.devices,
              message: 'No DHCP clients',
            )
          else
            ...sorted.map((c) => _buildClientRow(context, c)),
        ],
      ),
    );
  }

  Widget _buildClientRow(BuildContext context, DhcpClientUIModel client) {
    final colorScheme = Theme.of(context).colorScheme;
    final lease = client.leaseTimeFormatted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Block(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: client.active ? Colors.green : colorScheme.outline,
            ),
            AppGap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(client.displayName),
                  AppText.bodySmall(
                    [
                      if (client.hostName.isNotEmpty) client.mac,
                      if (client.leaseExpiryFormatted.isNotEmpty)
                        'Lease: ${client.leaseExpiryFormatted}',
                    ].join(' · '),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: context.colWidth(2),
              child: AppText.bodySmall(
                client.ip,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (lease.isNotEmpty)
              SizedBox(
                width: context.colWidth(1),
                child: AppText.bodySmall(
                  lease,
                  color: colorScheme.onSurfaceVariant,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
