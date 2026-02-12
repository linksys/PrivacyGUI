import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

/// Utility class for calculating speed test gauge parameters.
///
/// This class provides helper methods to determine dynamic gauge bounds and markers
/// based on historical speed test results. All methods are static and pure functions.
class SpeedTestGaugeUtils {
  // Private constructor to prevent instantiation
  SpeedTestGaugeUtils._();

  /// Calculates the maximum speed (in Mbps) from historical speed test results.
  ///
  /// This method examines both [state.historicalSpeedTests] and [state.latestSpeedTest]
  /// to find the highest download or upload speed recorded.
  ///
  /// **Parameters:**
  /// - [state]: The current [HealthCheckState] containing speed test history
  ///
  /// **Returns:**
  /// - The maximum speed in Mbps (converted from Kbps)
  /// - Returns 100.0 as default if no valid history exists
  ///
  /// **Examples:**
  /// ```dart
  /// final maxSpeed = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);
  /// // Returns 150.5 if the fastest recorded speed was 150.5 Mbps
  /// ```
  static double calculateMaxHistoricalSpeed(HealthCheckState state) {
    final allTests = <SpeedTestUIModel>[];

    // Include historical tests
    if (state.historicalSpeedTests.isNotEmpty) {
      allTests.addAll(state.historicalSpeedTests);
    }

    // Include latest test if it's not already in historical
    if (state.latestSpeedTest != null &&
        !state.historicalSpeedTests.contains(state.latestSpeedTest)) {
      allTests.add(state.latestSpeedTest!);
    }

    if (allTests.isEmpty) {
      return 100.0; // Default to 100 Mbps if no history
    }

    double maxSpeed = 0.0;

    for (final test in allTests) {
      // Download speed (convert Kbps to Mbps)
      if (test.downloadBandwidthKbps != null &&
          test.downloadBandwidthKbps! > 0) {
        final downloadMbps = test.downloadBandwidthKbps! / 1024.0;
        if (downloadMbps > maxSpeed) {
          maxSpeed = downloadMbps;
        }
      }

      // Upload speed (convert Kbps to Mbps)
      if (test.uploadBandwidthKbps != null && test.uploadBandwidthKbps! > 0) {
        final uploadMbps = test.uploadBandwidthKbps! / 1024.0;
        if (uploadMbps > maxSpeed) {
          maxSpeed = uploadMbps;
        }
      }
    }

    // If all values were null or zero, return default
    return maxSpeed > 0 ? maxSpeed : 100.0;
  }

  /// Rounds up a speed value to the nearest hundred (ceiling).
  ///
  /// This ensures gauge markers are at clean, readable intervals.
  /// The minimum return value is always 100.0.
  ///
  /// **Parameters:**
  /// - [speed]: The speed value in Mbps to round up
  ///
  /// **Returns:**
  /// - The rounded value, minimum 100.0
  ///
  /// **Examples:**
  /// ```dart
  /// SpeedTestGaugeUtils.roundUpToHundred(89.0);   // Returns 100.0
  /// SpeedTestGaugeUtils.roundUpToHundred(345.0);  // Returns 400.0
  /// SpeedTestGaugeUtils.roundUpToHundred(1234.0); // Returns 1300.0
  /// SpeedTestGaugeUtils.roundUpToHundred(56.0);   // Returns 100.0 (minimum)
  /// ```
  static double roundUpToHundred(double speed) {
    // Ensure minimum is 100
    if (speed < 100) {
      return 100.0;
    }

    // Round up to nearest hundred
    return (speed / 100).ceil() * 100.0;
  }

