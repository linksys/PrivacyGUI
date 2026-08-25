import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible, not a bare AppText (#1349). The title sized itself to
              // its natural width against a rigid count-plus-button group, so
              // neither child could yield: `ar` overflowed this row by 113px at a
              // 320px screen and by 141px at 601px, where the page's two-column
              // band hands the card a narrower box than the one-column band does.
              // Flexible rather than Expanded so a short title still paints at its
              // own width and `spaceBetween` keeps distributing the slack — the
              // layout is unchanged wherever it already fitted, and wraps instead
              // of overflowing where it did not.
              Flexible(
                child: AppText.titleSmall(loc(context).dhcpReservations),
              ),
              Row(
                children: [
                  AppText.labelLarge('${reservations.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    identifier: 'dhcp-reservation-add',
                    onTap: isSaving ? null : () => _showAddDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.md(),
          if (reservations.isEmpty)
            DetailEmptyBlock(
              icon: Icons.bookmark_border,
              message: loc(context).noDhcpReservations,
            )
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            AppGap.md(),
            // MAC over IP rather than side by side: the row's flexible space is
            // narrower than a full MAC plus an IP, so a side-by-side layout
            // ellipsised the MAC — the row's only device identifier. The IP no
            // longer uses `context.colWidth()`, which measures against the page
            // grid: its 216dp on a 4-column mobile grid left the MAC column too
            // narrow for one line, wrapping it one octet per line (#1140).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    reservation.mac,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reservation.ip.isNotEmpty)
                    AppText.bodySmall(
                      reservation.ip,
                      color: colorScheme.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AppGap.sm(),
            AppIconButton(
              icon: AppIcon.font(Icons.edit_outlined, size: 18),
              identifier: 'dhcp-reservation-edit-${reservation.mac}',
              onTap: isSaving
                  ? null
                  : () => _showEditDialog(context, ref, reservation),
            ),
            AppGap.sm(),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              identifier: 'dhcp-reservation-delete-${reservation.mac}',
              onTap: isSaving
                  ? null
                  : () => _confirmDelete(context, ref, reservation),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps device data from the notifier to autocomplete UI options for the
  /// MAC and IP fields.
  ({List<AppAutoCompleteOption> mac, List<AppAutoCompleteOption> ip})
      _buildDeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(uspDhcpReservationsProvider.notifier).deviceOptions();
    final macOptions = devices
        .where((d) => d.mac.isNotEmpty)
        .map((d) => AppAutoCompleteOption(
              label: d.name,
              value: d.mac,
              subtitle: d.ip,
              isActive: d.isActive,
            ))
        .toList();
    final ipOptions = devices
        .where((d) => d.ip.isNotEmpty)
        .map((d) => AppAutoCompleteOption(
              label: d.name,
              value: d.ip,
              subtitle: d.mac,
              isActive: d.isActive,
            ))
        .toList();
    return (mac: macOptions, ip: ipOptions);
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final options = _buildDeviceOptions(ref);
    final result = await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(
        macDeviceOptions: options.mac,
        ipDeviceOptions: options.ip,
        existingReservations: reservations,
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
    final result = await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(
        reservation: reservation,
        macDeviceOptions: options.mac,
        ipDeviceOptions: options.ip,
        existingReservations: reservations,
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
      title: loc(context).deleteReservation,
      content: AppText.bodyMedium(
          loc(context).deleteReservationConfirm(reservation.mac)),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.dangerText(
          label: loc(context).delete,
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
