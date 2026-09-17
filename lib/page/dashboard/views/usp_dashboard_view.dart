import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_available_banner.dart';
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
              // The firmware notice (#1552). Above the scroll view rather than in
              // it: it is not a dashboard card, it outranks all of them, and a
              // card would scroll out of sight on the surface where most users
              // never scroll.
              //
              // Shown only on the arm below that renders the dashboard, and it has
              // to be spelled with both halves. `hasValue` alone is true for an
              // `AsyncError.copyWithPrevious` — the shape riverpod publishes when a
              // refresh fails after a successful boot — so on a dropped session the
              // banner would paint above the `ServiceErrorView` the `when` renders,
              // offering Update Now on a page that just said it cannot reach the
              // router.
              //
              // What the gate defers is one USP read, the `fwup` UCI subtree. The
              // other one is already made: `systemInfoDataProvider` is the
              // orchestrator's first domain provider and its `build()` listens to
              // `firmwareBanksDataProvider`, so `FirmwareImage.` is fetched during
              // boot whether this banner exists or not. Deferring is still the
              // honest order — there is nothing to interrupt until the dashboard is
              // there to interrupt — and it keeps one fetch out of the boot burst,
              // not two.
              if (asyncState.hasValue && !asyncState.hasError)
                const FirmwareUpdateAvailableBanner(),
              Expanded(
                child: asyncState.when(
                  loading: () => const Center(
                    child: AppLoader(),
                  ),
                  error: (error, stack) => ServiceErrorView(
                    error: error is ServiceError ? error : null,
                    title: loc(context).failedToLoadSettings,
                    onRetry: () => ref
                        .read(dashboardOrchestratorProvider.notifier)
                        .refreshAll(),
                    secondaryLabel: loc(context).logout,
                    onSecondary: () => _logout(context, ref),
                  ),
                  data: (_) => const UspSliverDashboardView(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    // Fire-and-forget logout (same pattern as JNAP general_settings_widget).
    // Navigate synchronously — no async gap avoids WidgetRef invalidation.
    ref.read(authProvider.notifier).logout(cause: EndCause.userRequested);

    // Where "logged out" lands is the mode's answer, not this view's. Before
    // #1323 this went to localLoginPassword unconditionally, which in a Remote
    // Assistance build is a password field that cannot do anything: the
    // credential was a one-shot Guardian token, and there is no local password to
    // type.
    //
    // The switch is here rather than behind a helper because only the *local* arm
    // needs it: `RoutePath.localLoginPassword` is a deliberate shortcut past the
    // '/' redirect, and nothing else wants that. The remote arm agrees with what
    // `router_provider.dart`'s /usp* guard would have answered on its own once
    // cause 3 cleared the session — the two spell '?ended=true' independently, and
    // arriving at the same URL twice is idempotent. Navigating explicitly anyway
    // keeps the two arms symmetric instead of leaving one exit to a redirect and
    // the other not; if that string ever grows a third speller, it wants a named
    // constant rather than a helper.
    final destination =
        switch (ref.read(appModeProfileProvider).session.destination) {
      // Directly, instead of '/', to skip the heavy autoConfigurationLogic
      // redirect that re-runs authCheck/init(). Unchanged from before #1323.
      SessionOutcome.loginPage => RoutePath.localLoginPassword,
      // `ended` rather than `expired`: reaching this button means the user chose
      // to leave from the dashboard's error state.
      SessionOutcome.supportSessionEnded =>
        '${RoutePath.remoteAssistanceConfirm}?ended=true',
    };
    ref.read(routerProvider).go(destination);
  }
}
