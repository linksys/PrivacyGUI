import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

/// Pure UI state for Node Light (LED) settings.
class NodeLightState extends Equatable {
  final bool isNightModeEnabled;
  final int startHour;
  final int endHour;
  final bool allDayOff;

  const NodeLightState({
    this.isNightModeEnabled = false,
    this.startHour = 20,
    this.endHour = 6,
    this.allDayOff = false,
  });

  /// Status derived from settings logic
  NodeLightStatus get status {
    if (allDayOff) {
      return NodeLightStatus.off;
    }
    if (isNightModeEnabled) {
      return NodeLightStatus.night;
    }
    return NodeLightStatus.on;
  }

  /// Initial state
  factory NodeLightState.initial() => const NodeLightState();

  @override
  List<Object?> get props =>
      [isNightModeEnabled, startHour, endHour, allDayOff];

  NodeLightState copyWith({
    bool? isNightModeEnabled,
    int? startHour,
    int? endHour,
    bool? allDayOff,
  }) {
    return NodeLightState(
      isNightModeEnabled: isNightModeEnabled ?? this.isNightModeEnabled,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      allDayOff: allDayOff ?? this.allDayOff,
    );
  }
}
