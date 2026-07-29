import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/diagnostic_state.dart';
import '../providers/unified_diagnostics_notifier.dart';
import 'widgets/diagnostic_flow_menu.dart';
import 'widgets/diagnostic_manual_tools_view.dart';
import 'widgets/diagnostic_results_view.dart';
import 'widgets/diagnostic_running_view.dart';
import 'widgets/diagnostic_start_view.dart';

class UnifiedDiagnosticsView extends ConsumerStatefulWidget {
  const UnifiedDiagnosticsView({super.key});

  @override
  ConsumerState<UnifiedDiagnosticsView> createState() =>
      _UnifiedDiagnosticsViewState();
}

class _UnifiedDiagnosticsViewState
    extends ConsumerState<UnifiedDiagnosticsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Snap scroll to top whenever the step changes so newly rendered headers
    // (tabs, problem cards, flow menu) aren't hidden under the previous
    // step's offset.
    ref.listen<UnifiedDiagnosticsState>(
      unifiedDiagnosticsProvider,
      (prev, next) {
        if (prev?.step == next.step) return;
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      },
    );

    final state = ref.watch(unifiedDiagnosticsProvider);

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).networkDiagnostics,
      scrollable: true,
      controller: _scrollController,
      onBackTap: () => _handleBack(context, ref, state),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _buildContent(context, ref, state),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    return switch (state.step) {
      DiagnosticStep.idle => const DiagnosticStartView(),
      DiagnosticStep.preQualifying => _buildPreQualifying(context, ref),
      DiagnosticStep.selectFlow => DiagnosticFlowMenu(state: state),
      DiagnosticStep.manualTools => const DiagnosticManualToolsView(),
      DiagnosticStep.showingResults => DiagnosticResultsView(state: state),
      DiagnosticStep.completed => _buildCompleted(context, ref),
      _ => DiagnosticRunningView(state: state),
    };
  }

  Widget _buildPreQualifying(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: AppLoader(),
          ),
          AppGap.xl(),
          AppText.titleMedium(loc(context).checkingConnection),
          AppGap.md(),
          AppText.bodySmall(
            loc(context).runningQuickNetworkCheck,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.xl(),
          AppText.headlineSmall(loc(context).diagnosticsComplete),
          AppGap.xxxl(),
          AppButton(
            label: loc(context).returnToDashboard,
            onTap: () => _returnToMenu(context, ref),
          ),
        ],
      ),
    );
  }

  // Single-flight guard for the app-bar back tap. onBackTap is a plain
  // VoidCallback slot, so a Future-returning handler would have its Future
  // silently discarded — leaving no guard against a second back-tap firing a
  // concurrent cancel()/teardown that clobbers _teardownFuture. Keeping
  // _handleBack synchronous and gating on this flag prevents that race.
  bool _isBackNavigating = false;

  void _handleBack(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    if (_isBackNavigating) return;
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    final handledInternally = notifier.goBack();
    if (handledInternally) return;

    // Leaving the page: capture the router before any state change, cancel the
    // in-flight run, then navigate only after the full teardown (in-flight
    // drain + scope release) completes — mirroring _returnToMenu. Awaiting
    // cancel() alone would race the unsubscribe DELETE against a quick
    // re-entry's subscribe POST.
    _isBackNavigating = true;
    final router = GoRouter.of(context);
    notifier.cancel();
    unawaited(
      notifier.teardownDone
          // Release the single-flight guard unconditionally — even if teardown
          // completes with an error — so the app-bar back button can never get
          // permanently stuck disabled.
          .whenComplete(() => _isBackNavigating = false)
          .then((_) {
        if (!mounted) return;
        if (router.canPop()) {
          router.pop();
        } else {
          router.goNamed(RouteNamed.uspMenu);
        }
      }),
    );
  }

  Future<void> _returnToMenu(BuildContext context, WidgetRef ref) async {
    // Await the full teardown (in-flight drain + scope release) before
    // navigating, mirroring _returnToDashboard. cancel() tears the scope down
    // off the critical path, so awaiting cancel() alone races the unsubscribe
    // DELETE against a quick re-entry's subscribe POST.
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    await notifier.cancel();
    await notifier.teardownDone;
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNamed.uspMenu);
    }
  }
}
