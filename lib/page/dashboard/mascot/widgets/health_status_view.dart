import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../health/health_dimension.dart';
import '../health/health_dimension_registry.dart';
import '../health/health_score.dart';
import '../health/system_health_provider.dart';

/// Callback when a dimension is tapped.
typedef OnDimensionTap = void Function(HealthDimensionType dimension);

/// Health status view with problem-first display.
///
/// - When all healthy: Shows "All systems healthy" with summary
/// - When issues exist: Highlights problems, collapses healthy items
/// - Tap dimension to expand details
class HealthStatusView extends ConsumerWidget {
  final OnDimensionTap? onDimensionTap;
  final Color textColor;

  const HealthStatusView({
    super.key,
    this.onDimensionTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(systemHealthProvider);

    return healthState.when(
      data: (state) => _buildStatusView(context, ref, state),
      loading: () => _buildLoading(),
      error: (_, __) => AppText.bodyMedium(
        'Unable to load health data',
        color: textColor,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildStatusView(
    BuildContext context,
    WidgetRef ref,
    SystemHealthState state,
  ) {
    final evalContext = ref.read(healthEvaluationContextProvider);

    final dimensions = HealthDimensions.all;
    if (dimensions.isEmpty) {
      return AppText.bodyMedium('No dimensions', color: textColor);
    }

    // Separate healthy from problematic
    final problematic = <HealthDimension>[];
    final healthy = <HealthDimension>[];

    for (final dim in dimensions) {
      final score = state[dim.type]?.score ?? 100;
      if (score < 80) {
        problematic.add(dim);
      } else {
        healthy.add(dim);
      }
    }

    // Sort problematic by score (worst first)
    problematic.sort((a, b) {
      final scoreA = state[a.type]?.score ?? 100;
      final scoreB = state[b.type]?.score ?? 100;
      return scoreA.compareTo(scoreB);
    });

    if (problematic.isEmpty) {
      return _buildAllHealthy(context, ref, healthy, state, evalContext);
    }

    return _buildWithIssues(
        context, ref, problematic, healthy, state, evalContext);
  }

  Widget _buildAllHealthy(
    BuildContext context,
    WidgetRef ref,
    List<HealthDimension> dimensions,
    SystemHealthState state,
    HealthEvaluationContext evalContext,
  ) {
    final cs = Theme.of(context).colorScheme;

    // Build summary text
    final summaryParts = <String>[];
    for (final dim in dimensions) {
      final summary = dim.getSummary(evalContext);
      if (summary.items.isNotEmpty) {
        final firstItem = summary.items.first;
        summaryParts.add(firstItem.value);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.titleSmall(
                'All systems healthy',
                color: textColor,
              ),
            ),
          ],
        ),
        if (summaryParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: AppText.bodySmall(
              summaryParts.take(3).join(' · '),
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildHealthyChips(context, dimensions, state),
      ],
    );
  }

  Widget _buildWithIssues(
    BuildContext context,
    WidgetRef ref,
    List<HealthDimension> problematic,
    List<HealthDimension> healthy,
    SystemHealthState state,
    HealthEvaluationContext evalContext,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Problematic items (expanded)
        ...problematic.map((dim) => _buildProblemItem(
              context,
              dim,
              state[dim.type],
              dim.getSummary(evalContext),
            )),

        if (healthy.isNotEmpty) ...[
          const SizedBox(height: 8),
          Divider(color: textColor.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 8),
          _buildHealthyChips(context, healthy, state),
        ],
      ],
    );
  }

  Widget _buildProblemItem(
    BuildContext context,
    HealthDimension dimension,
    HealthScore? score,
    DimensionSummary summary,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tier = score?.tier ?? HealthTier.excellent;
    final tierColor = NetworkHealthHelpers.tierColor(tier, cs);
    final icon = tier == HealthTier.critical || tier == HealthTier.poor
        ? Icons.error
        : Icons.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => onDimensionTap?.call(dimension.type),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: tierColor, size: 18),
              const SizedBox(width: 8),
              AppText.labelLarge(
                dimension.displayName,
                color: tierColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppText.bodySmall(
                  summary.status,
                  color: textColor.withValues(alpha: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textColor.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthyChips(
    BuildContext context,
    List<HealthDimension> dimensions,
    SystemHealthState state,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: dimensions.map((dim) {
        return InkWell(
          onTap: () => onDimensionTap?.call(dim.type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 12,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                AppText.labelSmall(
                  dim.displayName,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
