import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/local_network_settings_state.dart';
import '../../../../../mocks/local_network_settings_notifier_mocks.dart';

void main() {
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  setUp(() {
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
  });

  testLocalizations('DHCP Server view test - DHCP server enabled',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const DHCPServerView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('DHCP Server view test - DHCP server disabled',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const DHCPServerView(),
    );
    await tester.pumpWidget(widget);
    final dhcpServerFinder = find.byWidgetPredicate(
      (widget) => widget is Switch && widget.thumbIcon == null,
    );
    expect(dhcpServerFinder, findsOneWidget);
    await tester.tap(dhcpServerFinder);
    await tester.pumpAndSettle();
  });
}
