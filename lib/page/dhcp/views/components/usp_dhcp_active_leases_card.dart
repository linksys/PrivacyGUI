import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

enum _DhcpClientFilter { all, onlineOnly }

/// Read-only card displaying DHCP client leases with filter chips.
class UspDhcpActiveLeasesCard extends StatefulWidget {
  final List<DhcpClientUIModel> clients;

  const UspDhcpActiveLeasesCard({super.key, required this.clients});

  @override
  State<UspDhcpActiveLeasesCard> createState() =>
      _UspDhcpActiveLeasesCardState();
}

class _UspDhcpActiveLeasesCardState extends State<UspDhcpActiveLeasesCard> {
  _DhcpClientFilter _filter = _DhcpClientFilter.all;

  @override
  Widget build(BuildContext context) {
    final onlineCount = widget.clients.where((c) => c.isOnline == true).length;

    final filtered = _filter == _DhcpClientFilter.onlineOnly
        ? widget.clients.where((c) => c.isOnline == true).toList()
        : widget.clients;

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
              AppText.labelLarge('$onlineCount / ${widget.clients.length}'),
            ],
          ),
          AppGap.sm(),
          _buildFilterChips(context),
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

  Widget _buildFilterChips(BuildContext context) {
    return Row(
      children: [
        FilterChip(
          label: Text(loc(context).all),
          selected: _filter == _DhcpClientFilter.all,
          onSelected: (_) => setState(() => _filter = _DhcpClientFilter.all),
        ),
        AppGap.sm(),
        FilterChip(
          label: Text(loc(context).online),
          selected: _filter == _DhcpClientFilter.onlineOnly,
          onSelected: (_) =>
              setState(() => _filter = _DhcpClientFilter.onlineOnly),
        ),
      ],
    );
  }

  Widget _buildClientRow(BuildContext context, DhcpClientUIModel client) {
    final colorScheme = Theme.of(context).colorScheme;
    final lease = client.leaseTimeFormatted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(client.displayName),
                  if (client.hostName.isNotEmpty)
                    AppText.bodySmall(
                      client.mac,
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
            SizedBox(
              width: context.colWidth(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lease.isNotEmpty)
                    AppText.bodySmall(
                      lease,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (client.leaseExpiryFormatted.isNotEmpty)
                    AppText.bodySmall(
                      client.leaseExpiryFormatted,
                      color: colorScheme.onSurfaceVariant,
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
