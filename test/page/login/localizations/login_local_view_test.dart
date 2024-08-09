import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/device_info_test_data.dart';
import '../../../mocks/dashboard_manager_notifier_mocks.dart';

void main() async {
  late DashboardManagerNotifier mockDashboardManagerNotifier;
  late MockRouterRepository mockRouterRepository;

  setUp(() {
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    when(mockDashboardManagerNotifier.checkDeviceInfo(null)).thenAnswer(
        (realInvocation) async =>
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']));
  });

  mockRouterRepository = MockRouterRepository();
  when(mockRouterRepository.send(JNAPAction.getAdminPasswordHint))
      .thenAnswer((realInvocation) async => JNAPSuccess.fromJson(const {
            "result": "OK",
            "output": {"passwordHint": "Link123"}
          }));
  testLocalizations(
    'login local view - init state',
    (tester, locale) async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            routerRepositoryProvider
                .overrideWith((ref) => mockRouterRepository),
          ],
        ),
      );

      await tester.pumpAndSettle();
    },
  );
  testLocalizations(
    'login local view - input password',
    (tester, locale) async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            routerRepositoryProvider
                .overrideWith((ref) => mockRouterRepository),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final passwordFinder = find.byType(AppPasswordField);
      await tester.enterText(passwordFinder, 'Password!!!');
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'login local view - input password visible',
    (tester, locale) async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            routerRepositoryProvider
                .overrideWith((ref) => mockRouterRepository),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final passwordFinder = find.byType(AppPasswordField);
      await tester.enterText(passwordFinder, 'Password!!!');
      await tester.pumpAndSettle();
      final secureFinder = find.byIcon(LinksysIcons.visibility);
      await tester.tap(secureFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'login local view - failed to login',
    (tester, locale) async {
      when(mockRouterRepository.send(
        JNAPAction.checkAdminPassword,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: false,
        type: null,
        fetchRemote: false,
        cacheLevel: CacheLevel.noCache,
        timeoutMs: 10000,
        retries: 1,
        sideEffectOverrides: null,
      )).thenThrow(JNAPError.fromJson(const {
        "result": "ErrorInvalidAdminPassword",
        "output": {"attemptsRemaining": 4, "delayTimeRemaining": 5}
      }));
      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            routerRepositoryProvider
                .overrideWith((ref) => mockRouterRepository),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final passwordFinder = find.byType(AppPasswordField);
      await tester.enterText(passwordFinder, 'Password!!!');
      await tester.pumpAndSettle();
      final secureFinder = find.byIcon(LinksysIcons.visibility);
      await tester.tap(secureFinder);
      await tester.pumpAndSettle();

      final loginFinder = find.byType(AppFilledButton);
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();
    },
  );
}
