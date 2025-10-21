import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import '../../../../test_data/_index.dart';

void main() {
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late DeviceListNotifier mockDeviceListNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockDeviceListNotifier = MockDeviceListNotifier();
    // Mock InstantPrivacyNotifier
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    // Mock DeviceListNotifier
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
  });

  tearDown(() {});

  testLocalizations(
    'Instant-Privacy view - disabled state',
    (tester, locale) async {
      when(mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      await tester.pumpWidget(
        testableSingleRoute(
          child: const InstantPrivacyView(),
          locale: locale,
          overrides: [
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            deviceListProvider.overrideWith(() => mockDeviceListNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ],
  );

  testLocalizations(
    'Instant-Privacy view - MAC filtering warning',
    (tester, locale) async {
      when(mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      when(mockInstantPrivacyNotifier.fetch(
              forceRemote: anyNamed('forceRemote')))
          .thenAnswer((_) {
        return Future.delayed(Durations.extralong1, () {
          return InstantPrivacyState.fromMap(instantPrivacyDenyTestState);
        });
      });
      await tester.pumpWidget(
        testableSingleRoute(
          child: const InstantPrivacyView(),
          locale: locale,
          overrides: [
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            deviceListProvider.overrideWith(() => mockDeviceListNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ],
  );

  testLocalizations(
    'Instant-Privacy view - enabled state',
    (tester, locale) async {
      when(mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      await tester.pumpWidget(
        testableSingleRoute(
          child: const InstantPrivacyView(),
          locale: locale,
          overrides: [
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            deviceListProvider.overrideWith(() => mockDeviceListNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ],
  );

  testLocalizations('Instant-Privacy view - enabling modal',
      (tester, locale) async {
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
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

  testLocalizations('Instant-Privacy view - disabling modal',
      (tester, locale) async {
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
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

  testLocalizations('Instant-Privacy view - delete confirm modal',
      (tester, locale) async {
    when(mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final deleteFinder = find.byIcon(LinksysIcons.delete);
    await tester.tap(deleteFinder.at(1));
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Privacy view - delete self alert modal',
      (tester, locale) async {
    when(mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantPrivacyView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final myCardFinder = find.ancestor(
        of: find.text('3C:22:FB:E4:4F:18'), matching: find.byType(AppCard));
    await tester.scrollUntilVisible(myCardFinder, 100,
        scrollable: find.byType(Scrollable).last);
    expect(myCardFinder, findsOneWidget);
    final deleteFinder = find.descendant(
        of: myCardFinder, matching: find.byIcon(LinksysIcons.delete));
    await tester.tap(deleteFinder.first);
    await tester.pumpAndSettle();
  });
}
