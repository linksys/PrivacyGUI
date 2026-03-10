import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_fab.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/usp_page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Standalone USP Dashboard — displays device info fetched directly via USP.
///
/// Handles loading/error states, then delegates to [UspSliverDashboardView]
/// which uses SliverDashboard as the single layout engine for all modes.
class UspDashboardView extends ConsumerWidget {
  const UspDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspDashboardProvider);
    final isRefreshing =
        asyncState.isLoading && asyncState.valueOrNull != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main dashboard content
        SafeArea(
          child: Column(
            children: [
              const UspTopBar(),
              if (isRefreshing)
                LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                ),
              Expanded(
                child: asyncState.when(
                  loading: () => _buildSkeleton(context, ref),
                  error: (error, stack) => _buildError(context, ref, error),
                  data: (_) => const UspSliverDashboardView(),
                ),
              ),
            ],
          ),
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 4,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
            ),
            AppGap.md(),
            const UspDashboardSkeleton(),
          ],
        ),
      ),
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

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    context.goNamed(RouteNamed.home);
  }
}
