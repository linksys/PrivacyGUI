import 'package:flutter/widgets.dart';
import 'dashboard_layout_context.dart';

/// Abstract strategy interface for dashboard layouts.
///
/// Each concrete implementation handles a specific [DashboardLayoutVariant]
/// and is responsible for arranging widgets according to that layout's rules.
///
/// Strategies are stateless singletons - all required data is passed via
/// [DashboardLayoutContext].
abstract class DashboardLayoutStrategy {
  const DashboardLayoutStrategy();

  /// Builds the layout widget tree using the provided context.
  ///
  /// The context contains:
  /// - Pre-built atomic widgets (IoC pattern)
  /// - Layout configuration (hasLanPort, isHorizontalLayout)
  /// - BuildContext for responsive calculations (colWidth)
  Widget build(DashboardLayoutContext context);
}
