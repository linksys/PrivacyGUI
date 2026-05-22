import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full CRUD card for DHCP reservations on the detail page.
class UspDhcpReservationsDetailCard extends ConsumerWidget {
  final List<DhcpReservationUIModel> reservations;
  final bool isSaving;

  const UspDhcpReservationsDetailCard({
    super.key,
    required this.reservations,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onTap: isSaving ? null : () => _showAddDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          if (reservations.isEmpty)
            AppText.bodyMedium('No DHCP reservations configured')
          else
            ...reservations.map((r) => _buildReservationRow(context, ref, r)),
        ],
      ),
    );
  }

  Widget _buildReservationRow(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationUIModel reservation,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppSwitch(
            value: reservation.enable,
            scale: 0.8,
            onChanged: isSaving
                ? null
                : (value) => ref
                    .read(uspDhcpReservationsProvider.notifier)
                    .toggleReservation(reservation, value),
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
            onTap: isSaving
                ? null
                : () => _showEditDialog(context, ref, reservation),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isSaving
                ? null
                : () => _confirmDelete(context, ref, reservation),
          ),
        ],
      ),
    );
  }

  ({List<AppAutoCompleteOption> mac, List<AppAutoCompleteOption> ip})
      _buildDeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(devicesDataProvider).valueOrNull?.deviceModels ?? [];
    final macOptions = devices
        .where((d) => d.mac.isNotEmpty)
        .map((d) => AppAutoCompleteOption(
              label: d.displayName,
              value: d.mac,
              subtitle: d.ip,
              isActive: d.isActive,
            ))
        .toList();
    final ipOptions = devices
        .where((d) => d.ip.isNotEmpty)
        .map((d) => AppAutoCompleteOption(
              label: d.displayName,
              value: d.ip,
              subtitle: d.mac,
              isActive: d.isActive,
            ))
        .toList();
    return (mac: macOptions, ip: ipOptions);
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final options = _buildDeviceOptions(ref);
    final result =
        await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(
        macDeviceOptions: options.mac,
        ipDeviceOptions: options.ip,
      ),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspDhcpReservationsProvider.notifier).addReservation(
          DhcpReservationUIModel(
            mac: result.mac,
            ip: result.ip,
            enable: result.enable,
          ),
        );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationUIModel reservation,
  ) async {
    final options = _buildDeviceOptions(ref);
    final result =
        await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(
        reservation: reservation,
        macDeviceOptions: options.mac,
        ipDeviceOptions: options.ip,
      ),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspDhcpReservationsProvider.notifier).editReservation(
          reservation,
          reservation.copyWith(
            mac: result.mac,
            ip: result.ip,
            enable: result.enable,
          ),
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
    ref
        .read(uspDhcpReservationsProvider.notifier)
        .deleteReservation(reservation);
  }
}
