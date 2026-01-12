import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Universal Custom Layout Strategy
///
/// Handles the Unified Dynamic Grid Layout (Bento Grid) for all device types.
/// Used when "Custom Layout" is enabled in preferences.
class CustomDashboardLayoutStrategy extends DashboardLayoutStrategy {
  const CustomDashboardLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    // 1. Get grid configuration based on device type
    // Mobile: 4 cols, Tablet: 8 cols, Desktop: 12 cols
    final crossAxisCount = ctx.resolver.currentMaxColumns;
    final spacing =
        AppLayoutConfig.gutter(MediaQuery.of(ctx.context).size.width);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ctx.title,
        AppGap.xl(),
        // Bento Grid Layout using StaggeredGrid
        StaggeredGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          children: ctx.orderedVisibleCustomSpecs.map((spec) {
            final config = ctx.getConfigFor(spec);
            final child = ctx.getAtomicWidgetById(spec.id);

            if (child == null) return const SizedBox.shrink();

            final mode = config.displayMode;

            // Force full width on Mobile to prevent overflow
            // This replicates the behavior of the previous Wrap-based layout
            final isMobile = AppLayoutConfig.isMobileWidth(
                MediaQuery.of(ctx.context).size.width);

            final colSpan = isMobile
                ? crossAxisCount
                : ctx.resolver.resolveColumns(
                    spec,
                    mode,
                    availableColumns: crossAxisCount,
                    overrideColumns: config.columnSpan,
                  );

            // Calculate height in grid units (rows)
            // If null, it means intrinsic height (use .fit)
            final rowSpan = ctx.resolver.resolveGridMainAxisCellCount(
              spec,
              mode,
              availableColumns: crossAxisCount,
              overrideColumns: config.columnSpan,
            );

            if (rowSpan != null) {
              // Fixed aspect ratio or column-based height -> Force Bento Box

              // WiFi Grid manages its own internal cards/layout, so we don't wrap it in an AppCard
              if (spec.id == DashboardWidgetSpecs.wifiGrid.id) {
                return StaggeredGridTile.count(
                  crossAxisCellCount: colSpan,
                  mainAxisCellCount: rowSpan,
                  child: child,
                );
              }

              return StaggeredGridTile.count(
                crossAxisCellCount: colSpan,
                mainAxisCellCount: rowSpan,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: child, // child is now "pure content" (no card)
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              // Intrinsic height -> Fit content
              return StaggeredGridTile.fit(
                crossAxisCellCount: colSpan,
                child: child,
              );
            }
          }).toList(),
        ),
      ],
    );
  }
}
