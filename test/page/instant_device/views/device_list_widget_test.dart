// The shared device list's delete and deauth buttons with full access.
//
// Instant Devices and Node Detail both render their per-device delete and deauth
// through this widget. These tests pin that the buttons appear exactly when
// their caller asks for them (and deauth only when the router supports it), and
// that each reports the device it was tapped on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  // One wireless, online device keeps every finder unambiguous; deauth is only
  // offered for a wireless one.
  const device = DeviceListItem(
    deviceId: 'd1',
    name: 'Phone',
    isOnline: true,
    isWired: false,
  );

  setUp(() {
    when(serviceHelper.isSupportClientDeauth()).thenReturn(true);
  });

  tearDown(() => reset(serviceHelper));

  Future<void> pumpList(
    WidgetTester tester, {
    bool enableDelete = false,
    bool enableDeauth = false,
    void Function(DeviceListItem)? onItemDelete,
    void Function(DeviceListItem)? onItemDeauth,
  }) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [accessPolicyProvider.overrideWithValue(AccessPolicy.full)],
      child: Scaffold(
        body: DeviceListWidget(
          devices: const [device],
          enableDelete: enableDelete,
          enableDeauth: enableDeauth,
          onItemDelete: onItemDelete,
          onItemDeauth: onItemDeauth,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  final deleteIcon = find.byIcon(LinksysIcons.delete);
  final deauthIcon = find.byIcon(LinksysIcons.bidirectional);

  testWidgets('neither button appears unless asked for', (tester) async {
    await pumpList(tester);

    expect(find.text('Phone'), findsOneWidget);
    expect(deleteIcon, findsNothing);
    expect(deauthIcon, findsNothing);
  });

  testWidgets('delete appears when asked for and reports its device',
      (tester) async {
    DeviceListItem? deleted;
    await pumpList(tester,
        enableDelete: true, onItemDelete: (item) => deleted = item);

    await tester.tap(deleteIcon);

    expect(deleted, device);
  });

  testWidgets('deauth appears when asked for and reports its device',
      (tester) async {
    DeviceListItem? deauthed;
    await pumpList(tester,
        enableDeauth: true, onItemDeauth: (item) => deauthed = item);

    await tester.tap(deauthIcon);

    expect(deauthed, device);
  });

  testWidgets('deauth stays hidden when the router does not support it',
      (tester) async {
    when(serviceHelper.isSupportClientDeauth()).thenReturn(false);
    await pumpList(tester, enableDeauth: true, onItemDeauth: (_) {});

    expect(deauthIcon, findsNothing);
  });
}
