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
  /// case that most needs to (REQ-16). **After Save** since #1511 P5 (D3): a
  /// node added there joins with the Wi-Fi the user has just set, and nothing
  /// past the save edits the Wi-Fi.
  static const yourNetworkStepId = 'network';

  /// Every step the stepper shows, in order.
  List<String> get stepIds => [...settingStepIds, yourNetworkStepId];

  String get firstStepId => stepIds.first;

  /// The step whose button saves: the last setting step (#1511 P5).
  String get saveStepId => settingStepIds.last;

  /// The step Next goes to from [stepId], or `null` where the step's button is
  /// not Next: on the save step, which saves — the flow then opens Your
  /// Network itself — and on Your Network.
  String? stepAfter(String stepId) {
    final i = settingStepIds.indexOf(stepId);
    return i < 0 || i == settingStepIds.length - 1
        ? null
        : settingStepIds[i + 1];
  }

  /// The step Back goes to from [stepId], or `null` where there is no Back: on
  /// the first step, and on Your Network, which is past the save. **Back never
  /// crosses Save** (D7).
  String? stepBefore(String stepId) {
    final i = settingStepIds.indexOf(stepId);
    return i <= 0 ? null : settingStepIds[i - 1];
  }

  @override
  List<Object?> get props => [settingStepIds];
}
