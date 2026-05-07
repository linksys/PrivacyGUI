import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// Transforms raw codegen [PortForwarding] to UI models.
///
/// Shared between L1 Service (fetch) and L2 Service (fetch for page).
List<PortForwardingRuleUIModel> transformForwardingRules(PortForwarding data) {
  return data.items
      .map((r) => PortForwardingRuleUIModel(
            instancePath: r.instancePath,
            description: r.description,
            externalPort: r.externalPort,
            externalPortEndRange: r.externalPortEndRange,
            internalPort: r.internalPort,
            internalClient: r.internalClient,
            protocol: r.protocol,
            enabled: r.enabled,
          ))
      .toList();
}

/// Transforms raw codegen [PortTriggering] to UI models.
///
/// Shared between L1 Service (fetch) and L2 Service (fetch for page).
List<PortTriggeringRuleUIModel> transformTriggeringRules(PortTriggering data) {
  return data.items
      .map((t) => PortTriggeringRuleUIModel(
            instancePath: t.instancePath,
            enabled: t.enabled,
            description: t.description,
            triggerPort: t.triggerPort,
            triggerPortEndRange: t.triggerPortEndRange,
            triggerProtocol: t.triggerProtocol,
            forwardRules: t.rules
                .map((r) => PortTriggerForwardRuleUIModel(
                      instancePath: r.instancePath,
                      forwardPort: r.forwardPort,
                      forwardPortEndRange: r.forwardPortEndRange,
                      forwardProtocol: r.forwardProtocol,
                    ))
                .toList(),
          ))
      .toList();
}
