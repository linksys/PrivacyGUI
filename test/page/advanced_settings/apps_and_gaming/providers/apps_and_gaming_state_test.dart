import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';

const _state = AppsAndGamingViewState(
  preserveDDNSState: DDNSState(
    supportedProvider: ['None', 'No-IP'],
    provider: NoIPDNSProvider(
        settings: NoIPSettings(username: 'bob', password: 'pw', hostName: 'b')),
    status: 'Success',
    ipAddress: '203.0.113.7',
  ),
  preserveSinglePortForwardingListState: SinglePortForwardingListState(rules: [
    SinglePortForwardingRule(
      isEnabled: true,
      externalPort: 3074,
      protocol: 'TCP',
      internalServerIPAddress: '192.168.1.150',
      internalPort: 3074,
      description: 'XBox',
    ),
  ]),
  preservePortRangeForwardingListState: PortRangeForwardingListState(rules: [
    PortRangeForwardingRule(
      isEnabled: true,
      firstExternalPort: 6888,
      lastExternalPort: 6900,
      protocol: 'Both',
      internalServerIPAddress: '192.168.1.150',
      description: 'BitTorrent',
    ),
  ]),
  preservePortRangeTriggeringListState: PortRangeTriggeringListState(rules: [
    PortRangeTriggeringRule(
      isEnabled: true,
      firstTriggerPort: 12000,
      lastTriggerPort: 12050,
      firstForwardedPort: 12000,
      lastForwardedPort: 12050,
      description: 'custom',
    ),
  ]),
  isDataValid: false,
);

void main() {
  test('survives a trip through JSON text, with every tab it kept', () {
    expect(AppsAndGamingViewState.fromJson(_state.toJson()), _state);
  });

  test('reads a page that kept nothing yet as invalid', () {
    final read = AppsAndGamingViewState.fromMap(const {});

    expect(read.preserveDDNSState, isNull);
    expect(read.preserveSinglePortForwardingListState, isNull);
    expect(read.preservePortRangeForwardingListState, isNull);
    expect(read.preservePortRangeTriggeringListState, isNull);
    expect(read.isDataValid, isFalse);
  });

  test('copyWith can clear what it names', () {
    final cleared = _state.copyWith(
      preserveDDNSState: () => null,
      preserveSinglePortForwardingListState: () => null,
      preservePortRangeForwardingListState: () => null,
      preservePortRangeTriggeringListState: () => null,
      isDataValid: true,
    );

    expect(cleared, const AppsAndGamingViewState());
    expect(_state.copyWith(), _state);
    expect(_state.toString(), contains('isDataValid: false'));
  });
}
