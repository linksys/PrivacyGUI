import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/input_field/pin_code_input.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('local router recovery view - init state',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));

    await testHelper.pumpView(
      tester,
      child: const LocalRouterRecoveryView(),
      locale: locale,
      config: LinksysRouteConfig(noNaviRail: true),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - input code',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));

    await testHelper.pumpView(
      tester,
      child: const LocalRouterRecoveryView(),
      locale: locale,
      config: LinksysRouteConfig(noNaviRail: true),
    );

    await tester.pump(Duration(seconds: 1));

    tester.widget<AppPinCodeInput>(find.byType(AppPinCodeInput)).controller?.text = '12345';
    await tester.pumpAndSettle();
  });

  testLocalizations('local router recovery view - wrong input code',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 2),
    );

    await testHelper.pumpView(
      tester,
      child: const LocalRouterRecoveryView(),
      locale: locale,
      config: LinksysRouteConfig(noNaviRail: true),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - last chance',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 1),
    );

    await testHelper.pumpView(
      tester,
      child: const LocalRouterRecoveryView(),
      locale: locale,
      config: LinksysRouteConfig(noNaviRail: true),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - being locked',
      (tester, locale) async {
    when(testHelper.mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 0),
    );

    await testHelper.pumpView(
      tester,
      child: const LocalRouterRecoveryView(),
      locale: locale,
      config: LinksysRouteConfig(noNaviRail: true),
    );

    await tester.pump(Duration(seconds: 1));
  });
}