  /// Calculates the dynamic upper bound for the speed test gauge.
  ///
  /// This combines [calculateMaxHistoricalSpeed] and [roundUpToHundred]
  /// to determine an appropriate maximum value for the gauge display.
  ///
  /// **Parameters:**
  /// - [state]: The current [HealthCheckState] containing speed test history
  ///
  /// **Returns:**
  /// - The calculated upper bound in Mbps (minimum 100.0, rounded to hundreds)
  ///
  /// **Examples:**
  /// ```dart
  /// final upperBound = SpeedTestGaugeUtils.calculateGaugeUpperBound(state);
  /// // If max historical speed is 234 Mbps, returns 300.0
  /// ```
  static double calculateGaugeUpperBound(HealthCheckState state) {
    final maxHistorical = calculateMaxHistoricalSpeed(state);
    return roundUpToHundred(maxHistorical);
  }

  /// Generates appropriate marker values for the speed gauge.
  ///
  /// The markers are distributed to provide meaningful reference points based
  /// on the upper bound. Different ranges use different marker intervals:
  ///
  /// - **100 Mbps**: `[0, 1, 5, 10, 20, 30, 50, 75, 100]`
  /// - **100-200 Mbps**: `[0, 10, 20, 30, 50, 75, 100, 150, upperBound]`
  /// - **200-500 Mbps**: `[0, 50, 100, 150, ..., upperBound]` (50 Mbps intervals)
  /// - **500-1000 Mbps**: `[0, 100, 200, ..., 500, 750, upperBound]` (100 Mbps intervals)
  /// - **1000+ Mbps**: `[0, 200, 400, ..., upperBound]` (200 Mbps intervals)
  ///
  /// **Small gauge mode** (when [isSmallGauge] is true): Returns only `[0, upperBound]`
  ///
  /// **Parameters:**
  /// - [upperBound]: The maximum value for the gauge in Mbps
  /// - [isSmallGauge]: If true, returns simplified markers for compact display (default: false)
  ///
  /// **Returns:**
  /// - A sorted list of marker values in ascending order
  ///
  /// **Examples:**
  /// ```dart
  /// SpeedTestGaugeUtils.generateMarkers(100.0);
  /// // Returns [0, 1, 5, 10, 20, 30, 50, 75, 100]
  ///
  /// SpeedTestGaugeUtils.generateMarkers(300.0);
  /// // Returns [0, 50, 100, 150, 200, 250, 300]
  ///
  /// SpeedTestGaugeUtils.generateMarkers(300.0, isSmallGauge: true);
  /// // Returns [0, 300]
  /// ```
  static List<double> generateMarkers(
    double upperBound, {
    bool isSmallGauge = false,
  }) {
    if (isSmallGauge) {
      return [0, upperBound];
    }

    if (upperBound <= 100) {
      // Default case: 0-100 Mbps
      return const [0, 1, 5, 10, 20, 30, 50, 75, 100];
    } else if (upperBound <= 200) {
      // 100-200 Mbps range
      return [0, 10, 20, 30, 50, 75, 100, 150, upperBound];
    } else if (upperBound <= 500) {
      // 200-500 Mbps range
      // Generate markers at 50 Mbps intervals up to 300, then 100 Mbps intervals
      final markers = <double>[0];
      for (double i = 50; i <= 300; i += 50) {
        markers.add(i);
      }
      for (double i = 400; i < upperBound; i += 100) {
        markers.add(i);
      }
      markers.add(upperBound);
      return markers;
    } else if (upperBound <= 1000) {
      // 500-1000 Mbps range
      // Generate markers at 100 Mbps intervals, with an extra marker at 750 if applicable
      final markers = <double>[0];
      for (double i = 100; i <= 500; i += 100) {
        markers.add(i);
      }
      // Only add 750 if upperBound is >= 750 to maintain sorted order
      if (upperBound >= 750) {
        markers.add(750);
      }
      if (upperBound != 1000) {
        markers.add(upperBound);
      } else {
        markers.add(1000);
      }
      return markers;
    } else {
      // 1000+ Mbps range
      // Generate markers at 200 Mbps intervals
      final markers = <double>[0];
      for (double i = 200; i < upperBound; i += 200) {
        markers.add(i);
      }
      markers.add(upperBound);
      return markers;
    }
  }
}
