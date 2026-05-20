import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/diagnostic_state.dart';
import '../providers/unified_diagnostics_notifier.dart';
import 'widgets/diagnostic_flow_menu.dart';
import 'widgets/diagnostic_problem_selector.dart';
import 'widgets/diagnostic_results_view.dart';
import 'widgets/diagnostic_running_view.dart';
import 'widgets/diagnostic_start_view.dart';

class UnifiedDiagnosticsView extends ConsumerWidget {
  const UnifiedDiagnosticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedDiagnosticsProvider);

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: 'Network Diagnostics',
      scrollable: true,
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
      DiagnosticStep.selectProblem => const DiagnosticProblemSelector(),
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
          AppText.titleMedium('Checking connection...'),
          AppGap.md(),
          AppText.bodySmall(
            'Running quick network check',
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
          AppText.headlineSmall('Diagnostics Complete'),
          AppGap.xxxl(),
          AppButton(
            label: 'Return to Dashboard',
            onTap: () => _returnToDashboard(context, ref),
          ),
        ],
      ),
    );
  }

  void _handleBack(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    final handledInternally = notifier.goBack();
    if (!handledInternally) {
      _returnToDashboard(context, ref);
    }
  }

  void _returnToDashboard(BuildContext context, WidgetRef ref) {
    ref.read(unifiedDiagnosticsProvider.notifier).cancel();
    context.goNamed(RouteNamed.uspDashboard);
  }
}
