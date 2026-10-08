import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_auto_ipoe.dart';
import '../../../../mocks/provider_overrides/mock_internet_settings.dart';
import '../fixtures/auto_ipoe_golden_scenes.dart';
import '../../../../mocks/test_data/scenes/internet_settings_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'internet_settings',
      view: () => const UspInternetSettingsView(),
      shell: ShellType.custom,
      height: 1500,
      states: {
        'ipoe': (overrides) => overrides.addAll([
              ...internetSettingsOverrides(dataState(ipoeForm)),
              ...autoIPoEOverrides(
                snapshot: ipoeReadySnapshot,
                pageState: ipoeGoldenPageState(ipoeReadySnapshot),
                submission: null,
              ),
            ]),
        'ipoe_editing': (overrides) => overrides.addAll([
              ...internetSettingsOverrides(
                dataState(ipoeForm, isEditing: true),
              ),
              ...autoIPoEOverrides(
                snapshot: ipoeReadySnapshot,
                pageState: ipoeGoldenPageState(ipoeReadySnapshot),
                submission: null,
              ),
            ]),
        'ipoe_v6_plus_static_ip_editing': (overrides) => overrides.addAll([
              ...internetSettingsOverrides(
                dataState(ipoeForm, isEditing: true),
              ),
              ...autoIPoEOverrides(
                snapshot: ipoeStaticIpSnapshot,
                pageState: ipoeGoldenPageState(ipoeStaticIpSnapshot),
                submission: null,
              ),
            ]),
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
