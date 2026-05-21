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
import 'step_result_tile.dart';
import 'traceroute_detail_card.dart';

class DiagnosticResultsView extends ConsumerWidget {
  final UnifiedDiagnosticsState state;

  const DiagnosticResultsView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

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

    return AppResponsiveLayout(
      mobile: (context) => _ResultsLayout(
        state: state,
        colorScheme: colorScheme,
        errors: errors,
        warnings: warnings,
        successful: successful,
        sideBySide: false,
        onRestart: () =>
            ref.read(unifiedDiagnosticsProvider.notifier).restart(),
        onDone: () => _returnToDashboard(context, ref),
      ),
      desktop: (context) {
        // Only split into two columns when BOTH sides have meaningful content.
        // Otherwise the empty side reads as a UI bug, not a layout choice.
        final hasIssues = errors.isNotEmpty || warnings.isNotEmpty;
        final hasRecs = state.recommendations.isNotEmpty;
        return _ResultsLayout(
          state: state,
          colorScheme: colorScheme,
          errors: errors,
          warnings: warnings,
          successful: successful,
          sideBySide: hasIssues && hasRecs,
          onRestart: () =>
              ref.read(unifiedDiagnosticsProvider.notifier).restart(),
          onDone: () => _returnToDashboard(context, ref),
        );
      },
    );
  }

  Future<void> _returnToDashboard(BuildContext context, WidgetRef ref) async {
    // Await cancel so the shared diagnostic scope is released before the
    // notifier auto-disposes — without this, a quick re-entry races the
    // unsubscribe DELETE against the next acquire's subscribe POST.
    await ref.read(unifiedDiagnosticsProvider.notifier).cancel();
    if (!context.mounted) return;
    context.goNamed(RouteNamed.uspDashboard);
  }
}

class _ResultsLayout extends StatelessWidget {
  final UnifiedDiagnosticsState state;
  final ColorScheme colorScheme;
  final List<DiagnosticStepUIModel> errors;
  final List<DiagnosticStepUIModel> warnings;
  final List<DiagnosticStepUIModel> successful;
  final bool sideBySide;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  const _ResultsLayout({
    required this.state,
    required this.colorScheme,
    required this.errors,
    required this.warnings,
    required this.successful,
    required this.sideBySide,
    required this.onRestart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssues = errors.isNotEmpty || warnings.isNotEmpty;
    final hasRecs = state.recommendations.isNotEmpty;
    final tracerouteResults =
        state.results.whereType<TracerouteCheckUIModel>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (sideBySide) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _IssuesSection(
                    errors: errors,
                    warnings: warnings,
                    colorScheme: colorScheme,
                  ),
                ),
                AppGap.gutter(),
                Expanded(
                  flex: 5,
                  child: _RecommendationsSection(
                    recommendations: state.recommendations,
                  ),
                ),
              ],
            ),
          ),
          AppGap.xl(),
        ] else ...[
          if (hasIssues) ...[
            _IssuesSection(
              errors: errors,
              warnings: warnings,
              colorScheme: colorScheme,
            ),
            AppGap.lg(),
          ],
          if (hasRecs) ...[
            _RecommendationsSection(
              recommendations: state.recommendations,
            ),
            AppGap.lg(),
          ],
        ],
        if (successful.isNotEmpty) ...[
          AppExpansionPanel.single(
            headerTitle: 'Successful Checks (${successful.length})',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  successful.map((r) => StepResultTile(result: r)).toList(),
            ),
          ),
          AppGap.lg(),
        ],
        ...tracerouteResults.map((r) => TracerouteDetailCard(result: r)),
        AppGap.xxxl(),
        _ActionBar(
          onRestart: onRestart,
          onDone: onDone,
          state: state,
          fullWidth: !sideBySide,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionHeader(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppText.labelLarge(label, color: color),
    );
  }
}

class _IssuesSection extends StatelessWidget {
  final List<DiagnosticStepUIModel> errors;
  final List<DiagnosticStepUIModel> warnings;
  final ColorScheme colorScheme;

  const _IssuesSection({
    required this.errors,
    required this.warnings,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errors.isNotEmpty) ...[
          _SectionHeader('Critical Issues', color: colorScheme.error),
          ...errors
              .map((r) => StepResultTile(result: r, initiallyExpanded: true)),
          if (warnings.isNotEmpty) AppGap.lg(),
        ],
        if (warnings.isNotEmpty) ...[
          _SectionHeader('Potential Issues', color: colorScheme.tertiary),
          ...warnings
              .map((r) => StepResultTile(result: r, initiallyExpanded: true)),
        ],
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final List<RecommendationUIModel> recommendations;

  const _RecommendationsSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Recommended Actions'),
        ...recommendations.map((r) => RecommendationCard(rec: r)),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onDone;
  final UnifiedDiagnosticsState state;

  /// Mobile / single-column desktop fills width. Side-by-side desktop caps
  /// the action bar at 6/12 cols centered — full-width buttons on a wide
  /// screen look weird and hurt scan-ability.
  final bool fullWidth;

  const _ActionBar({
    required this.onRestart,
    required this.onDone,
    required this.state,
    required this.fullWidth,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AppButton.secondary(label: 'Run Again', onTap: onRestart),
        ),
        AppGap.lg(),
        Expanded(
          child: AppButton(label: 'Done', onTap: onDone),
        ),
      ],
    );
    final exportLink = AppButton.text(
      label: 'Export Diagnostics Report',
      onTap: () => DiagnosticReportExporter.shareReport(state),
    );
    final stack = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons,
        AppGap.lg(),
        Center(child: exportLink),
        AppGap.xl(),
      ],
    );
    if (fullWidth) return stack;
    return Center(
      child: SizedBox(
        width: context.colWidth(6, baseColumns: 12),
        child: stack,
      ),
    );
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            AppGap.lg(),
            Expanded(child: AppText.titleLarge(title)),
            _StatusCount(
                label: 'Failed', count: errorCount, color: colorScheme.error),
            AppGap.lg(),
            _StatusCount(
                label: 'Warning',
                count: warningCount,
                color: colorScheme.tertiary),
            AppGap.lg(),
            _StatusCount(
                label: 'Passed',
                count: passedCount,
                color: colorScheme.primary),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText.titleLarge('$count', color: color),
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
