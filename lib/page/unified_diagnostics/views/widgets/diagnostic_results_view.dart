import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/route/constants.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';
import '../../providers/unified_diagnostics_notifier.dart';
import 'diagnostic_report_export.dart';
import 'recommendation_card.dart';
import 'speed_test_result_card.dart';
import 'step_result_tile.dart';
import 'traceroute_detail_card.dart';

class DiagnosticResultsView extends ConsumerWidget {
  final UnifiedDiagnosticsState state;

  const DiagnosticResultsView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Categorize results
    final errors = state.results
        .where((r) => r.severity == DiagnosticSeverity.error)
        .toList();
    final warnings = state.results
        .where((r) => r.severity == DiagnosticSeverity.warning)
        .toList();
    final successful = state.results
        .where((r) =>
            r.severity == DiagnosticSeverity.ok ||
            r.severity == DiagnosticSeverity.skipped)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Header Card
        _SummaryCard(
          hasErrors: errors.isNotEmpty,
          hasWarnings: warnings.isNotEmpty,
          errorCount: errors.length,
          warningCount: warnings.length,
          passedCount: successful
              .where((r) => r.severity == DiagnosticSeverity.ok)
              .length,
        ),
        AppGap.xl(),

        // Speed test results (if available) - Integrated into results flow
        if (state.speedTest != null) ...[
          SpeedTestResultCard(speedTest: state.speedTest!),
          AppGap.lg(),
        ],

        // 1. Critical Issues (Errors)
        if (errors.isNotEmpty) ...[
          AppText.labelLarge('Critical Issues', color: colorScheme.error),
          AppGap.md(),
          ...errors
              .map((r) => StepResultTile(result: r, initiallyExpanded: true)),
          AppGap.lg(),
        ],

        // 2. Potential Issues (Warnings)
        if (warnings.isNotEmpty) ...[
          AppText.labelLarge('Potential Issues', color: colorScheme.tertiary),
          AppGap.md(),
          ...warnings
              .map((r) => StepResultTile(result: r, initiallyExpanded: true)),
          AppGap.lg(),
        ],

        // 3. Recommendations
        if (state.recommendations.isNotEmpty) ...[
          AppText.labelLarge('Recommended Actions'),
          AppGap.md(),
          ...state.recommendations.map((r) => RecommendationCard(rec: r)),
          AppGap.xl(),
        ],

        // 4. Successful Checks (Collapsed by default)
        if (successful.isNotEmpty) ...[
          AppExpansionPanel.single(
            headerTitle: 'Successful Checks (${successful.length})',
            content: Column(
              children:
                  successful.map((r) => StepResultTile(result: r)).toList(),
            ),
          ),
          AppGap.lg(),
        ],

        // Traceroute details (if available)
        ...state.results
            .whereType<TracerouteCheckUIModel>()
            .map((r) => TracerouteDetailCard(result: r)),
        AppGap.xxxl(),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AppButton.secondary(
                label: 'Run Again',
                onTap: () =>
                    ref.read(unifiedDiagnosticsProvider.notifier).restart(),
              ),
            ),
            AppGap.lg(),
            Expanded(
              child: AppButton(
                label: 'Done',
                onTap: () => _returnToDashboard(context, ref),
              ),
            ),
          ],
        ),
        AppGap.lg(),
        Center(
          child: AppButton.text(
            label: 'Export Diagnostics Report',
            onTap: () => DiagnosticReportExporter.shareReport(state),
          ),
        ),
        AppGap.xl(),
      ],
    );
  }

  void _returnToDashboard(BuildContext context, WidgetRef ref) {
    ref.read(unifiedDiagnosticsProvider.notifier).cancel();
    context.goNamed(RouteNamed.uspDashboard);
  }
}

class _SummaryCard extends StatelessWidget {
  final bool hasErrors;
  final bool hasWarnings;
  final int errorCount;
  final int warningCount;
  final int passedCount;

  const _SummaryCard({
    required this.hasErrors,
    required this.hasWarnings,
    required this.errorCount,
    required this.warningCount,
    required this.passedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color, title) = hasErrors
        ? (Icons.error, colorScheme.error, 'Issues Found')
        : hasWarnings
            ? (Icons.warning, colorScheme.tertiary, 'Potential Issues')
            : (Icons.check_circle, colorScheme.primary, 'All Systems OK');

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            AppGap.md(),
            AppText.headlineSmall(title),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusCount(
                    label: 'Failed',
                    count: errorCount,
                    color: colorScheme.error),
                _StatusCount(
                    label: 'Warning',
                    count: warningCount,
                    color: colorScheme.tertiary),
                _StatusCount(
                    label: 'Passed',
                    count: passedCount,
                    color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.titleLarge('$count', color: color),
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
