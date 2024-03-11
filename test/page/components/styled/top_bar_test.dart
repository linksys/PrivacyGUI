import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg_test/flutter_svg_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/top_bar.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../common/config.dart';
import '../../../common/mock_firebase_messaging.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mock_notifiers/mock_auth_notifier.dart';

void main() async {
  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;
  late AuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
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
            LinksysRoute(path: '/', builder: (context, state) => const Center())
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(Symbols.person);
      expect(settingsFinder, findsOneWidget);
      final notificationsFinder = find.byIcon(Symbols.notifications);
      expect(notificationsFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test top bar with Linksys logo should displsy on mobile variants',
    variants: responsiveMobileVariants,
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      // Find Build Context
      final BuildContext context = tester.element(find.byType(TopBar));
      final asset = CustomTheme.of(context).images.linksysLogoBlack;
      final logoFinder = find.svg(asset);
      expect(logoFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test top bar with Linksys logo should not displsy on desktop variants',
    variants: responsiveDesktopVariants,
    (tester) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          provider: provider,
          overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      // Find Build Context
      final BuildContext context = tester.element(find.byType(TopBar));
      final asset = CustomTheme.of(context).images.linksysLogoBlack;
      final logoFinder = find.svg(asset);
      expect(logoFinder, findsNothing);
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
            LinksysRoute(path: '/', builder: (context, state) => const Center())
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(Symbols.person);
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
            LinksysRoute(path: '/', builder: (context, state) => const Center())
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(Symbols.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      final logoutFinder = find.text('Log out');
      expect(logoutFinder, findsOneWidget);
    },
  );
}
