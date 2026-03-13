import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the top bar and bottom navigation bar are visible.
///
/// Toggled by scroll direction in the dashboard:
/// - Scroll down → hide (false)
/// - Scroll up → show (true)
final uspBarsVisibleProvider = StateProvider<bool>((ref) => true);
