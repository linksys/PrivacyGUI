import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/card_skeleton.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/dhcp_reservation_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDhcpReservationsCard extends ConsumerWidget {
  const UspDhcpReservationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhcpData = ref.watch(dhcpDataProvider).valueOrNull;
    if (dhcpData == null) return const CardSkeleton.list(rows: 3);
    final reservations = dhcpData.reservationModels;
    final clients = dhcpData.clientModels;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reservations section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AppText.titleMedium('DHCP Reservations')),
              AppButton.text(
                label: 'View All',
                onTap: () => context.goNamed(RouteNamed.uspDhcpDetail),
              ),
              AppGap.md(),
              Row(
                children: [
                  AppText.labelLarge('${reservations.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap: isLoading
                        ? null
                        : () => _showAddDhcpDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          if (reservations.isEmpty)
            AppText.bodyMedium('No DHCP reservations configured')
          else
            ...reservations
                .map((r) => _buildReservationRow(context, ref, r, isLoading)),
          // ── Client leases section ──
          AppGap.xl(),
          const Divider(),
          AppGap.md(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Active Leases'),
              AppText.labelLarge('${clients.where((c) => c.active).length}'),
            ],
          ),
          AppGap.md(),
          if (clients.isEmpty)
            AppText.bodyMedium('No DHCP clients')
          else
            ...clients.map((c) => _buildClientRow(context, c)),
        ],
      ),
    );
  }

  Widget _buildReservationRow(BuildContext context, WidgetRef ref,
      DhcpReservationUIModel reservation, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          .read(dhcpDataProvider.notifier)
                          .toggleReservation(
                              reservation.instancePath, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(reservation.mac)),
          SizedBox(
            width: context.colWidth(2),
            child: AppText.bodySmall(
              reservation.ip,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
    );
  }

  Future<void> _showAddDhcpDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => const DhcpReservationDialog(),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () =>
          ref.read(dhcpDataProvider.notifier).addReservation(
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
          .read(dhcpDataProvider.notifier)
          .deleteReservation(reservation.instancePath),
      successMessage: 'Reservation deleted',
    );
  }
}
