import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/_index.dart';

void main() {
  late MockRouterPasswordNotifier mockRouterPasswordNotifier;

  setUp(() {
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
    when(mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
  });

  testLocalizations('local reset router password view - init state',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalResetRouterPasswordView(),
        locale: locale,
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );

    await tester.pumpAndSettle();
  });

  testLocalizations('local reset router password view - input password masked',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalResetRouterPasswordView(),
        locale: locale,
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder, 'Linksys');
    await tester.pumpAndSettle();
  });

  testLocalizations('local reset router password view - input password visible',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalResetRouterPasswordView(),
        locale: locale,
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder, 'Linksys');
    await tester.pumpAndSettle();
    // Tap eye icon
    final secureIconFinder = find.byIcon(LinksysIcons.visibility);
    await tester.tap(secureIconFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'local reset router password view - input password visible and hint',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalResetRouterPasswordView(),
        locale: locale,
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder, 'Linksys');
    await tester.pumpAndSettle();
    // Tap eye icon
    final secureIconFinder = find.byIcon(LinksysIcons.visibility);
    await tester.tap(secureIconFinder);
    await tester.pumpAndSettle();
    // Input hint
    final hintFinder = find.byType(AppTextField).last;
    await tester.enterText(hintFinder, 'Linksys');
    await tester.pumpAndSettle();
  });

  testLocalizations('local reset router password view - success prompt',
      (tester, locale) async {
    when(mockRouterPasswordNotifier.build()).thenReturn(
      RouterPasswordState.fromMap(routerPasswordTestState1)
          .copyWith(isValid: true),
    );

    await tester.pumpWidget(
      testableSingleRoute(
        child: const LocalResetRouterPasswordView(),
        locale: locale,
        overrides: [
          routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Input new password
    final passwordFinder = find.byType(AppPasswordField);
    await tester.enterText(passwordFinder, 'Linksys123!');
    await tester.pumpAndSettle();
    // Tap save
    final saveFinder = find.byType(AppFilledButton);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();
  });
}
