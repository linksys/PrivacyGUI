import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_list_test_state.dart';
import '../../../../test_data/instant_privacy_test_data.dart';
import '../../../../test_data/instant_privacy_test_state.dart';

final _instantPrivacyScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();

    when(testHelper.mockInstantPrivacyNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return InstantPrivacyState.fromMap(instantPrivacyInitState);
    });
  });

  testLocalizations(
    'Instant-Privacy view - disabled state',
    (tester, locale) async {
      when(testHelper.mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      await testHelper.pumpView(
        tester,
        child: const InstantPrivacyView(),
        locale: locale,
      );
    },
    screens: _instantPrivacyScreens,
  );

  testLocalizations(
    'Instant-Privacy view - MAC filtering warning',
    (tester, locale) async {
      when(testHelper.mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      when(testHelper.mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));
      when(testHelper.mockInstantPrivacyNotifier.fetch(
              fetchRemote: anyNamed('fetchRemote')))
          .thenAnswer((_) {
        return Future.delayed(Durations.extralong1, () {
          return InstantPrivacyState.fromMap(instantPrivacyDenyTestState);
        });
      });
      await testHelper.pumpView(
        tester,
        child: const InstantPrivacyView(),
        locale: locale,
      );
    },
    screens: _instantPrivacyScreens,
  );

  testLocalizations(
    'Instant-Privacy view - enabled state',
    (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState));
      when(testHelper.mockDeviceListNotifier.build()).thenReturn(
          DeviceListState.fromMap(instantPrivacyDeviceListTestState));

      await testHelper.pumpView(
        tester,
        child: const InstantPrivacyView(),
        locale: locale,
      );
    },
    screens: _instantPrivacyScreens,
  );

  testLocalizations('Instant-Privacy view - enabling modal',
      (tester, locale) async {
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await testHelper.pumpView(
      tester,
      child: const InstantPrivacyView(),
      locale: locale,
    );

    final switchFinder = find.byType(AppSwitch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Privacy view - disabling modal',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState));
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await testHelper.pumpView(
      tester,
      child: const InstantPrivacyView(),
      locale: locale,
    );

    final switchFinder = find.byType(AppSwitch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Privacy view - delete confirm modal',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState));
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await testHelper.pumpView(
      tester,
      child: const InstantPrivacyView(),
      locale: locale,
    );

    final deleteFinder = find.byIcon(LinksysIcons.delete);
    await tester.tap(deleteFinder.at(1));
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Privacy view - delete self alert modal',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyOnState));
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(instantPrivacyDeviceListTestState));

    await testHelper.pumpView(
      tester,
      child: const InstantPrivacyView(),
      locale: locale,
    );
    final myCardFinder = find.ancestor(
        of: find.text('3C:22:FB:E4:4F:18'), matching: find.byType(AppCard));
    final deleteFinder = find.descendant(
        of: myCardFinder, matching: find.byIcon(LinksysIcons.delete));
    await tester.tap(deleteFinder.first);
    await tester.pumpAndSettle();
  });
}