import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/route/constants.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';
import '../../providers/unified_diagnostics_notifier.dart';
import '../../services/diagnostic_report_service.dart';
import 'diagnostic_result_card.dart';
import 'diagnostic_results_grid.dart';
import 'recommendation_card.dart';
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
    // Release the shared diagnostic scope before the notifier auto-disposes.
    // cancel() resets state synchronously and tears the scope down off the
    // critical path (unawaited), so awaiting cancel() alone is not enough —
    // we must also await teardownDone. Without this, a quick re-entry races
    // the unsubscribe DELETE against the next acquire's subscribe POST.
    //
    // cancel() resets state to UnifiedDiagnosticsState(), which rebuilds and
    // unmounts THIS widget. Since the awaits cross frame boundaries,
    // context.mounted is false afterward and a context-based navigation would
    // be silently dropped — so capture the router up front.
    final router = GoRouter.of(context);
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    await notifier.cancel();
    await notifier.teardownDone;
    router.goNamed(RouteNamed.uspDashboard);
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
    final hasRecs = state.recommendations.isNotEmpty;
    final tracerouteResults =
        state.results.whereType<TracerouteCheckUIModel>().toList();
    final isSingleFlow = state.flow != null;
    final allResults = [...errors, ...warnings, ...successful];

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
        // Single flow: full-width cards stacked
        // Full diagnostic: responsive grid
        if (isSingleFlow)
          ...allResults.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DiagnosticResultCard(result: r),
              ))
        else
          DiagnosticResultsGrid(results: allResults),
        if (hasRecs) ...[
          AppGap.lg(),
          _RecommendationsSection(recommendations: state.recommendations),
        ],
        if (tracerouteResults.isNotEmpty) ...[
          AppGap.lg(),
          ...tracerouteResults.map((r) => TracerouteDetailCard(result: r)),
        ],
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
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppText.labelLarge(label),
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
        _SectionHeader(loc(context).recommendedActions),
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
          child: AppButton.secondary(
              label: loc(context).runAgain,
              identifier: 'diagnostic-run-again',
              onTap: onRestart),
        ),
        AppGap.lg(),
        Expanded(
          child: AppButton(
              label: loc(context).done,
              identifier: 'diagnostic-done',
              onTap: onDone),
        ),
      ],
    );
    final exportLink = AppButton.text(
      label: loc(context).exportDiagnosticsReport,
      identifier: 'diagnostic-export',
      onTap: () => const DiagnosticReportService().share(state),
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
        ? (Icons.error, colorScheme.error, loc(context).issuesFound)
        : hasWarnings
            ? (
                Icons.warning,
                colorScheme.tertiary,
                loc(context).potentialIssues
              )
            : (
                Icons.check_circle,
                colorScheme.primary,
                loc(context).allSystemsOk
              );

    return AppCard(
      identifier: 'diagnostic-results',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        // A `Wrap` of two groups rather than one flat `Row` (#1602). The `Row`
        // carried a 40px icon, three intrinsic-width counts and two gaps besides
        // the title, so at the 320px floor the `Expanded` title collapsed to zero
        // and the fixed children still went over — by up to 120px, in every locale
        // and on every results state including `en`. `spaceBetween` keeps the wide
        // layout the `Row` had (title left, counts hard right, one line) and lets
        // the counts drop to a second line instead of overflowing.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.md,
          children: [
            // `Row`s inside a `Wrap` are handed the line's width as their
            // constraint, so the `Flexible` below wraps the title rather than
            // overflowing it — and each group still travels as one unit.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: color),
                AppGap.lg(),
                Flexible(child: AppText.titleLarge(title)),
              ],
            ),
            // A `Wrap` too, and the reason is worth keeping: moving the counts
            // onto their own run fixed 221 of the 302 red cells, and the
            // remaining 81 moved to *this* group — three labels of
            // `Fehlgeschlagen` / `Warnung` / `Bestanden` length do not fit a
            // 320px line either, over by up to 64px in 9 locales across every
            // results state. `spacing` replaces the two `AppGap.lg()`s so the
            // gap does not survive a line break as leading whitespace.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusCount(
                    label: loc(context).failed,
                    count: errorCount,
                    color: colorScheme.error),
                _StatusCount(
                    label: loc(context).warning,
                    count: warningCount,
                    color: colorScheme.tertiary),
                _StatusCount(
                    label: loc(context).passed,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText.titleLarge('$count', color: color),
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
