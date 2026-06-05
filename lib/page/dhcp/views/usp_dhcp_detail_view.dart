import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_feature_state.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// DHCP detail page — shows server info, active leases, and reservations.
///
/// Server info from [lanDataProvider], active leases from [dhcpDataProvider],
/// reservations from [uspDhcpReservationsProvider] (page-level Preservable).
class UspDhcpDetailView extends ConsumerWidget {
  const UspDhcpDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDhcp = ref.watch(dhcpDataProvider);
    final reservationState = ref.watch(uspDhcpReservationsProvider);
    final reservationStatus = reservationState.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'DHCP Settings',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspLocalNetwork,
      onRefresh: () async {
        ref.invalidate(dhcpDataProvider);
        ref.read(uspDhcpReservationsProvider.notifier).fetch(forceRemote: true);
      },
      bottomBar: _buildBottomBar(context, ref, reservationState),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        // Show loading if either source is still loading
        if (reservationStatus.isLoading ||
            (asyncDhcp.isLoading && asyncDhcp.valueOrNull == null)) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: AppLoader(),
            ),
          );
        }

        if (reservationStatus.error != null) {
          return _buildError(childContext, ref, reservationStatus.error!);
        }

        if (asyncDhcp.hasError && asyncDhcp.valueOrNull == null) {
          return _buildError(childContext, ref, asyncDhcp.error.toString());
        }

        return _buildContent(childContext, ref);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    DhcpReservationsFeatureState reservationState,
  ) {
    if (!reservationState.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !reservationState.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () =>
          ref.read(uspDhcpReservationsProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium(loc(context).failedToLoadSettings),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: loc(context).retry,
            onTap: () {
              ref.invalidate(dhcpDataProvider);
              ref
                  .read(uspDhcpReservationsProvider.notifier)
                  .fetch(forceRemote: true);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final dhcpData = ref.watch(dhcpDataProvider).valueOrNull;
    final lanInfo = ref.watch(lanDataProvider).valueOrNull?.model;
    final reservationState = ref.watch(uspDhcpReservationsProvider);
    final reservations = reservationState.settings.current.reservations;
    final isSaving = reservationState.status.isSaving;
    final clients = dhcpData?.clientModels ?? [];

    return AppResponsiveLayout(
      mobile: (ctx) =>
          _buildMobileLayout(ctx, lanInfo, clients, reservations, isSaving),
      desktop: (ctx) =>
          _buildDesktopLayout(ctx, lanInfo, clients, reservations, isSaving),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile: single column
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(
    BuildContext context,
    dynamic lanInfo,
    List<DhcpClientUIModel> clients,
    List<DhcpReservationUIModel> reservations,
    bool isSaving,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lanInfo != null) UspDhcpServerInfoCard(info: lanInfo),
        AppGap.xl(),
        UspDhcpActiveLeasesCard(clients: clients),
        AppGap.xl(),
        UspDhcpReservationsDetailCard(
          reservations: reservations,
          isSaving: isSaving,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: server info full-width, then two columns
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(
    BuildContext context,
    dynamic lanInfo,
    List<DhcpClientUIModel> clients,
    List<DhcpReservationUIModel> reservations,
    bool isSaving,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lanInfo != null) UspDhcpServerInfoCard(info: lanInfo),
        AppGap.xl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: context.colWidth(6),
              child: UspDhcpActiveLeasesCard(clients: clients),
            ),
            AppGap.gutter(),
            SizedBox(
              width: context.colWidth(6),
              child: UspDhcpReservationsDetailCard(
                reservations: reservations,
                isSaving: isSaving,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspDhcpReservationsProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, 'DHCP reservations saved');
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to save: $e');
      }
    }
  }
}
