import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full CRUD card for DHCP reservations on the detail page.
class UspDhcpReservationsDetailCard extends ConsumerWidget {
  final List<DhcpReservationUIModel> reservations;

  const UspDhcpReservationsDetailCard({
    super.key,
    required this.reservations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('DHCP Reservations'),
              Row(
                children: [
                  AppText.labelLarge('${reservations.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap:
                        isLoading ? null : () => _showAddDialog(context, ref),
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
        ],
      ),
    );
  }

  Widget _buildReservationRow(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationUIModel reservation,
    bool isLoading,
  ) {
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
            icon: AppIcon.font(Icons.edit_outlined, size: 18),
            onTap: isLoading
                ? null
                : () => _showEditDialog(context, ref, reservation),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isLoading
                ? null
                : () => _confirmDelete(context, ref, reservation),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => const DhcpReservationEditDialog(),
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

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationUIModel reservation,
  ) async {
    final result = await showDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(reservation: reservation),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () =>
          ref.read(dhcpDataProvider.notifier).updateReservation(
                instancePath: reservation.instancePath,
                mac: result.mac,
                ip: result.ip,
                enable: result.enable,
              ),
      successMessage: 'Reservation updated',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationUIModel reservation,
  ) async {
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
