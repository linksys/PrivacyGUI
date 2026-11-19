import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-widget data cache.
///
/// Keyed by widget ID. Stores a flat `Map<String, dynamic>` whose keys are
/// full USP paths (USP data source) or mapping keys (HTTP data source), and
/// whose values are the latest known values.
///
/// Written by `packageWidgetLiveProvider` (the initial fetch, SSE value
/// changes, the HTTP poll and the `refresh_data` action) and cleared by the
/// loader when the widget's package is removed.
///
/// NOT autoDispose, and `build` does no I/O: the data outlives the card, so a
/// card that comes back to the dashboard shows its last data at once while the
/// live notifier refetches, and the loader can clear a removed widget without
/// starting anything for it.
final packageWidgetDataProvider = NotifierProvider.family<
    PackageWidgetDataNotifier, Map<String, dynamic>, String>(
  PackageWidgetDataNotifier.new,
);

class PackageWidgetDataNotifier
    extends FamilyNotifier<Map<String, dynamic>, String> {
  @override
  Map<String, dynamic> build(String widgetId) => const {};

  /// Set the full data snapshot (from an initial fetch or a refresh).
  void setAll(Map<String, dynamic> data) {
    state = Map.from(data);
  }

  /// Patch a single path-value pair (from SSE ValueChange).
  void updatePath(String path, dynamic value) {
    state = {...state, path: value};
  }

  /// Clear all data (on widget removal).
  void clear() {
    state = const {};
  }
}
