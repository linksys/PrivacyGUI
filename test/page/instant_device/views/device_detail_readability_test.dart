import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';

import '../../../common/di.dart';
import '../../../common/screen.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../common/theme_data.dart';
import '../../../layout_gate/fully_shown.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/device_details_test_state.dart';
import '../../../test_data/local_network_settings_state.dart';

// Constitution 3.4. A device's IPs, MAC and SSID are useless when cut. Each
// is as long as it gets (an SSID takes up to 32 characters), at the
// narrowest mobile and desktop page, in every locale. #1802 P4 measured at
// least 100px to spare on one line for each, so the guard was proven by
// capping the value at one line in a 60px box: every case went red.
const _ipv4 = '192.168.123.234';
const _ipv6 = 'fd00:abcd:1234:5678:9abc:def0:1234:5678';
const _mac = '8C:3B:AD:FE:EE:DD';
const _ssid = 'Linksys-Home-Network-5GHz-Guest1';

void main() {
  late MockExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  mockDependencyRegister();

  setUp(() {
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    final state = ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    when(mockExternalDeviceDetailNotifier.build()).thenReturn(state.copyWith(
        item: state.item.copyWith(
      ipv4Address: _ipv4,
      ipv6Address: _ipv6,
      macAddress: _mac,
      ssid: _ssid,
    )));
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
  });

  for (final (name, value) in [
    ('IPv4 address', find.text(_ipv4)),
    ('IPv6 address', find.text(_ipv6)),
    ('MAC address', find.text(_mac)),
    ('SSID', find.textContaining(_ssid)),
  ]) {
    for (final screen in const [
      ScreenSize('480', 480, 900, 1),
      ScreenSize('1241', 1241, 900, 1),
    ]) {
      for (final locale in AppLocalizations.supportedLocales) {
        testWidgets(
            'device detail shows the $name in full at ${screen.name} in '
            '${locale.toLanguageTag()}', (tester) async {
          await loadTestFonts();
          await tester.setScreenSize(screen);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(testableSingleRoute(
            locale: locale,
            overrides: [
              localNetworkSettingProvider
                  .overrideWith(() => mockLocalNetworkSettingsNotifier),
              externalDeviceDetailProvider
                  .overrideWith(() => mockExternalDeviceDetailNotifier),
            ],
            child: const DeviceDetailView(),
          ));
          await tester.pumpAndSettle();
          await tester.ensureVisible(value);
          await tester.pumpAndSettle();

          expect(value, isFullyShown);
        });
      }
    }
  }
}
