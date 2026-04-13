import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

void main() {
  late UspDeviceService service;

  setUp(() {
    service = UspDeviceService();
  });

  // Moved to dedicated L1 Service tests:
  // buildSystemInfoUIModel → UspSystemInfoDataService
  // buildFirmwareImageUIModels → UspSystemInfoDataService
  // buildDeviceUIModels → UspDevicesDataService
  // buildNodeUIModels → UspDevicesDataService
  // buildWifiRadioUIModels → UspWifiDataService
  // buildDhcpClientUIModels → UspDhcpDataService
  // buildDhcpReservationUIModels → UspDhcpDataService
  // buildLanInfoUIModel → UspLanDataService
  // buildEthernetPortUIModels → UspEthernetDataService

  // ---------------------------------------------------------------------------
  // buildPortForwardingRuleUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildPortForwardingRuleUIModels', () {
    test('maps all fields including nested data', () {
      final data = PortForwarding(items: [
        PortForwardingRule(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          externalPortEndRange: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ]);

      final result = service.buildPortForwardingRuleUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].description, 'HTTP');
      expect(result[0].protocol, 'TCP');
      expect(result[0].enabled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // buildPortTriggeringRuleUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildPortTriggeringRuleUIModels', () {
    test('maps parent + nested forward rules', () {
      final data = PortTriggering(items: [
        PortTrigger(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerPortEndRange: 21,
          triggerProtocol: 'TCP',
          rules: [
            PortTriggerForwardRule(
              instancePath: 'path.1.Rule.1.',
              forwardPort: 1024,
              forwardPortEndRange: 1030,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ]);

      final result = service.buildPortTriggeringRuleUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].description, 'FTP');
      expect(result[0].forwardRules, hasLength(1));
      expect(result[0].forwardRules[0].forwardPort, 1024);
    });

    test('empty forward rules list', () {
      final data = PortTriggering(items: [
        PortTrigger(
          instancePath: 'path.1.',
          enabled: true,
          description: 'Simple',
          triggerPort: 5060,
          triggerPortEndRange: 5060,
          triggerProtocol: 'UDP',
          rules: [],
        ),
      ]);

      final result = service.buildPortTriggeringRuleUIModels(data);
      expect(result[0].forwardRules, isEmpty);
    });
  });

  // buildWanStatusUIModel — moved to UspWanDataService
}
