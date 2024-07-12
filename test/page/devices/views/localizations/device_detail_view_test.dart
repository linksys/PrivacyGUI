import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/device_details_test_state.dart';
import '../../device_detail_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<ExternalDeviceDetailNotifier>(),
])
void main() {
  late ExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;

  setUp(() {
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
  });
  testLocalizations('Device detail view ', (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  });
  testLocalizations('Device detail view - scroll down on mobile layout',
      (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final lastTextFinder = find.byType(AppSettingCard).last;
    await tester.scrollUntilVisible(lastTextFinder, 10,
        scrollable: find
            .descendant(
                of: find.byType(StyledAppPageView),
                matching: find.byType(Scrollable))
            .last);
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);
  testLocalizations('Device detail view - edit modal ',
      (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });
}
