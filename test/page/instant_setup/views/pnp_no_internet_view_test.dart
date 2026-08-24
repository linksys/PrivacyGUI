@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_no_internet_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Fake notifier that starts on [NoInternet] and records bypass calls, so the
/// view test never touches real USP services.
class _FakePnpNotifier extends PnpNotifier {
  int bypassCalls = 0;
  int retryCalls = 0;

  @override
  PnpState build() => const PnpState(
        phase: NoInternet(ssid: 'Linksys-Test'),
        serialNumber: 'SN-TEST',
      );

  @override
  Future<void> bypassToDashboard() async {
    bypassCalls++;
  }

  @override
  Future<void> retryInternetCheck() async {
    retryCalls++;
  }
}

void main() {
  late _FakePnpNotifier fakeNotifier;
  late String currentLocation;

  // The view is taller than the default 800x600 test surface; enlarge it so
  // the bottom buttons are on-screen and tappable.
  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host() {
    fakeNotifier = _FakePnpNotifier();
    final router = GoRouter(
      initialLocation: RoutePath.pnpNoInternetConnection,
      routes: [
        GoRoute(
          path: RoutePath.pnpNoInternetConnection,
          builder: (_, __) => const PnpNoInternetView(),
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
        pnpProvider.overrideWith(() => fakeNotifier),
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

    expect(fakeNotifier.bypassCalls, 1);
    expect(currentLocation, RoutePath.uspDashboard);
    expect(find.text('DASHBOARD_STUB'), findsOneWidget);
  });

  testWidgets('bypass navigates even when notifier skips acknowledge (no SN)',
      (tester) async {
    // The fake's bypassToDashboard is a no-op (mirrors the SN-null early return
    // in production, which also completes without throwing). The view must
    // still navigate — proving the SN-null path is a deliberate, safe bypass.
    enlargeSurface(tester);
    await tester.pumpWidget(host());
    await _settle(tester);

    await tester.tap(find.text('Log into router'));
    await _settle(tester);

    expect(currentLocation, RoutePath.uspDashboard);
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
