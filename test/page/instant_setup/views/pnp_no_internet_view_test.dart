@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_ending.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_no_internet_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_internet_troubleshooting.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

void main() {
  late int bypassCalls;
  late String currentLocation;

  /// PnP's ending as the route layer hands it to the hub (#1511 P1), recording
  /// the "continue without internet" it runs before going where it answers.
  TroubleshootingEnding pnpEnding() => TroubleshootingEnding(
        exitLocation: RoutePath.pnp,
        continueWithoutInternet: () async {
          bypassCalls++;
          return RoutePath.uspDashboard;
        },
      );

  // The view is taller than the default 800x600 test surface; enlarge it so
  // the bottom buttons are on-screen and tappable.
  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host({TroubleshootingEnding? ending}) {
    bypassCalls = 0;
    final hubEnding = ending ?? pnpEnding();
    final router = GoRouter(
      initialLocation: '/troubleshooting',
      routes: [
        GoRoute(
          path: '/troubleshooting',
          builder: (_, __) => PnpNoInternetView(ending: hubEnding),
        ),
        GoRoute(
          path: RoutePath.uspDashboard,
          builder: (_, __) => const Scaffold(body: Text('DASHBOARD_STUB')),
        ),
        GoRoute(
          path: RoutePath.pnp,
          builder: (_, __) => const Scaffold(body: Text('PNP_STUB')),
        ),
      ],
    );
    router.routerDelegate.addListener(() {
      currentLocation =
          router.routerDelegate.currentConfiguration.uri.toString();
    });
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...internetTroubleshootingOverrides(),
      ],
      child: MaterialApp.router(
        theme: _testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Freeze looping animations (e.g. AppLoader) so pump() settles;
        // otherwise pumpAndSettle never returns.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows both Log into router and Try again buttons',
      (tester) async {
    enlargeSurface(tester);
    await tester.pumpWidget(host());
    await _settle(tester);

    expect(find.text('Log into router'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('tapping Log into router bypasses and navigates to dashboard',
      (tester) async {
    enlargeSurface(tester);
    await tester.pumpWidget(host());
    await _settle(tester);

    await tester.tap(find.text('Log into router'));
    await _settle(tester);

    expect(bypassCalls, 1);
    expect(currentLocation, RoutePath.uspDashboard);
    expect(find.text('DASHBOARD_STUB'), findsOneWidget);
  });

  testWidgets('a caller with nothing to continue into offers no bypass',
      (tester) async {
    // The dashboard's ending (#1511 P1): there is no setup to acknowledge, so
    // the hub has no "Log into router" — and "Try again" is still there.
    enlargeSurface(tester);
    await tester.pumpWidget(host(
      ending: const TroubleshootingEnding(exitLocation: RoutePath.uspDashboard),
    ));
    await _settle(tester);

    expect(find.text('Log into router'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}

/// Bounded pump — the view contains an [AppLoader] whose animation never fully
/// settles even with disableAnimations, so pumpAndSettle would time out. A few
/// fixed frames are enough for navigation + rebuilds to flush.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
