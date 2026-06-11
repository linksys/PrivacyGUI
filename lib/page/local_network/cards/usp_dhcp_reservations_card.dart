import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/dhcp_reservation_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDhcpReservationsCard extends ConsumerWidget {
  const UspDhcpReservationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhcpData = ref.watch(dhcpDataProvider).valueOrNull;
    if (dhcpData == null) return const CardSkeleton.list(rows: 3);
    final reservations = dhcpData.reservationModels;
    final clients = dhcpData.clientModels;
    final activeClients = clients.where((c) => c.active).toList();
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return DashboardCardTemplate.multiSection(
      title: 'DHCP',
      trailing: AppIconButton(
        icon: AppIcon.font(Icons.add, size: 20),
        onTap: isLoading ? null : () => _showAddDhcpDialog(context, ref),
      ),
      detailRoute: RouteNamed.uspDhcpDetail,
      itemCount: reservations.length + activeClients.length,
      sections: [
        CardSection(
          title: 'Reservations',
          titleBadge: AppText.labelMedium('${reservations.length}'),
          isEmpty: reservations.isEmpty,
          emptyMessage: 'No DHCP reservations configured',
          content: Column(
            children: [
              for (var i = 0; i < reservations.length; i++) ...[
                _buildReservationRow(context, ref, reservations[i], isLoading),
                if (i < reservations.length - 1) AppGap.sm(),
              ],
            ],
          ),
        ),
        CardSection(
          title: 'Active Leases',
          titleBadge: AppText.labelMedium('${activeClients.length}'),
          isEmpty: clients.isEmpty,
          emptyMessage: 'No DHCP clients',
          content: Column(
            children: [
              for (var i = 0; i < clients.length; i++) ...[
                _buildClientRow(context, clients[i]),
                if (i < clients.length - 1) AppGap.sm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationRow(BuildContext context, WidgetRef ref,
      DhcpReservationUIModel reservation, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
      child: Row(
        children: [
          AppSwitch(
            value: reservation.enable,
            scale: 0.8,
            onChanged: isLoading
                ? null
                : (value) => performUspMutation(
                      context,
                      ref,
                      loadingKey: 'dhcp',
                      mutation: () => ref
                          .read(uspDhcpReservationsProvider.notifier)
                          .immediateToggle(reservation.instancePath!, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(reservation.mac)),
          AppText.bodySmall(
            reservation.ip,
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isLoading
                ? null
                : () => _confirmDeleteDhcp(context, ref, reservation),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(BuildContext context, DhcpClientUIModel client) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final lease = client.leaseTimeFormatted;

    return LayoutBlock(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: client.active
                  ? (appColors?.semanticSuccess ?? Colors.green)
                  : colorScheme.outline,
            ),
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
          AppText.bodySmall(client.ip, color: colorScheme.onSurfaceVariant),
          if (lease.isNotEmpty) ...[
            AppGap.md(),
            AppText.bodySmall(lease, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddDhcpDialog(BuildContext context, WidgetRef ref) async {
    final result = await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => const DhcpReservationDialog(),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () =>
          ref.read(uspDhcpReservationsProvider.notifier).immediateAdd(
                mac: result.mac,
                ip: result.ip,
                enable: result.enable,
              ),
      successMessage: 'Reservation added',
    );
  }

  Future<void> _confirmDeleteDhcp(BuildContext context, WidgetRef ref,
      DhcpReservationUIModel reservation) async {
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: 'Delete Reservation',
      content: AppText.bodyMedium('Delete reservation for ${reservation.mac}?'),
      actions: [
        AppButton.text(
          label: 'Cancel',
          onTap: () => context.pop(),
        ),
        AppButton.dangerText(
          label: 'Delete',
          onTap: () => context.pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () => ref
          .read(uspDhcpReservationsProvider.notifier)
          .immediateDelete(reservation.instancePath!),
      successMessage: 'Reservation deleted',
    );
  }
}
