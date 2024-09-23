import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import '../../../../mocks/jnap_service_helper_spec_mocks.dart';
import '../../../../test_data/device_list_test_state.dart';
import '../../../../test_data/instant_privacy_test_data.dart';

void main() {
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late DeviceListNotifier mockDeviceListNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    // Mock InstantPrivacyNotifier
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyInitState));
    when(mockInstantPrivacyNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return InstantPrivacyState.fromMap(instantPrivacyInitState);
    });
    // Mock DeviceListNotifier
    mockDeviceListNotifier = MockDeviceListNotifier();
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));

  });

  testLocalizations('Instant privacy view - off 1', (tester, locale) async {
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - off 2', (tester, locale) async {
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState2));
    
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - on 1', (tester, locale) async {
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState1));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - on 2', (tester, locale) async {
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState2));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState2));
    
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - enable dialog', (tester, locale) async {
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byType(AppSwitch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - disable dialog', (tester, locale) async {
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState1));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byType(AppSwitch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant privacy view - delete dialog', (tester, locale) async {
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState1));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final deleteFinder = find.byIcon(LinksysIcons.delete);
    await tester.tap(deleteFinder.first);
    await tester.pumpAndSettle();
  });
}
