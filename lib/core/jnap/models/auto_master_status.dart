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

  static AutoMasterStatus? fromValue(String? value) {
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
      autoMasterStatus:
          AutoMasterStatus.fromValue(map['autoMasterStatus'] as String?),
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
