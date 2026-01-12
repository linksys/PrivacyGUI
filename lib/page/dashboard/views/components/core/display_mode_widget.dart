import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'dashboard_loading_wrapper.dart';

/// Mixin for widgets that support display modes.
///
/// Provides a common interface for Compact/Normal/Expanded rendering.
mixin DisplayModeAware {
  DisplayMode get displayMode;
}

/// Base class for atomic dashboard widgets (stateless).
///
/// Provides:
/// - Unified displayMode parameter
/// - Automatic loading wrapper integration
/// - Standard build pattern with mode-specific builders
///
/// Usage:
/// ```dart
/// class CustomInternetStatus extends DisplayModeConsumerWidget {
///   const CustomInternetStatus({super.key, super.displayMode});
///
///   @override
///   double getLoadingHeight(DisplayMode mode) => switch (mode) {
///     DisplayMode.compact => 40,
///     DisplayMode.normal => 80,
///     DisplayMode.expanded => 100,
///   };
///
///   @override
///   Widget buildCompactView(BuildContext context, WidgetRef ref) {
///     // Compact implementation
///   }
///   // ... other build methods
/// }
/// ```
abstract class DisplayModeConsumerWidget extends ConsumerWidget
    with DisplayModeAware {
  const DisplayModeConsumerWidget({
    super.key,
    this.displayMode = DisplayMode.normal,
  });

  @override
  final DisplayMode displayMode;

  /// Loading height for each display mode.
  double getLoadingHeight(DisplayMode mode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: getLoadingHeight(displayMode),
      builder: (context, ref) => buildContent(context, ref),
    );
  }

  /// Build content based on current displayMode.
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return switch (displayMode) {
      DisplayMode.compact => buildCompactView(context, ref),
      DisplayMode.normal => buildNormalView(context, ref),
      DisplayMode.expanded => buildExpandedView(context, ref),
    };
  }

  /// Override to build compact view.
  Widget buildCompactView(BuildContext context, WidgetRef ref);

  /// Override to build normal view.
  Widget buildNormalView(BuildContext context, WidgetRef ref);

  /// Override to build expanded view.
  Widget buildExpandedView(BuildContext context, WidgetRef ref);
}

/// Base class for atomic dashboard widgets (stateful).
///
/// Use when your widget needs local state (e.g., tooltip visibility).
abstract class DisplayModeConsumerStatefulWidget extends ConsumerStatefulWidget
    with DisplayModeAware {
  const DisplayModeConsumerStatefulWidget({
    super.key,
    this.displayMode = DisplayMode.normal,
  });

  @override
  final DisplayMode displayMode;
}

/// Mixin for State classes of DisplayModeConsumerStatefulWidget.
///
/// Usage:
/// ```dart
/// class _CustomWiFiGridState extends ConsumerState<CustomWiFiGrid>
///     with DisplayModeStateMixin<CustomWiFiGrid> {
///
///   @override
///   double getLoadingHeight(DisplayMode mode) => 200;
///
///   @override
///   Widget buildCompactView(BuildContext context, WidgetRef ref) {
///     // implementation
///   }
///   // ...
/// }
/// ```
mixin DisplayModeStateMixin<T extends DisplayModeConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Loading height for each display mode.
  double getLoadingHeight(DisplayMode mode);

  @override
  Widget build(BuildContext context) {
    return DashboardLoadingWrapper(
      loadingHeight: getLoadingHeight(widget.displayMode),
      builder: (context, ref) => buildContent(context, ref),
    );
  }

  /// Build content based on current displayMode.
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return switch (widget.displayMode) {
      DisplayMode.compact => buildCompactView(context, ref),
      DisplayMode.normal => buildNormalView(context, ref),
      DisplayMode.expanded => buildExpandedView(context, ref),
    };
  }

  /// Override to build compact view.
  Widget buildCompactView(BuildContext context, WidgetRef ref);

  /// Override to build normal view.
  Widget buildNormalView(BuildContext context, WidgetRef ref);

  /// Override to build expanded view.
  Widget buildExpandedView(BuildContext context, WidgetRef ref);
}
