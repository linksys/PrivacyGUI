import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_auto_ipoe.dart';
import '../../../../mocks/provider_overrides/mock_internet_settings.dart';
import '../../../../mocks/test_data/scenes/auto_ipoe_scene_data.dart';
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
                pageState: ipoeReadyPageState,
                submission: null,
              ),
            ]),
        'ipoe_editing': (overrides) => overrides.addAll([
              ...internetSettingsOverrides(
                dataState(ipoeForm, isEditing: true),
              ),
              ...autoIPoEOverrides(
                snapshot: ipoeReadySnapshot,
                pageState: ipoeReadyPageState,
                submission: null,
              ),
            ]),
        'ipoe_v6_plus_static_ip_editing': (overrides) => overrides.addAll([
              ...internetSettingsOverrides(
                dataState(ipoeForm, isEditing: true),
              ),
              ...autoIPoEOverrides(
                snapshot: ipoeStaticIpSnapshot,
                pageState: ipoeStaticIpPageState,
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
        'pptp': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pptpStaticUnderlayForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  pppInstancePath: 'Device.PPP.Interface.1.',
                ),
              ),
            ),
        'pptp_static_underlay_editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pptpStaticUnderlayForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  pppInstancePath: 'Device.PPP.Interface.1.',
                  isEditing: true,
                ),
              ),
            ),
        'pptp_dhcp_underlay': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(pptpDhcpUnderlayForm,
                    readOnlyInfo: pppoeReadOnlyInfo),
              ),
            ),
        'pptp_dhcp_underlay_editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pptpDhcpUnderlayForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  isEditing: true,
                ),
              ),
            ),
        'pptp_validation_error': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pptpValidationErrorForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  isEditing: true,
                ),
              ),
            ),
        'l2tp': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(l2tpKeepAliveForm, readOnlyInfo: pppoeReadOnlyInfo),
              ),
            ),
        'l2tp_on_demand_editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  l2tpOnDemandForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  pppInstancePath: 'Device.PPP.Interface.1.',
                  isEditing: true,
                ),
              ),
            ),
        'l2tp_validation_error_on_demand': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  l2tpValidationErrorOnDemandForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  isEditing: true,
                ),
              ),
            ),
        'pppoe_keep_alive_editing': (overrides) => overrides.addAll(
              internetSettingsOverrides(
                dataState(
                  pppoeKeepAliveForm,
                  readOnlyInfo: pppoeReadOnlyInfo,
                  pppInstancePath: 'Device.PPP.Interface.1.',
                  isEditing: true,
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
      interactions: {
        'pptp_validation_error_tooltip': Interaction(
          setup: (overrides) => overrides.addAll(
            internetSettingsOverrides(
              dataState(
                pptpValidationErrorForm,
                readOnlyInfo: pppoeReadOnlyInfo,
                isEditing: true,
              ),
            ),
          ),
          steps: _tapEveryErrorIcon,
        ),
        'l2tp_validation_error_on_demand_tooltip': Interaction(
          setup: (overrides) => overrides.addAll(
            internetSettingsOverrides(
              dataState(
                l2tpValidationErrorOnDemandForm,
                readOnlyInfo: pppoeReadOnlyInfo,
                isEditing: true,
              ),
            ),
          ),
          steps: _tapEveryErrorIcon,
        ),
      },
    ),
  );
}

/// Opens every field's error tooltip at once.
Future<void> _tapEveryErrorIcon(WidgetTester tester) async {
  final errorIcons = find.byIcon(Icons.error_outline);
  for (int i = 0; i < errorIcons.evaluate().length; i++) {
    await tester.tap(errorIcons.at(i), warnIfMissed: false);
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
}
