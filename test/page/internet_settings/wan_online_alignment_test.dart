import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/wan_ip_reading.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

import '../../mocks/provider_overrides/mock_wan_data.dart';

/// linksys/PrivacyGUI#1620 — one definition of "WAN online" for the whole app.
///
/// WHAT WENT WRONG. Two providers answered the same question from different TR-181
/// fields: `wanIsUpProvider` from `Device.IP.Interface.{wan}.Status`, and
/// `wanIpReadingProvider` from `IPv4Address.1.IPAddress` being non-empty. The dashboard
/// read the first, the Internet Settings banner the second — so the two screens could
/// describe the same router differently at the same moment, one click apart.
///
/// Measured on real hardware (M60-US, FW 2.0.2.26091803, 2026-10-01): after `ifup`,
/// `Status` reads `Up` for about **5 seconds** before an address arrives. Reproduced
/// twice. Going down there is no disagreement — `Status` and the address change together,
/// and the address leaf disappears rather than emptying.
///
/// So `Status == 'Up'` is the definition, and the address is a separate question that
/// keeps its own three states in [WanIpReading].
///
/// These tests assert at the provider level rather than by pumping each screen. The
/// widgets are covered by their own tests; what cannot be covered there is the property
/// that matters here — that there is only ONE answer to read.
void main() {
  ProviderContainer container(Override wan) {
    final c = ProviderContainer(overrides: [wan]);
    addTearDown(c.dispose);
    return c;
  }

  group('#1620 — one definition of online', () {
    test(
        'link up with no address yet reads ONLINE, and the address is separate',
        () async {
      final c = container(wanDataOverride(wanUpNoAddressModel));
      await c.read(wanDataProvider.future);

      // THE 5-SECOND WINDOW. Before #1620 the dashboard said online here and the
      // Internet Settings banner said offline.
      expect(c.read(wanIsUpProvider), isTrue,
          reason:
              'the link is up; an address that has not arrived is not a disconnection');

      // And the address question still answers honestly — "the device reported no
      // address" — which is what the address line renders as '--'. The point of #1620 is
      // that this no longer doubles as an online/offline verdict.
      expect(c.read(wanIpReadingProvider), isA<WanIpNone>());
    });

    test('link down reads OFFLINE, and both questions agree there', () async {
      final c = container(wanDataOverride(wanNoAddressModel));
      await c.read(wanDataProvider.future);

      expect(c.read(wanIsUpProvider), isFalse);
      expect(c.read(wanIpReadingProvider), isA<WanIpNone>(),
          reason:
              'measured: Status and the address leaf change together on the way down');
    });

    test('a normal connection reads ONLINE with its address', () async {
      final c = container(wanDataOverride());
      await c.read(wanDataProvider.future);

      expect(c.read(wanIsUpProvider), isTrue);
      expect(c.read(wanIpReadingProvider), isA<WanIpAddress>());
    });
  });

  group('#1620 — "not read yet" is a third answer, not a default', () {
    test('an unread L1 gives null rather than a guess', () {
      final c = container(wanDataOverride());

      // Read before awaiting the future: nothing has settled yet.
      expect(c.read(wanIsUpProvider), isNull,
          reason:
              'the provider must not invent an answer; the caller chooses what to do');
      expect(c.read(wanIpReadingProvider), isA<WanIpUnknown>());
    });

    test('a failed L1 read also gives null, not false', () async {
      final c = container(wanDataErrorOverride());
      try {
        await c.read(wanDataProvider.future);
      } catch (_) {
        // Expected; the question is what the providers say afterwards.
      }

      // NOT `false`. This provider used to return `true` here via `?? true`, which is a
      // guess in the other direction — and #1613 had already established for the address
      // that an unreadable L1 must not be rendered as a confident verdict. The screens
      // now make that choice themselves: the dashboard writes `?? true` so it does not
      // raise a false alarm, the Internet Settings dot writes `?? false` so it does not
      // claim a connection.
      expect(c.read(wanIsUpProvider), isNull);
      expect(c.read(wanIpReadingProvider), isA<WanIpUnknown>());
    });
  });
}
