import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_client_ui_model.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Active Leases'),
              AppText.labelLarge('$activeCount / ${clients.length}'),
            ],
          ),
          AppGap.xl(),
          if (sorted.isEmpty)
            AppText.bodyMedium('No DHCP clients')
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
            width: 130,
            child: AppText.bodySmall(
              client.ip,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (lease.isNotEmpty)
            SizedBox(
              width: 70,
              child: AppText.bodySmall(
                lease,
                color: colorScheme.onSurfaceVariant,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
