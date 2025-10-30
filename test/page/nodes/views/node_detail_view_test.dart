import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';

import '../../../common/_index.dart';
import '../../../common/test_helper.dart';
import '../../../test_data/node_details_data.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    initBetterActions();
  });
  testLocalizations('Test node details view with mobile layout',
      (tester, locale) async {
    when(testHelper.mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    await testHelper.pumpShellView(
      tester,
      child: const NodeDetailView(),
      locale: locale,
    );

    final nameFinder = find.text('Router123');
    expect(nameFinder, findsNWidgets(2));
  }, screens: responsiveMobileScreens);
  testLocalizations('Test node details view with desktop layout',
      (tester, locale) async {
    when(testHelper.mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    await testHelper.pumpShellView(
      tester,
      child: const NodeDetailView(),
      locale: locale,
    );

    BuildContext context = tester.element(find.byType(NodeDetailView));
    final nameFinder = find.text('Router123');
    expect(nameFinder, findsNWidgets(2));

    final routerImageFinder =
        find.image(CustomTheme.of(context).images.devices.routerMx6200);
    expect(routerImageFinder, findsOneWidget);
  }, screens: responsiveDesktopScreens);
}
