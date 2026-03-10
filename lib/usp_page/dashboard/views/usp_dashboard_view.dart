import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_fab.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dashboard/services/usp_pdf_service.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Standalone USP Dashboard — displays device info fetched directly via USP.
///
/// This page is completely independent of JNAP polling. It is used as the
/// landing page when USP is the only viable protocol (e.g. JNAP disabled
/// on the router firmware).
class UspDashboardView extends ConsumerWidget {
  const UspDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspDashboardProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main dashboard content
        UiKitPageView.withSliver(
          scrollable: true,
          appBarStyle: UiKitAppBarStyle.none,
          topbar: const PreferredSize(
            preferredSize: Size.fromHeight(64),
            child: UspTopBar(),
          ),
          backState: UiKitBackState.none,
          onRefresh: () => ref.refresh(uspDashboardProvider.future),
          padding:
              const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
          child: (childContext, constraints) {
            final isRefreshing =
                asyncState.isLoading && asyncState.valueOrNull != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRefreshing)
                  LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Theme.of(childContext)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                  ),
                asyncState.when(
                  loading: () => _buildSkeleton(childContext, ref),
                  error: (error, stack) =>
                      _buildError(childContext, ref, error),
                  data: (state) => _buildContent(childContext, ref, state),
                ),
              ],
            );
          },
        ),

        // Theme Studio Panel (animated slide-in from right)
        Consumer(
          builder: (context, ref, _) {
            final isOpen = ref.watch(demoUIProvider).isThemePanelOpen;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              top: 0,
              bottom: 0,
              right: isOpen ? 0 : -500,
              width: 500,
              child: const Material(
                elevation: 16,
                child: ThemeStudioPanel(),
              ),
            );
          },
        ),

        // Theme Studio FAB
        const Positioned(
          bottom: 16,
          right: 16,
          child: ThemeStudioFab(),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(uspLoadingProgressProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress.fraction,
          minHeight: 4,
          backgroundColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        AppGap.md(),
        const UspDashboardSkeleton(),
      ],
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
          AppText.titleMedium('Unable to load USP data'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspDashboardProvider),
          ),
          AppGap.md(),
          AppButton.text(
            label: 'Logout',
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final info = state.systemInfoModel;
    final devices = state.deviceModels;

    return AppResponsiveLayout(
      mobile: (ctx) => _buildMobileLayout(ctx, ref, state, info, devices),
      desktop: (ctx) => _buildDesktopLayout(ctx, ref, state, info, devices),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.headlineSmall('USP Dashboard'),
        Row(
          children: [
            AppIconButton(
              icon: AppIcon.font(Icons.print),
              onTap: () {
                final state = ref.read(uspDashboardProvider).valueOrNull;
                if (state != null) {
                  doSomethingWithSpinner(
                    context,
                    UspPdfService.generatePdf(state),
                  );
                }
              },
            ),
            AppGap.sm(),
            AppIconButton(
              icon: AppIcon.font(Icons.refresh),
              onTap: () => ref.invalidate(uspDashboardProvider),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    UspDashboardState state,
    SystemInfoUIModel info,
    List<DeviceUIModel> devices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        AppGap.xl(),
        UspStatsPanel(state: state, devices: devices),
        AppGap.xl(),
        UspNetworkStatusCard(wan: state.wanStatusModel),
        AppGap.xl(),
        UspNetworkTopologyCard(
            info: info, devices: devices, meshNodes: state.meshTopology.nodes),
        AppGap.xl(),
        UspDeviceInfoCard(info: info),
        AppGap.xl(),
        UspLanInfoCard(info: state.lanInfoModel),
        AppGap.xl(),
        UspEthernetPortsCard(ports: state.ethernetPortModels),
        AppGap.xl(),
        UspSystemStatusCard(info: info),
        AppGap.xl(),
        UspConnectedDevicesCard(
          devices: devices,
          onViewAll: () => context.goNamed(RouteNamed.uspDeviceList),
        ),
        AppGap.xl(),
        UspWifiStatusCard(state: state),
        AppGap.xl(),
        UspTimeSettingsCard(state: state),
        AppGap.xl(),
        UspDhcpReservationsCard(state: state),
        AppGap.xl(),
        UspPortForwardingCard(state: state),
        AppGap.xl(),
        UspProtocolInfoCard(),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    UspDashboardState state,
    SystemInfoUIModel info,
    List<DeviceUIModel> devices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        AppGap.xl(),
        UspStatsPanel(state: state, devices: devices),
        AppGap.xl(),
        UspNetworkStatusCard(wan: state.wanStatusModel),
        AppGap.xl(),
        UspNetworkTopologyCard(
            info: info, devices: devices, meshNodes: state.meshTopology.nodes),
        AppGap.xl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: static info
            Expanded(
              child: Column(
                children: [
                  UspDeviceInfoCard(info: info),
                  AppGap.xl(),
                  UspLanInfoCard(info: state.lanInfoModel),
                  AppGap.xl(),
                  UspEthernetPortsCard(ports: state.ethernetPortModels),
                  AppGap.xl(),
                  UspSystemStatusCard(info: info),
                  AppGap.xl(),
                  UspConnectedDevicesCard(
                    devices: devices,
                    onViewAll: () => context.goNamed(RouteNamed.uspDeviceList),
                  ),
                  AppGap.xl(),
                  UspProtocolInfoCard(),
                ],
              ),
            ),
            AppGap.gutter(),
            // Right column: interactive/CRUD
            Expanded(
              child: Column(
                children: [
                  UspWifiStatusCard(state: state),
                  AppGap.xl(),
                  UspTimeSettingsCard(state: state),
                  AppGap.xl(),
                  UspDhcpReservationsCard(state: state),
                  AppGap.xl(),
                  UspPortForwardingCard(state: state),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    context.goNamed(RouteNamed.home);
  }
}
