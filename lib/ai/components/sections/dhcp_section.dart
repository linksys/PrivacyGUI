import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../section_header.dart';

/// DHCP data section.
///
/// Displays DHCP reservations and active clients.
class DhcpSection extends StatelessWidget {
  final List<Map<String, dynamic>>? reservations;
  final List<Map<String, dynamic>>? clients;

  const DhcpSection({
    super.key,
    this.reservations,
    this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final hasReservations = reservations != null && reservations!.isNotEmpty;
    final hasClients = clients != null && clients!.isNotEmpty;

    if (!hasReservations && !hasClients) {
      return AppText.body('No DHCP data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasReservations) ...[
          SectionHeader(
            title: 'Reservations',
            badge: AppBadge(label: '${reservations!.length}'),
          ),
          for (final res in reservations!) _buildReservationRow(res),
        ],
        if (hasReservations && hasClients) ...[
          AppGap.md(),
          const Divider(),
          AppGap.md(),
        ],
        if (hasClients) ...[
          SectionHeader(
            title: 'Active Clients',
            badge: AppBadge(label: '${clients!.length}'),
          ),
          for (final client in clients!) _buildClientRow(client),
        ],
      ],
    );
  }

  Widget _buildReservationRow(Map<String, dynamic> res) {
    final hostname = res['hostname'] as String? ?? 'Unknown';
    final mac = res['mac'] as String? ?? '';
    final ip = res['ip'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(flex: 2, child: AppText.body(hostname)),
          Expanded(flex: 2, child: AppText.bodySmall(mac)),
          Expanded(flex: 2, child: AppText.bodySmall(ip)),
        ],
      ),
    );
  }

  Widget _buildClientRow(Map<String, dynamic> client) {
    final hostname = client['hostname'] as String? ?? 'Unknown';
    final mac = client['mac'] as String? ?? '';
    final ip = client['ip'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(flex: 2, child: AppText.body(hostname)),
          Expanded(flex: 2, child: AppText.bodySmall(mac)),
          Expanded(flex: 2, child: AppText.bodySmall(ip)),
        ],
      ),
    );
  }
}
