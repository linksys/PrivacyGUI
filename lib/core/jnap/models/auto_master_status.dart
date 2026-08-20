import 'package:equatable/equatable.dart';

/// AutoMasterStatus represents the status of the Auto Master process.
/// - idle: Auto Master is not running
/// - running: Auto Master is in progress
/// - complete: Auto Master finished successfully (password changed to WiFi password)
/// - failed: Auto Master failed (e.g., found another Master on network, password still admin)
enum AutoMasterStatus {
  idle,
  running,
  complete,
  failed,
  ;

  String toValue() {
    return switch (this) {
      AutoMasterStatus.idle => 'Idle',
      AutoMasterStatus.running => 'Running',
      AutoMasterStatus.complete => 'Complete',
      AutoMasterStatus.failed => 'Failed',
    };
  }

  /// Maps a raw JNAP `autoMasterStatus` payload to a status, or `null` for
  /// anything unrecognized.
  ///
  /// Takes [Object?] rather than [String?] on purpose: callers pass
  /// `result.output['autoMasterStatus']` straight from a decoded JSON map, and
  /// an `as String?` cast there would throw a `TypeError` on an unexpected
  /// payload type. `scheduledCommand` does not catch `TypeError`, so that would
  /// escape the polling stream and strand the waiting spinner. A non-String
  /// value simply misses every case below and yields `null`, which the callers
  /// already handle as "status unavailable".
  static AutoMasterStatus? fromValue(Object? value) {
    return switch (value) {
      'Idle' => AutoMasterStatus.idle,
      'Running' => AutoMasterStatus.running,
      'Complete' => AutoMasterStatus.complete,
      'Failed' => AutoMasterStatus.failed,
      _ => null,
    };
  }
}

/// Response model for GetAutoMasterStatus JNAP action.
/// Response format: { "autoMasterStatus": "Idle" | "Running" | "Complete" }
class GetAutoMasterStatusResponse extends Equatable {
  final AutoMasterStatus? autoMasterStatus;

  const GetAutoMasterStatusResponse({this.autoMasterStatus});

  factory GetAutoMasterStatusResponse.fromMap(Map<String, dynamic> map) {
    return GetAutoMasterStatusResponse(
      autoMasterStatus: AutoMasterStatus.fromValue(map['autoMasterStatus']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoMasterStatus': autoMasterStatus?.toValue(),
    };
  }

  @override
  List<Object?> get props => [autoMasterStatus];
}
