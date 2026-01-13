import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Universal Custom Layout Strategy
///
/// Handles the Unified Dynamic Grid Layout (Wrap-based) for all device types.
/// Used when "Custom Layout" is enabled in preferences.
class CustomDashboardLayoutStrategy extends DashboardLayoutStrategy {
  const CustomDashboardLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ctx.title,
        AppGap.xl(),
        // Flexible Grid Layout using Wrap
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: ctx.orderedVisibleWidgets,
          ),
        ),
      ],
    );
  }
}
