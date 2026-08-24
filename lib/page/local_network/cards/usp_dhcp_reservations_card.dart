import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
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
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDhcpReservationsCard extends ConsumerWidget {
  const UspDhcpReservationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhcpData = ref.watch(dhcpDataProvider).valueOrNull;
    if (dhcpData == null) return const CardSkeleton.list(rows: 3);
    final reservations = dhcpData.reservationModels;
    final clients = dhcpData.clientModels;
    // Dashboard shows only online clients (based on Hosts.Active, not DHCP lease).
    final onlineClients = clients.where((c) => c.isOnline == true).toList();
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';
    final compact = CardDensityScope.of(context) == CardDensity.compact;

    return DashboardCardTemplate.multiSection(
      title: 'DHCP',
      trailing: AppIconButton(
        icon: AppIcon.font(Icons.add, size: 20),
        onTap: isLoading ? null : () => _showAddDhcpDialog(context, ref),
      ),
      // Reservations, not reservations plus leases. The card is two sections and
      // the footer counts both, but the tile has one number and the reservations
      // are the ones a user configured — the leases are whatever happens to be
      // connected, which `connected_devices` already reports.
      popupValue: '${reservations.length}',
      detailRoute: RouteNamed.uspDhcpDetail,
      itemCount: reservations.length + onlineClients.length,
      sections: [
        CardSection(
          title: loc(context).reservations,
          titleBadge: AppText.labelMedium('${reservations.length}'),
          isEmpty: reservations.isEmpty,
          emptyMessage: loc(context).noDhcpReservations,
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
          title: loc(context).activeLeases,
          titleBadge: AppText.labelMedium('${onlineClients.length}'),
          isEmpty: onlineClients.isEmpty,
          emptyMessage: 'No DHCP clients',
          content: Column(
            children: [
              for (var i = 0; i < onlineClients.length; i++) ...[
                _buildClientRow(context, onlineClients[i], compact: compact),
                if (i < onlineClients.length - 1) AppGap.sm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationRow(BuildContext context, WidgetRef ref,
      DhcpReservationUIModel reservation, bool isLoading) {
    return ToggleRow(
      value: reservation.enable,
      isLoading: isLoading,
      onChanged: isLoading || reservation.instancePath == null
          ? null
          : (value) => performUspMutation(
                context,
                ref,
                loadingKey: 'dhcp',
                mutation: () => ref
                    .read(uspDhcpReservationsProvider.notifier)
                    .immediateToggle(reservation.instancePath!, value),
              ),
      title: reservation.mac,
      subtitle: reservation.ip,
      trailing: AppIconButton(
        icon: AppIcon.font(Icons.delete_outline, size: 18),
        onTap: isLoading || reservation.instancePath == null
            ? null
            : () => _confirmDeleteDhcp(context, ref, reservation),
      ),
    );
  }

  /// The Active Leases row.
  ///
  /// **Why this row has a compact form (#1321).** The trailing slot carries an IP
  /// *and* a lease duration, and `AppListTile` hands `trailing` through
  /// unconstrained, so the row overflowed by 50.0px at 260.5px and 29.0px at
  /// 288.0px — both widths the #1183 gate sweeps — with the lease clipped at the
  /// right edge on a real router. Neither operand can give: the IP is what the row
  /// exists to show, and an ellipsized `10h…` is the defect that was reported, not
  /// a fix for it.
  ///
  /// So the compact form **stacks** them instead of dropping either. That is the
  /// half of the fix that matters at the narrow end: [DeviceRow.compact] returns
  /// 60px (the 44px icon block plus the 16px gap ui_kit adds per occupied slot),
  /// which alone clears 252px and not the 200px the band starts at. Stacked, the
  /// slot's demand falls from IP + gap + lease to `max(IP, lease)` — the address
  /// at every reachable content, since the widest lease a pool can hand out
  /// (`364d 23h`, capped by `validateLeaseTime`) is narrower than a 15-character
  /// quad. The band is therefore bounded by the address alone, which is why
  /// `normalAbove: 369` covers it from 200px up.
  ///
  /// The icon the compact form drops is the only part of this row that can go
  /// without loss: [build] filters to `isOnline == true` before building any row,
  /// so the dot is **always** the success colour here and the ternary below has
  /// one reachable branch. It is kept for the normal form because the row is a
  /// live lease and the dot says so at a glance — it carries no information the
  /// caller cannot already infer, which is exactly what makes it the right thing
  /// to spend.
  Widget _buildClientRow(
    BuildContext context,
    DhcpClientUIModel client, {
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final lease = client.leaseTimeFormatted;

    return DeviceRow(
      compact: compact,
      icon: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: client.isOnline == true
              ? (appColors?.semanticSuccess ?? Colors.green)
              : colorScheme.outline,
        ),
      ),
      title: client.displayName,
      subtitle: client.hostName.isNotEmpty ? client.mac : null,
      trailing: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText.bodySmall(client.ip,
                    color: colorScheme.onSurfaceVariant),
                if (lease.isNotEmpty)
                  AppText.bodySmall(lease, color: colorScheme.onSurfaceVariant),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodySmall(client.ip,
                    color: colorScheme.onSurfaceVariant),
                if (lease.isNotEmpty) ...[
                  AppGap.md(),
                  AppText.bodySmall(lease, color: colorScheme.onSurfaceVariant),
                ],
              ],
            ),
    );
  }

  Future<void> _showAddDhcpDialog(BuildContext context, WidgetRef ref) async {
    final options = _buildDeviceOptions(ref);
    final result = await showAppDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => DhcpReservationEditDialog(
        macDeviceOptions: options.mac,
        ipDeviceOptions: options.ip,
      ),
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
      successMessage: loc(context).reservationAdded,
    );
  }

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

  Future<void> _confirmDeleteDhcp(BuildContext context, WidgetRef ref,
      DhcpReservationUIModel reservation) async {
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
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () => ref
          .read(uspDhcpReservationsProvider.notifier)
          .immediateDelete(reservation.instancePath!),
      successMessage: loc(context).reservationDeleted,
    );
  }
}
