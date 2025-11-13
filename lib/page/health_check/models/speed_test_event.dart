import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';

/// Defines the events that are streamed from the [SpeedTestService] to the UI layer.
///
/// This sealed class ensures that all possible events are handled explicitly.
sealed class SpeedTestStreamEvent {}

/// Event representing an in-progress update from the speed test.
class SpeedTestProgress extends SpeedTestStreamEvent {
  /// The partial result of the ongoing speed test.
  final SpeedTestUIModel partialResult;
  SpeedTestProgress(this.partialResult);
}

/// Event representing the successful completion of the speed test.
class SpeedTestSuccess extends SpeedTestStreamEvent {
  /// The final result of the completed speed test.
  final SpeedTestUIModel finalResult;
  SpeedTestSuccess(this.finalResult);
}

/// Event representing a failure during the speed test.
class SpeedTestFailure extends SpeedTestStreamEvent {
  /// A string describing the error that occurred.
  final String error;
  SpeedTestFailure(this.error);
}
