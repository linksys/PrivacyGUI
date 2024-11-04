import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import '../../../../test_data/device_details_test_state.dart';
import '../../../../test_data/local_network_settings_state.dart';

void main() {
  late ExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;
  late LocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  setUp(() {
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
  });
  testLocalizations('Device detail view ', (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
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
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
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
  testLocalizations('Device detail view - edit modal ', (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
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
