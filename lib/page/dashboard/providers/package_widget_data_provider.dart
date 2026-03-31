import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-widget USP data store.
///
/// Keyed by widget ID. Stores a flat `Map<String, dynamic>` where keys
/// are full USP paths and values are the latest known values.
///
/// Updated by:
/// - Initial USP GET (populates the full snapshot)
/// - SSE ValueChange notifications (patch individual paths)
///
/// NOT autoDispose — data persists while the widget is on the dashboard.
final packageWidgetDataProvider = StateNotifierProvider.family<
    PackageWidgetDataNotifier, Map<String, dynamic>, String>(
  (ref, widgetId) => PackageWidgetDataNotifier(),
);

class PackageWidgetDataNotifier extends StateNotifier<Map<String, dynamic>> {
  PackageWidgetDataNotifier() : super(const {});

  /// Set the full data snapshot (from initial USP GET).
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
