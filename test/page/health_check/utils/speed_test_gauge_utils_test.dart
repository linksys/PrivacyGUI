import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/utils/speed_test_gauge_utils.dart';

void main() {
  group('SpeedTestGaugeUtils', () {
    group('calculateMaxHistoricalSpeed', () {
      test(
          'returns 100.0 when historicalSpeedTests is empty and latestSpeedTest is null',
          () {
        // Arrange
        final state = HealthCheckState.init();

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, 100.0);
      });

      test('returns max download speed when it is the highest value', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '150.5',
              downloadUnit: 'Mbps',
              uploadSpeed: '50.2',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: 154112, // 150.5 * 1024
              uploadBandwidthKbps: 51404, // 50.2 * 1024
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(150.5, 0.1));
      });

      test('returns max upload speed when it is the highest value', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '50.2',
              downloadUnit: 'Mbps',
              uploadSpeed: '200.8',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: 51404, // 50.2 * 1024
              uploadBandwidthKbps: 205619, // 200.8 * 1024
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(200.8, 0.1));
      });

      test('returns maximum across multiple historical tests', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '100',
              downloadUnit: 'Mbps',
              uploadSpeed: '50',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'test1',
              serverId: '1',
              downloadBandwidthKbps: 102400, // 100 * 1024
              uploadBandwidthKbps: 51200, // 50 * 1024
            ),
            SpeedTestUIModel(
              downloadSpeed: '234.5',
              downloadUnit: 'Mbps',
              uploadSpeed: '75',
              uploadUnit: 'Mbps',
              latency: '12',
              timestamp: 'test2',
              serverId: '2',
              downloadBandwidthKbps: 240128, // 234.5 * 1024
              uploadBandwidthKbps: 76800, // 75 * 1024
            ),
            SpeedTestUIModel(
              downloadSpeed: '150',
              downloadUnit: 'Mbps',
              uploadSpeed: '60',
              uploadUnit: 'Mbps',
              latency: '8',
              timestamp: 'test3',
              serverId: '1',
              downloadBandwidthKbps: 153600, // 150 * 1024
              uploadBandwidthKbps: 61440, // 60 * 1024
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(234.5, 0.1));
      });

      test(
          'includes latestSpeedTest in calculation when not in historical list',
          () {
        // Arrange
        const latestTest = SpeedTestUIModel(
          downloadSpeed: '300',
          downloadUnit: 'Mbps',
          uploadSpeed: '100',
          uploadUnit: 'Mbps',
          latency: '15',
          timestamp: 'latest',
          serverId: '3',
          downloadBandwidthKbps: 307200, // 300 * 1024
          uploadBandwidthKbps: 102400, // 100 * 1024
        );

        final state = HealthCheckState.init().copyWith(
          latestSpeedTest: () => latestTest,
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '150',
              downloadUnit: 'Mbps',
              uploadSpeed: '50',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'old',
              serverId: '1',
              downloadBandwidthKbps: 153600,
              uploadBandwidthKbps: 51200,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(300.0, 0.1));
      });

      test('does not duplicate latestSpeedTest if already in historical list',
          () {
        // Arrange
        const testResult = SpeedTestUIModel(
          downloadSpeed: '200',
          downloadUnit: 'Mbps',
          uploadSpeed: '80',
          uploadUnit: 'Mbps',
          latency: '10',
          timestamp: 'same',
          serverId: '1',
          downloadBandwidthKbps: 204800,
          uploadBandwidthKbps: 81920,
        );

        final state = HealthCheckState.init().copyWith(
          latestSpeedTest: () => testResult,
          historicalSpeedTests: const [testResult], // Same instance in both
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(200.0, 0.1));
      });

      test('returns 100.0 when all bandwidth values are null', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '--',
              downloadUnit: 'Mbps',
              uploadSpeed: '--',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: null,
              uploadBandwidthKbps: null,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, 100.0);
      });

      test('returns 100.0 when all bandwidth values are zero', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '0.0',
              downloadUnit: 'Mbps',
              uploadSpeed: '0.0',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: 0,
              uploadBandwidthKbps: 0,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, 100.0);
      });

      test('handles mix of null and valid values correctly', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '--',
              downloadUnit: 'Mbps',
              uploadSpeed: '75',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'test1',
              serverId: '1',
              downloadBandwidthKbps: null,
              uploadBandwidthKbps: 76800, // 75 * 1024
            ),
            SpeedTestUIModel(
              downloadSpeed: '120',
              downloadUnit: 'Mbps',
              uploadSpeed: '--',
              uploadUnit: 'Mbps',
              latency: '12',
              timestamp: 'test2',
              serverId: '2',
              downloadBandwidthKbps: 122880, // 120 * 1024
              uploadBandwidthKbps: null,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateMaxHistoricalSpeed(state);

        // Assert
        expect(result, closeTo(120.0, 0.1));
      });
    });

    group('roundUpToHundred', () {
      test('returns 100.0 for values less than 100', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(0), 100.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(50), 100.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(89), 100.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(99.9), 100.0);
      });

      test('returns 100.0 for exactly 100', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(100), 100.0);
      });

      test('rounds up to nearest hundred for values in 100-200 range', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(101), 200.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(150), 200.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(199), 200.0);
      });

      test('returns exact hundred for values that are already exact hundreds',
          () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(200), 200.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(500), 500.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(1000), 1000.0);
      });

      test('rounds up correctly for mid-range values', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(234), 300.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(345), 400.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(456.7), 500.0);
      });

      test('rounds up correctly for large values', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(1234), 1300.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(5678.9), 5700.0);
      });

      test('handles decimal values correctly', () {
        expect(SpeedTestGaugeUtils.roundUpToHundred(150.1), 200.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(299.9), 300.0);
        expect(SpeedTestGaugeUtils.roundUpToHundred(100.01), 200.0);
      });
    });

    group('calculateGaugeUpperBound', () {
      test('returns at least 100 for empty state', () {
        // Arrange
        final state = HealthCheckState.init();

        // Act
        final result = SpeedTestGaugeUtils.calculateGaugeUpperBound(state);

        // Assert
        expect(result, 100.0);
      });

      test('rounds up max historical speed to nearest hundred', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '234',
              downloadUnit: 'Mbps',
              uploadSpeed: '100',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: 239616, // 234 * 1024
              uploadBandwidthKbps: 102400,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateGaugeUpperBound(state);

        // Assert
        expect(result, 300.0);
      });

      test(
          'integrates calculateMaxHistoricalSpeed and roundUpToHundred correctly',
          () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '567',
              downloadUnit: 'Mbps',
              uploadSpeed: '150',
              uploadUnit: 'Mbps',
              latency: '8',
              timestamp: 'now',
              serverId: '2',
              downloadBandwidthKbps: 580608, // 567 * 1024
              uploadBandwidthKbps: 153600,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateGaugeUpperBound(state);

        // Assert
        // Max speed is 567 Mbps, rounded up to 600
        expect(result, 600.0);
      });

      test('handles edge case where max speed is exactly a hundred', () {
        // Arrange
        final state = HealthCheckState.init().copyWith(
          historicalSpeedTests: const [
            SpeedTestUIModel(
              downloadSpeed: '500',
              downloadUnit: 'Mbps',
              uploadSpeed: '200',
              uploadUnit: 'Mbps',
              latency: '10',
              timestamp: 'now',
              serverId: '1',
              downloadBandwidthKbps: 512000, // 500 * 1024
              uploadBandwidthKbps: 204800,
            ),
          ],
        );

        // Act
        final result = SpeedTestGaugeUtils.calculateGaugeUpperBound(state);

        // Assert
        expect(result, 500.0);
      });
    });

    group('generateMarkers', () {
      group('small gauge mode', () {
        test('returns only start and end markers when isSmallGauge is true',
            () {
          expect(
            SpeedTestGaugeUtils.generateMarkers(100, isSmallGauge: true),
            [0, 100],
          );
          expect(
            SpeedTestGaugeUtils.generateMarkers(500, isSmallGauge: true),
            [0, 500],
          );
          expect(
            SpeedTestGaugeUtils.generateMarkers(1200, isSmallGauge: true),
            [0, 1200],
          );
        });
      });

      group('100 Mbps range', () {
        test('returns detailed markers for 100 Mbps upper bound', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(100);
          expect(markers, const [0, 1, 5, 10, 20, 30, 50, 75, 100]);
        });

        test('returns detailed markers for upper bound less than 100', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(50);
          expect(markers, const [0, 1, 5, 10, 20, 30, 50, 75, 100]);
        });
      });

      group('100-200 Mbps range', () {
        test('returns appropriate markers for 200 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(200);
          expect(markers, [0, 10, 20, 30, 50, 75, 100, 150, 200]);
        });

        test('returns appropriate markers for 150 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(150);
          expect(markers, [0, 10, 20, 30, 50, 75, 100, 150, 150]);
          // Note: upperBound appears twice - this is existing behavior
        });
      });

      group('200-500 Mbps range', () {
        test('returns 50 Mbps intervals for 300 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(300);
          expect(markers, [0, 50, 100, 150, 200, 250, 300, 300]);
          // Note: upperBound appears twice - this is existing behavior
        });

        test('returns mixed intervals for 500 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(500);
          expect(markers, [0, 50, 100, 150, 200, 250, 300, 400, 500]);
        });

        test('returns correct markers for 400 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(400);
          expect(markers, [0, 50, 100, 150, 200, 250, 300, 400]);
        });
      });

      group('500-1000 Mbps range', () {
        test('returns 100 Mbps intervals with 750 marker for 1000 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(1000);
          expect(markers, [0, 100, 200, 300, 400, 500, 750, 1000]);
        });

        test('returns correct markers for 800 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(800);
          expect(markers, [0, 100, 200, 300, 400, 500, 750, 800]);
        });

        test('omits 750 marker if upperBound is less than 750', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(600);
          expect(markers, [0, 100, 200, 300, 400, 500, 600]);
        });

        test('includes 750 marker exactly when upperBound is 750', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(750);
          expect(markers, [0, 100, 200, 300, 400, 500, 750, 750]);
          // Note: 750 appears twice - this is existing behavior
        });
      });

      group('1000+ Mbps range', () {
        test('returns 200 Mbps intervals for 1200 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(1200);
          expect(markers, [0, 200, 400, 600, 800, 1000, 1200]);
        });

        test('returns correct markers for 2000 Mbps', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(2000);
          expect(markers,
              [0, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000]);
        });

        test('handles non-round values correctly', () {
          final markers = SpeedTestGaugeUtils.generateMarkers(1500);
          expect(markers, [0, 200, 400, 600, 800, 1000, 1200, 1400, 1500]);
        });
      });

      group('marker ordering and validity', () {
        test('markers are always in ascending order for various upper bounds',
            () {
          final testValues = [100, 150, 200, 300, 500, 750, 1000, 1500, 2000];

          for (final upperBound in testValues) {
            final markers =
                SpeedTestGaugeUtils.generateMarkers(upperBound.toDouble());

            // Check that markers are sorted
            for (int i = 0; i < markers.length - 1; i++) {
              expect(
                markers[i] <= markers[i + 1],
                true,
                reason:
                    'Markers not in order for upperBound $upperBound: $markers',
              );
            }
          }
        });

        test('first marker is always 0', () {
          expect(SpeedTestGaugeUtils.generateMarkers(100).first, 0);
          expect(SpeedTestGaugeUtils.generateMarkers(500).first, 0);
          expect(SpeedTestGaugeUtils.generateMarkers(2000).first, 0);
        });

        test('last marker equals upperBound', () {
          expect(SpeedTestGaugeUtils.generateMarkers(100).last, 100);
          expect(SpeedTestGaugeUtils.generateMarkers(500).last, 500);
          expect(SpeedTestGaugeUtils.generateMarkers(2000).last, 2000);
        });

        test('all markers are within [0, upperBound] range', () {
          final testValues = [100, 300, 750, 1500];

          for (final upperBound in testValues) {
            final markers =
                SpeedTestGaugeUtils.generateMarkers(upperBound.toDouble());

            for (final marker in markers) {
              expect(
                marker >= 0 && marker <= upperBound,
                true,
                reason: 'Marker $marker out of range [0, $upperBound]',
              );
            }
          }
        });
      });
    });
  });
}
