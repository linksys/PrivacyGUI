import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// Service provider — stateless, per Article VI.
final uspDeviceServiceProvider = Provider<UspDeviceService>(
  (ref) => UspDeviceService(),
);

/// Transforms raw codegen Data Models into Presentation Layer UI Models.
///
/// All Data → UI conversion is consolidated here so that UI widgets never
/// import codegen types directly (constitution Section 5.3).
class UspDeviceService {
  // ---------------------------------------------------------------------------
  // Port Forwarding
  // ---------------------------------------------------------------------------

  List<PortForwardingRuleUIModel> buildPortForwardingRuleUIModels(
      PortForwarding portForwarding) {
    return portForwarding.items
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

  // ---------------------------------------------------------------------------
  // Port Triggering
  // ---------------------------------------------------------------------------

  List<PortTriggeringRuleUIModel> buildPortTriggeringRuleUIModels(
      PortTriggering portTriggering) {
    return portTriggering.items
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

  // Moved to dedicated L1 Services:
  // buildWanStatusUIModel → UspWanDataService
  // buildLanInfoUIModel → UspLanDataService
  // buildEthernetPortUIModels → UspEthernetDataService
  // buildNodeUIModels → UspDevicesDataService
  // buildDeviceUIModels → UspDevicesDataService
  // buildWifiRadioUIModels → UspWifiDataService
  // buildSystemInfoUIModel → UspSystemInfoDataService
  // buildFirmwareImageUIModels → UspSystemInfoDataService
  // buildTimeSettingsUIModel → UspTimeDataService
  // buildDhcpClientUIModels → UspDhcpDataService
  // buildDhcpReservationUIModels → UspDhcpDataService
}
