import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/mac_filtering_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/_index.dart';

/// The real notifier with the router taken out: it loads a fixed state with
/// filtering off, and the page's entry fetch and polling go nowhere.
class _FakePrivacy extends InstantPrivacyNotifier {
  @override
  InstantPrivacyState build() =>
      InstantPrivacyState.fromMap(instantPrivacyTestState);

  @override
  Future<InstantPrivacyState> fetch(
          {bool fetchRemote = false, bool statusOnly = false}) async =>
      state;

  @override
  Future doPolling() async {}
}

void main() {
  mockDependencyRegister();

  late _FakePrivacy privacy;

  Future<void> pumpPage(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deviceList = MockDeviceListNotifier();
    when(deviceList.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));
    privacy = _FakePrivacy();

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        instantPrivacyProvider.overrideWith(() => privacy),
        deviceListProvider.overrideWith(() => deviceList),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const Scaffold(body: MacFilteringView()),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: the switch picks the filter mode the page then saves to the router,
  // so it is blocked before it can change the mode at all.
  group('MAC filtering switch', () {
    final toggle = find.byWidgetPredicate(
        (w) => w is AppSwitch && w.semanticLabel == 'wifi mac filtering');

    testWidgets('is blocked in read-only mode', (tester) async {
      await pumpPage(tester, policy: const AccessPolicy(canWrite: false));

      expect(
          find.ancestor(
              of: toggle,
              matching:
                  find.byTooltip('This feature is unavailable in remote mode')),
          findsOneWidget);

      await tester.tap(toggle, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(privacy.state.settings.mode, MacFilterMode.disabled);
    });

    testWidgets('turns filtering on with full access', (tester) async {
      await pumpPage(tester);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(privacy.state.settings.mode, MacFilterMode.deny);
    });
  });
}
