import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_result.dart';
import 'diagnostic_result_card.dart';

/// Responsive grid layout for diagnostic result cards.
///
/// - Issues (warning/error) are shown at top as full-width cards with details
/// - OK/skipped items are shown in a compact grid below
class DiagnosticResultsGrid extends StatelessWidget {
  final List<DiagnosticStepUIModel> results;

  const DiagnosticResultsGrid({super.key, required this.results});

  static const _minCardWidth = 280.0;
  static const _maxCardWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    // Separate issues from OK items
    final issues = results
        .where((r) =>
            r.severity == DiagnosticSeverity.warning ||
            r.severity == DiagnosticSeverity.error)
        .toList();
    final okItems = results
        .where((r) =>
            r.severity == DiagnosticSeverity.ok ||
            r.severity == DiagnosticSeverity.skipped)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Issues section - full width cards with details
        if (issues.isNotEmpty) ...[
          for (final issue in issues) ...[
            DiagnosticIssueCard(result: issue),
            AppGap.md(),
          ],
          AppGap.md(),
        ],
        // OK items - compact grid
        if (okItems.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final cardsPerRow =
                  (availableWidth / _minCardWidth).floor().clamp(1, 3);
              final cardWidth =
                  (availableWidth - (cardsPerRow - 1) * AppSpacing.md) /
                      cardsPerRow;
              final constrainedWidth =
                  cardWidth.clamp(_minCardWidth, _maxCardWidth);

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: okItems.map((result) {
                  return SizedBox(
                    width: cardsPerRow == 1 ? availableWidth : constrainedWidth,
                    child: DiagnosticResultCard(result: result),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

/// Single full-width card for individual diagnostic flow results.
class SingleDiagnosticResultCard extends StatelessWidget {
  final DiagnosticStepUIModel result;

  const SingleDiagnosticResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DiagnosticResultCard(result: result);
  }
}
