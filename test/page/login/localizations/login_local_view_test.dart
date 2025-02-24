import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/device_info_test_data.dart';

void main() async {
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockAuthNotifier mockAuthNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    when(mockDashboardManagerNotifier.checkDeviceInfo(null)).thenAnswer(
      (realInvocation) async =>
          NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
    );

    mockAuthNotifier = MockAuthNotifier();
    when(mockAuthNotifier.build()).thenAnswer(
      (_) async => Future.value(
        AuthState.empty().copyWith(localPasswordHint: 'Linksys'),
      ),
    );
    when(mockAuthNotifier.getPasswordHint()).thenAnswer((_) async {});
    when(mockAuthNotifier.getAdminPasswordAuthStatus(any))
        .thenAnswer((_) async => null);
  });

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
            authProvider.overrideWith(() => mockAuthNotifier),
          ],
        ),
      );

      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'login local view - input password masked',
    (tester, locale) async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            authProvider.overrideWith(() => mockAuthNotifier),
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
            authProvider.overrideWith(() => mockAuthNotifier),
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
    'login local view - failed to login with auth status',
    (tester, locale) async {
      when(mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          "attemptsRemaining": 4,
          "delayTimeRemaining": 5,
        };
      });

      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            authProvider.overrideWith(() => mockAuthNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'login local view - failed to login with auth status and too many attempts',
    (tester, locale) async {
      when(mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          "attemptsRemaining": 0,
        };
      });

      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            authProvider.overrideWith(() => mockAuthNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'login local view - failed to login without auth status',
    (tester, locale) async {
      when(mockAuthNotifier.getAdminPasswordAuthStatus(any))
          .thenAnswer((_) async {
        return {
          "attemptsRemaining": null,
          "delayTimeRemaining": 5,
        };
      });

      await tester.pumpWidget(
        testableSingleRoute(
          child: const LoginLocalView(),
          locale: locale,
          overrides: [
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            authProvider.overrideWith(() => mockAuthNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    },
  );
}
