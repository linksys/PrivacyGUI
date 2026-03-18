import 'package:privacy_gui/generated/transforms.g.dart';

/// Thin facade over codegen [Transforms] so that Views and Models
/// never import `generated/*.g.dart` directly.
class UspFormatters {
  UspFormatters._();

  static String formatBytes(int bytes) => Transforms.formatBytes(bytes);

  static String formatSpeed(double kbps, {int precision = 2}) =>
      Transforms.formatSpeed(kbps, precision: precision);

  static String formatBandwidth(double mbps, {int precision = 2}) =>
      Transforms.formatBandwidth(mbps, precision: precision);
}
