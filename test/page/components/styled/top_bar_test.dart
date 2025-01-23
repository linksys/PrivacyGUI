import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg_test/flutter_svg_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/mock_auth_notifier.dart';

void main() async {
  late AuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockSimpleAuthNotifier();
  });

  testResponsiveWidgets(
    'Test top bar with icons',
    variants: responsiveAllVariants,
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) =>
                    const StyledAppPageView(child: Center()))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      expect(settingsFinder, findsOneWidget);
      // final notificationsFinder = find.byIcon(LinksysIcons.notifications);
      // expect(notificationsFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test top bar with Linksys logo should displsy on mobile variants',
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) =>
                    const StyledAppPageView(child: Center()))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      expect(find.text('Linksys Now'), findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test general settings menu should not has log out button when not log in yet',
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) =>
                    const StyledAppPageView(child: Center()))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      final logoutFinder = find.text('Log out');
      expect(logoutFinder, findsNothing);
    },
  );

  testResponsiveWidgets(
    'Test general settings menu should has log out button when logged in.',
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) =>
                    const StyledAppPageView(child: Center()))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      final logoutFinder = find.text('Log out');
      expect(logoutFinder, findsOneWidget);
    },
  );
}
