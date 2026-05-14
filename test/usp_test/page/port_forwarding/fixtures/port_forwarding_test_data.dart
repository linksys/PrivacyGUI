import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

// ---------------------------------------------------------------------------
// Sample Port Forwarding Rules
// ---------------------------------------------------------------------------

const httpServerRule = PortForwardingRuleUIModel(
  instancePath: 'Device.NAT.PortMapping.1',
  description: 'HTTP Server',
  externalPort: 80,
  externalPortEndRange: 0,
  internalPort: 80,
  internalClient: '192.168.1.100',
  protocol: 'TCP',
  enabled: true,
);

const sshRule = PortForwardingRuleUIModel(
  instancePath: 'Device.NAT.PortMapping.2',
  description: 'SSH Access',
  externalPort: 22,
  externalPortEndRange: 0,
  internalPort: 22,
  internalClient: '192.168.1.100',
  protocol: 'TCP',
  enabled: true,
);

const gameServerRangeRule = PortForwardingRuleUIModel(
  instancePath: 'Device.NAT.PortMapping.3',
  description: 'Game Server',
  externalPort: 3074,
  externalPortEndRange: 3080,
  internalPort: 3074,
  internalClient: '192.168.1.50',
  protocol: 'Both',
  enabled: true,
);

const mediaStreamingRangeRule = PortForwardingRuleUIModel(
  instancePath: 'Device.NAT.PortMapping.4',
  description: 'Media Streaming',
  externalPort: 8000,
  externalPortEndRange: 8010,
  internalPort: 8000,
  internalClient: '192.168.1.200',
  protocol: 'UDP',
  enabled: false,
);

// ---------------------------------------------------------------------------
// Sample Port Triggering Rules
// ---------------------------------------------------------------------------

const ftpTriggerRule = PortTriggeringRuleUIModel(
  instancePath: 'Device.NAT.PortTrigger.1',
  enabled: true,
  description: 'FTP Transfer',
  triggerPort: 21,
  triggerPortEndRange: 0,
  triggerProtocol: 'TCP',
  forwardRules: [
    PortTriggerForwardRuleUIModel(
      instancePath: 'Device.NAT.PortTrigger.1.Rule.1',
      forwardPort: 1024,
      forwardPortEndRange: 1030,
      forwardProtocol: 'TCP',
    ),
  ],
);

const ircTriggerRule = PortTriggeringRuleUIModel(
  instancePath: 'Device.NAT.PortTrigger.2',
  enabled: false,
  description: 'IRC Chat',
  triggerPort: 6667,
  triggerPortEndRange: 6669,
  triggerProtocol: 'TCP',
  forwardRules: [
    PortTriggerForwardRuleUIModel(
      instancePath: 'Device.NAT.PortTrigger.2.Rule.1',
      forwardPort: 113,
      forwardPortEndRange: 0,
      forwardProtocol: 'TCP',
    ),
  ],
);

// ---------------------------------------------------------------------------
// State Factories
// ---------------------------------------------------------------------------

/// Data state with sample forwarding and triggering rules.
PortForwardingPageFeatureState dataState({
  List<PortForwardingRuleUIModel> forwardingRules = const [
    httpServerRule,
    sshRule,
    gameServerRangeRule,
    mediaStreamingRangeRule,
  ],
  List<PortTriggeringRuleUIModel> triggeringRules = const [
    ftpTriggerRule,
    ircTriggerRule,
  ],
}) {
  final settings = PortForwardingPageSettings(
    forwardingRules: forwardingRules,
    triggeringRules: triggeringRules,
  );
  return PortForwardingPageFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const PortForwardingPageStatus(),
  );
}

/// Data state with empty lists (no rules configured).
PortForwardingPageFeatureState get emptyDataState {
  const settings = PortForwardingPageSettings();
  return PortForwardingPageFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const PortForwardingPageStatus(),
  );
}

/// Dirty state: a new rule has been added locally but not saved.
PortForwardingPageFeatureState dirtyState({bool isSaving = false}) {
  const original = PortForwardingPageSettings(
    forwardingRules: [httpServerRule, sshRule],
    triggeringRules: [ftpTriggerRule],
  );

  const newRule = PortForwardingRuleUIModel(
    instancePath: null,
    description: 'Minecraft Server',
    externalPort: 25565,
    externalPortEndRange: 0,
    internalPort: 25565,
    internalClient: '192.168.1.150',
    protocol: 'TCP',
    enabled: true,
  );

  const current = PortForwardingPageSettings(
    forwardingRules: [httpServerRule, sshRule, newRule],
    triggeringRules: [ftpTriggerRule],
  );

  return PortForwardingPageFeatureState(
    settings: Preservable(original: original, current: current),
    status: PortForwardingPageStatus(isSaving: isSaving),
  );
}

/// Error state: fetch failed.
PortForwardingPageFeatureState get errorState => PortForwardingPageFeatureState(
      settings: Preservable(
        original: const PortForwardingPageSettings(),
        current: const PortForwardingPageSettings(),
      ),
      status: const PortForwardingPageStatus(
        errorMessage: 'Connection failed',
      ),
    );
