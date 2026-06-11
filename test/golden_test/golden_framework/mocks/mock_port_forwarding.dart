import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';

class FixedPortForwardingPageNotifier extends UspPortForwardingPageNotifier {
  final PortForwardingPageFeatureState _fixedState;

  FixedPortForwardingPageNotifier(this._fixedState);

  @override
  PortForwardingPageFeatureState build() => _fixedState;

  @override
  Future<(PortForwardingPageSettings?, PortForwardingPageStatus?)>
      performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
          (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void addForwardingRule(PortForwardingRuleUIModel rule) {}

  @override
  void editForwardingRule(
      PortForwardingRuleUIModel oldRule, PortForwardingRuleUIModel newRule) {}

  @override
  void toggleForwardingRule(PortForwardingRuleUIModel rule, bool enabled) {}

  @override
  void deleteForwardingRule(PortForwardingRuleUIModel rule) {}

  @override
  void addTriggeringRule(PortTriggeringRuleUIModel rule) {}

  @override
  void editTriggeringRule(
      PortTriggeringRuleUIModel oldRule, PortTriggeringRuleUIModel newRule) {}

  @override
  void toggleTriggeringRule(PortTriggeringRuleUIModel rule, bool enabled) {}

  @override
  void deleteTriggeringRule(PortTriggeringRuleUIModel rule) {}

  @override
  Future<void> immediateToggleForwarding(
      String instancePath, bool enabled) async {}

  @override
  Future<void> immediateAddForwarding({
    required int externalPort,
    required int internalPort,
    required String internalClient,
    required String protocol,
    String description = '',
    bool enabled = true,
    int externalPortEndRange = 0,
  }) async {}

  @override
  Future<void> immediateToggleTriggering(
      String instancePath, bool enabled) async {}
}

/// Returns provider overrides for port forwarding golden tests.
List<Override> portForwardingOverrides(PortForwardingPageFeatureState state) =>
    [
      uspPortForwardingPageProvider
          .overrideWith(() => FixedPortForwardingPageNotifier(state)),
    ];
