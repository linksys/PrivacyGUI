import 'package:equatable/equatable.dart';

/// AutoMasterStatus represents the status of the Auto Master process.
/// - idle: Auto Master is not running or failed
/// - running: Auto Master is in progress
/// - complete: Auto Master finished successfully (password changed to WiFi password)
enum AutoMasterStatus {
  idle,
  running,
  complete,
  ;

  String toValue() {
    return switch (this) {
      AutoMasterStatus.idle => 'Idle',
      AutoMasterStatus.running => 'Running',
      AutoMasterStatus.complete => 'Complete',
    };
  }

  static AutoMasterStatus? fromValue(String? value) {
    return switch (value) {
      'Idle' => AutoMasterStatus.idle,
      'Running' => AutoMasterStatus.running,
      'Complete' => AutoMasterStatus.complete,
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
