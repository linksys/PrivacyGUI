import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preserves the selected tab index for tabbed dashboard cards across rebuilds.
///
/// Keyed by card widget ID (e.g. 'system_status', 'device_analytics').
/// NOT autoDispose — state persists when cards scroll out of view.
final cardTabIndexProvider = StateProvider.family<int, String>((_, __) => 0);
