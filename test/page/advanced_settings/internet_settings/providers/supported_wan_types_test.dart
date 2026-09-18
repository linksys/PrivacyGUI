// Which IPv4 connection types Internet Settings offers.
//
// IPoE is the only one with two conditions, and the two entry points used to
// disagree about that: the troubleshooter's ISP-type list required the router to
// list IPoE *and* to advertise the AutoIPoE service, while this filter checked
// only the list. A router that lists IPoE without the service would offer it
// here, render an all-defaults pane -- the provider returns its init state when
// the service is absent -- and fail only at Save.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

void main() {
  const routerTypes = ['DHCP', 'IPoE', 'Static', 'PPPoE'];

  test('offers IPoE when the router both lists it and advertises the service',
      () {
    expect(
      effectiveSupportedIpv4ConnectionTypes(
        supportedTypes: routerTypes,
        supportsAutoIPoEService: true,
      ),
      routerTypes,
    );
  });

  test('drops IPoE when the service is absent, keeping the rest', () {
    expect(
      effectiveSupportedIpv4ConnectionTypes(
        supportedTypes: routerTypes,
        supportsAutoIPoEService: false,
      ),
      ['DHCP', 'Static', 'PPPoE'],
    );
  });

  test('the service condition only ever affects IPoE', () {
    final withService = effectiveSupportedIpv4ConnectionTypes(
      supportedTypes: const [
        'DHCP',
        'Static',
        'PPPoE',
        'PPTP',
        'L2TP',
        'Bridge'
      ],
      supportsAutoIPoEService: true,
    );
    final withoutService = effectiveSupportedIpv4ConnectionTypes(
      supportedTypes: const [
        'DHCP',
        'Static',
        'PPPoE',
        'PPTP',
        'L2TP',
        'Bridge'
      ],
      supportsAutoIPoEService: false,
    );

    expect(withService, withoutService);
  });

  test('recognises IPoE however the router spells it', () {
    // The check is on the canonical type, so casing from the wire cannot slip
    // an unsupported IPoE past it.
    for (final spelling in ['IPoE', 'ipoe', 'IPOE', ' IPoE ']) {
      expect(
        effectiveSupportedIpv4ConnectionTypes(
          supportedTypes: [spelling],
          supportsAutoIPoEService: false,
        ),
        isEmpty,
        reason: spelling,
      );
      expect(
        effectiveSupportedIpv4ConnectionTypes(
          supportedTypes: [spelling],
          supportsAutoIPoEService: true,
        ),
        ['IPoE'],
        reason: spelling,
      );
    }
  });

  test('canonicalizes and de-duplicates as it did before', () {
    expect(
      effectiveSupportedIpv4ConnectionTypes(
        supportedTypes: const ['dhcp', 'DHCP', '', '  ', 'static'],
        supportsAutoIPoEService: true,
      ),
      ['DHCP', 'Static'],
    );
  });

  test('keeps an unknown type rather than dropping it', () {
    // Pre-existing behaviour: a type this build does not know is passed through
    // rather than hidden, so a newer router is not silently limited.
    expect(
      effectiveSupportedIpv4ConnectionTypes(
        supportedTypes: const ['DHCP', 'SomethingNewer'],
        supportsAutoIPoEService: true,
      ),
      ['DHCP', 'SomethingNewer'],
    );
  });
}
