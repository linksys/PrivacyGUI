import 'dart:ui' show Color;

/// The physical colors of the router's status LED (Pinnacle LED spec
/// r20260109a). These depict hardware, so unlike the rest of Instant-Test
/// they stay fixed across dark mode and custom theme colors.
abstract final class RouterLightColor {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF1E6FFF);
  static const red = Color(0xFFE53935);
  static const yellow = Color(0xFFFBC02D);
  static const green = Color(0xFF43A047);
  static const off = Color(0x00000000);
}
