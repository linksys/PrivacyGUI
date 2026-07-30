import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/dhcp/providers/dhcp_client_filter_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Read-only card displaying DHCP client leases with filter chips.
class UspDhcpActiveLeasesCard extends ConsumerWidget {
  final List<DhcpClientUIModel> clients;

  const UspDhcpActiveLeasesCard({super.key, required this.clients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dhcpClientFilterProvider);
    final onlineCount = clients.where((c) => c.isOnline == true).length;

    final filtered = filter == DhcpClientFilter.onlineOnly
        ? clients.where((c) => c.isOnline == true).toList()
        : clients;

    final sorted = List<DhcpClientUIModel>.from(filtered)
      ..sort((a, b) {
        // Online first, then by displayName
        final aOnline = a.isOnline == true;
        final bOnline = b.isOnline == true;
        if (aOnline != bOnline) return aOnline ? -1 : 1;
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
              AppText.titleSmall(loc(context).activeLeases),
              AppText.labelLarge('$onlineCount / ${clients.length}'),
            ],
          ),
          AppGap.sm(),
          _buildFilterChips(context, ref, filter),
          AppGap.md(),
          if (sorted.isEmpty)
            DetailEmptyBlock(
              icon: Icons.devices,
              message: loc(context).noDhcpClients,
            )
          else
            ...sorted.map((c) => _buildClientRow(context, c)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    DhcpClientFilter filter,
  ) {
    const filters = DhcpClientFilter.values;
    return AppChipGroup(
      chips: filters
          .map((f) => ChipItem(label: _filterLabel(context, f)))
          .toList(),
      selectedIndices: {filters.indexOf(filter)},
      selectionMode: ChipSelectionMode.single,
      onSelectionChanged: (indices) {
        if (indices.isNotEmpty) {
          ref.read(dhcpClientFilterProvider.notifier).state =
              filters[indices.first];
        }
      },
      wrap: false,
    );
  }

  String _filterLabel(BuildContext context, DhcpClientFilter filter) {
    switch (filter) {
      case DhcpClientFilter.all:
        return loc(context).all;
      case DhcpClientFilter.onlineOnly:
        return loc(context).online;
    }
  }

  Widget _buildClientRow(BuildContext context, DhcpClientUIModel client) {
    final colorScheme = Theme.of(context).colorScheme;
    final lease = client.leaseTimeFormatted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        // Columns are sized by flex, not `context.colWidth()`: colWidth is
        // measured against the page grid, so on a 4-column mobile grid two
        // colWidth(2) boxes exceed this row's own width, starving the name
        // column to zero and overflowing the row (#1140).
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color:
                  client.isOnline == true ? Colors.green : colorScheme.outline,
            ),
            AppGap.sm(),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    client.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.hostName.isNotEmpty)
                    AppText.bodySmall(
                      client.mac,
                      color: colorScheme.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AppGap.sm(),
            Expanded(
              flex: 3,
              child: AppText.bodySmall(
                client.ip,
                color: colorScheme.onSurfaceVariant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppGap.sm(),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lease.isNotEmpty)
                    AppText.bodySmall(
                      lease,
                      color: colorScheme.onSurfaceVariant,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (client.leaseExpiryFormatted.isNotEmpty)
                    AppText.bodySmall(
                      client.leaseExpiryFormatted,
                      color: colorScheme.onSurfaceVariant,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
