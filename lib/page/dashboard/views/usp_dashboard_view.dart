import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Standalone USP Dashboard — displays device info fetched directly via USP.
///
/// Handles loading/error states, then delegates to [UspSliverDashboardView]
/// which uses SliverDashboard as the single layout engine for all modes.
class UspDashboardView extends ConsumerWidget {
  const UspDashboardView({super.key});

  static const _animDuration = Duration(milliseconds: 250);
  static const _topBarHeight = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(dashboardOrchestratorProvider);
    final isRefreshing = asyncState.isLoading && asyncState.valueOrNull != null;
    final barsVisible = ref.watch(uspBarsVisibleProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main dashboard content
        SafeArea(
          child: Column(
            children: [
              AnimatedContainer(
                duration: _animDuration,
                height: barsVisible ? _topBarHeight : 0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: const UspTopBar(),
              ),
              if (isRefreshing)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: AppLoader(variant: LoaderVariant.linear),
                ),
              Expanded(
                child: asyncState.when(
                  loading: () => const Center(
                    child: AppLoader(),
                  ),
                  error: (error, stack) => _buildError(context, ref, error),
                  data: (_) => const UspSliverDashboardView(),
                ),
              ),
            ],
          ),
        ),
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
            onTap: () =>
                ref.read(dashboardOrchestratorProvider.notifier).refreshAll(),
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

  void _logout(BuildContext context, WidgetRef ref) {
    // Fire-and-forget logout (same pattern as JNAP general_settings_widget).
    // Navigate synchronously — no async gap avoids WidgetRef invalidation.
    // Go directly to localLoginPassword instead of '/' to skip the heavy
    // autoConfigurationLogic redirect that re-runs authCheck/init().
    ref.read(authProvider.notifier).logout();
    ref.read(routerProvider).go(RoutePath.localLoginPassword);
  }
}
