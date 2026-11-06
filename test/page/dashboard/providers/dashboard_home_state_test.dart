import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

import '../../../test_data/dashboard_manager_test_state.dart';

void main() {
  // The router broadcasts _VelopSetup4C4 on every band, WPA2/WPA3 mixed.
  final radios =
      DashboardManagerState.fromMap(dashboardManagerTestState).mainRadios;

  List<RouterRadio> withSettings({String? security, bool? broadcastSSID}) => [
        for (final radio in radios)
          radio.copyWith(
            settings: radio.settings.copyWith(
              security: security,
              broadcastSSID: broadcastSSID,
            ),
          ),
      ];

  // Share WiFi hands out the same code a WiFi Settings save does, so it has to
  // follow the band's security mode and broadcast setting too.
  group('DashboardWiFiItem.qrCredential', () {
    test('a WPA network shares a WPA code with its password', () {
      final item = DashboardWiFiItem.fromMainRadios(radios, 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;P:9pe0a3rpwc;T:WPA;H:false;;',
      );
    });

    test('an open network shares a code that joins without a password', () {
      final item =
          DashboardWiFiItem.fromMainRadios(withSettings(security: 'None'), 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;T:nopass;H:false;;',
      );
    });

    test('a network that hides its name shares a code marked hidden', () {
      final item = DashboardWiFiItem.fromMainRadios(
          withSettings(broadcastSSID: false), 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;P:9pe0a3rpwc;T:WPA;H:true;;',
      );
    });
  });
}
