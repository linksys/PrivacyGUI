import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// A utility class for simple performance benchmarking.
///
/// This class provides a way to measure the time elapsed between two points
/// in the code. It can be used to identify performance bottlenecks during
/// development. Logs are only printed in debug mode.
class BenchMarkLogger {
  /// A descriptive name for the benchmark, used in log outputs.
  final String name;

  /// If `true`, the logger will only record the time without printing to the console.
  /// Defaults to `false`.
  final bool recordOnly;

  late DateTime _start;
  late DateTime _end;

  /// Creates a [BenchMarkLogger] instance.
  ///
  /// [name] is a required identifier for the benchmark instance.
  /// [recordOnly] can be set to `true` to disable console logging.
  BenchMarkLogger({
    required this.name,
    this.recordOnly = false,
  });

  /// Starts the benchmark timer.
  ///
  /// This method records the current time as the starting point. If not in
  /// `recordOnly` mode, it logs the start time to the console.
  void start() {
    _start = DateTime.now();
    if (kDebugMode && !recordOnly) {
      logger.d('${describeIdentity(this)} - $name: start at <$_start>');
    }
  }

  /// Ends the benchmark timer and returns the elapsed time.
  ///
  /// This method records the current time as the end point, calculates the
  /// duration since [start] was called, and logs the result if not in
  /// `recordOnly` mode.
  ///
  /// Returns the total elapsed time in milliseconds.
  int end() {
    _end = DateTime.now();
    int delta = _calcuteDeltaTime();
    if (kDebugMode && !recordOnly) {
      logger.d(
          '${describeIdentity(this)} - $name: end at <$_end>, delta time is <$delta>');
    }
    return delta;
  }

  int _calcuteDeltaTime() {
    return _end.millisecondsSinceEpoch - _start.millisecondsSinceEpoch;
  }
}
