import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/_index.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late MockRouterPasswordNotifier mockRouterPasswordNotifier;

  setUp(() {
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
  });

  testLocalizations('local router recovery view - init state',
      (tester, locale) async {
    when(mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalRouterRecoveryView(),
        locale: locale,
        config: LinksysRouteConfig(noNaviRail: true),
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - wrong input code',
      (tester, locale) async {
    when(mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 2),
    );

    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalRouterRecoveryView(),
        locale: locale,
        config: LinksysRouteConfig(noNaviRail: true),
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - last chance',
      (tester, locale) async {
    when(mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 1),
    );

    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalRouterRecoveryView(),
        locale: locale,
        config: LinksysRouteConfig(noNaviRail: true),
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );

    await tester.pump(Duration(seconds: 1));
  });

  testLocalizations('local router recovery view - being locked',
      (tester, locale) async {
    when(mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(remainingErrorAttempts: 0),
    );

    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalRouterRecoveryView(),
        locale: locale,
        config: LinksysRouteConfig(noNaviRail: true),
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );

    await tester.pump(Duration(seconds: 1));
  });
}
