import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/instant_privacy_test_data.dart';

/// The real notifier with the router taken out: it loads a fixed state and its
/// save fails after a round trip, the way a refused or failed write does.
class _FailingSavePrivacy extends InstantPrivacyNotifier {
  @override
  InstantPrivacyState build() =>
      InstantPrivacyState.fromMap(instantPrivacyInitState);

  @override
  Future<InstantPrivacyState> fetch(
          {bool fetchRemote = false, bool statusOnly = false}) async =>
      state;

  @override
  Future doPolling() async {}

  int saves = 0;

  @override
  Future<InstantPrivacyState> save() async {
    saves++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw Exception('save failed');
  }
}

void main() {
  mockDependencyRegister();

  // #1637: the switch set the new mode on state before saving, and nothing put
  // it back when the save failed. Polling refreshes only the status, so the
  // switch went on showing a filter the router never turned on.
  testWidgets('a failed save puts the switch back', (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deviceList = MockDeviceListNotifier();
    when(deviceList.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));
    final notifier = _FailingSavePrivacy();

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        instantPrivacyProvider.overrideWith(() => notifier),
        deviceListProvider.overrideWith(() => deviceList),
      ],
      child: const InstantPrivacyView(),
    ));
    await tester.pumpAndSettle();
    final toggle = find.byWidgetPredicate(
        (w) => w is AppSwitch && w.semanticLabel == 'instant privacy');
    expect(tester.widget<AppSwitch>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    // The confirm dialog: turn it on.
    await tester.tap(find.text('Turn On'));
    await tester.pumpAndSettle();

    expect(tester.widget<AppSwitch>(toggle).value, isFalse,
        reason: 'the router never turned it on');
    expect(notifier.state.settings.mode, isNot(MacFilterMode.allow));
  });

  // #1637: in read-only mode the switch is blocked before it can save.
  testWidgets('read-only mode blocks the switch', (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deviceList = MockDeviceListNotifier();
    when(deviceList.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));
    final notifier = _FailingSavePrivacy();

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        instantPrivacyProvider.overrideWith(() => notifier),
        deviceListProvider.overrideWith(() => deviceList),
        accessPolicyProvider
            .overrideWithValue(const AccessPolicy(canWrite: false)),
      ],
      child: const InstantPrivacyView(),
    ));
    await tester.pumpAndSettle();
    final toggle = find.byWidgetPredicate(
        (w) => w is AppSwitch && w.semanticLabel == 'instant privacy');

    await tester.tap(toggle, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Turn On'), findsNothing,
        reason: 'the confirm dialog never opens');
    expect(notifier.saves, 0);
  });
}
