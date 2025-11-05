import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/safe_browsing_test_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(testHelper.mockInstantSafetyNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return InstantSafetyState.fromMap(instantSafetyTestState);
    });
  });

  testLocalizations('Instant safety view - on', (tester, locale) async {
    when(testHelper.mockInstantSafetyNotifier.build()).thenReturn(
        InstantSafetyState.fromMap(instantSafetyTestStateNotSupported));
    await testHelper.pumpShellView(
      tester,
      child: const InstantSafetyView(),
      config:
          LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Instant safety view - off', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const InstantSafetyView(),
      config:
          LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
    );
  }, screens: screens);
}