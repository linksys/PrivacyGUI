import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_internet_settings.dart';
import '../fixtures/internet_settings_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'internet_settings',
      view: () => const UspInternetSettingsView(),
      shell: ShellType.custom,
      height: 1500,
      states: {
        'dhcp': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(dhcpForm, readOnlyInfo: defaultReadOnlyInfo),
              ),
            ),
        'static_ip': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(staticIpForm, readOnlyInfo: defaultReadOnlyInfo),
              ),
            ),
        'pppoe': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pppoeForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  pppInstancePath: 'Device.PPP.Interface.1.',
                ),
              ),
            ),
        'bridge': (overrides) => overrides.addAll(
              internetSettingsOverrides(dataState(bridgeForm)),
            ),
        'bridge_editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  bridgeForm,
                  readOnlyInfo: bridgeReadOnlyInfo,
                  isEditing: true,
                ),
              ),
            ),
        'ipv6_enabled': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(ipv6EnabledForm, readOnlyInfo: ipv6ReadOnlyInfo),
              ),
            ),
        'editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  dhcpForm,
                  readOnlyInfo: defaultReadOnlyInfo,
                  isEditing: true,
                ),
              ),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              internetSettingsOverrides(dirtyState()),
            ),
      },
    ),
  );
}
