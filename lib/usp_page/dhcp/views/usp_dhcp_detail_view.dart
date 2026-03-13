import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/usp_page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/usp_page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// DHCP detail page — shows server info, active leases, and reservations.
///
/// Reads from [uspDashboardProvider] (shared state). All mutations delegate
/// to [UspDashboardNotifier] to keep state in sync with the dashboard.
class UspDhcpDetailView extends ConsumerWidget {
  const UspDhcpDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspDashboardProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'DHCP Settings',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
      onRefresh: () => ref.refresh(uspDashboardProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: AppLoader(),
            ),
          ),
          error: (error, stack) => _buildError(childContext, ref, error),
          data: (state) => _buildContent(childContext, ref, state),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load DHCP data'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspDashboardProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    return AppResponsiveLayout(
      mobile: (ctx) => _buildMobileLayout(ctx, state),
      desktop: (ctx) => _buildDesktopLayout(ctx, state),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile: single column
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context, UspDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UspDhcpServerInfoCard(info: state.lanInfoModel),
        AppGap.xl(),
        UspDhcpActiveLeasesCard(clients: state.dhcpClientModels),
        AppGap.xl(),
        UspDhcpReservationsDetailCard(
            reservations: state.dhcpReservationModels),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: server info full-width, then two columns
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(BuildContext context, UspDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UspDhcpServerInfoCard(info: state.lanInfoModel),
        AppGap.xl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: context.colWidth(6),
              child: UspDhcpActiveLeasesCard(clients: state.dhcpClientModels),
            ),
            AppGap.gutter(),
            SizedBox(
              width: context.colWidth(6),
              child: UspDhcpReservationsDetailCard(
                  reservations: state.dhcpReservationModels),
            ),
          ],
        ),
      ],
    );
  }
}
