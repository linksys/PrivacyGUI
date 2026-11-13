import 'package:equatable/equatable.dart';

/// Which steps the PnP wizard has, and in which order (#1511 P4).
///
/// **Decided once, when the wizard initializes, and never recomputed (D2).**
/// The setting steps come from the step list (`kPnpSettingSteps`), each kept or
/// dropped by its inclusion condition against what the router reported; after
/// that the stepper's segments, Next and Back, which step holds Save and the
/// back policy are all read from here, so none of them names a step.
class PnpFlowPlan extends Equatable {
  const PnpFlowPlan({required this.settingStepIds});

  /// The setting steps the router's data kept, in the step list's order.
  final List<String> settingStepIds;

  /// Your Network: always after the setting steps, with one node as with
  /// several (#1734) — it is where nodes are added, and a single router is the
  /// case that most needs to (REQ-16).
  static const yourNetworkStepId = 'network';

  /// Every step the stepper shows, in order.
  List<String> get stepIds => [...settingStepIds, yourNetworkStepId];

  String get firstStepId => stepIds.first;

  /// The step whose button saves. Your Network, until #1511 P5 moves Save to the
  /// last setting step.
  String get saveStepId => yourNetworkStepId;

  /// The step after [stepId], or `null` on the last one.
  String? stepAfter(String stepId) {
    final i = stepIds.indexOf(stepId);
    return i < 0 || i == stepIds.length - 1 ? null : stepIds[i + 1];
  }

  /// The step before [stepId], or `null` on the first one.
  String? stepBefore(String stepId) {
    final i = stepIds.indexOf(stepId);
    return i <= 0 ? null : stepIds[i - 1];
  }

  @override
  List<Object?> get props => [settingStepIds];
}
