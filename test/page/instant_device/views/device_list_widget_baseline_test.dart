// Baseline for the shared device list's delete and deauth buttons in the
// default build.
//
// Instant Devices and Node Detail both render their per-device delete and deauth
// through this widget, so a read-only build is going to turn both off here once
// rather than at each caller. These tests pin that in the default build the
// buttons appear exactly when their caller asks for them (and deauth only when
// the router supports it), and that each reports the device it was tapped on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_filtered_list_test_data.dart';

void main() {
  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  // One wireless, online device keeps every finder unambiguous.
  final device = DeviceListItem.fromMap(deviceFilteredTestData.first);

  setUp(() {
    when(mockServiceHelper.isSupportClientDeauth()).thenReturn(true);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> pump(
    WidgetTester tester, {
    bool readOnly = false,
    bool enableDelete = false,
    bool enableDeauth = false,
    void Function(DeviceListItem)? onItemDelete,
    void Function(DeviceListItem)? onItemDeauth,
  }) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [readOnlyModeProvider.overrideWithValue(readOnly)],
      child: SizedBox(
        height: 400,
        child: DeviceListWidget(
          devices: [device],
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
    await pump(tester);

    expect(deleteIcon, findsNothing);
    expect(deauthIcon, findsNothing);
  });

  testWidgets('delete appears when asked for and reports its device',
      (tester) async {
    DeviceListItem? deleted;
    await pump(tester,
        enableDelete: true, onItemDelete: (item) => deleted = item);

    await tester.tap(deleteIcon);
    expect(deleted, device);
  });

  testWidgets('deauth appears when asked for and reports its device',
      (tester) async {
    DeviceListItem? deauthed;
    await pump(tester,
        enableDeauth: true, onItemDeauth: (item) => deauthed = item);

    await tester.tap(deauthIcon);
    expect(deauthed, device);
  });

  testWidgets('deauth stays hidden when the router does not support it',
      (tester) async {
    when(mockServiceHelper.isSupportClientDeauth()).thenReturn(false);
    await pump(tester, enableDeauth: true, onItemDeauth: (_) {});

    expect(deauthIcon, findsNothing);
  });

  testWidgets('a read-only build hides both however they are asked for',
      (tester) async {
    await pump(tester,
        readOnly: true,
        enableDelete: true,
        enableDeauth: true,
        onItemDelete: (_) {},
        onItemDeauth: (_) {});

    expect(deleteIcon, findsNothing);
    expect(deauthIcon, findsNothing);
  });
}
