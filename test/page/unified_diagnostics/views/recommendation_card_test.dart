import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/recommendation_card.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

const _busyChannel = RecommendationUIModel(
  id: 'busy_channel',
  titleKey: 'diagnostics_rec_busy_channel_title',
  descriptionKey: 'diagnostics_rec_busy_channel_desc',
  priority: 7,
  actionId: RecommendationUIModel.openChannelFinder,
);

const _weakWifi = RecommendationUIModel(
  id: 'weak_wifi',
  titleKey: 'diagnostics_rec_weak_wifi_title',
  descriptionKey: 'diagnostics_rec_weak_wifi_desc',
  priority: 7,
  actionId: 'moveCloser',
);

/// The card under a router whose only other page is Channel Finder.
Future<GoRouter> _pump(WidgetTester tester, RecommendationUIModel rec) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => Scaffold(body: RecommendationCard(rec: rec)),
      routes: [
        GoRoute(
          path: 'channel-finder',
          name: RouteNamed.uspChannelFinder,
          builder: (_, __) => const Scaffold(body: Text('CHANNEL FINDER')),
        ),
      ],
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    theme: AppTheme.create(
      brightness: Brightness.light,
      seedColor: Colors.blue,
      designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.pumpAndSettle();
  return router;
}

Finder get _openButton => find.byWidgetPredicate((w) =>
    w is AppButton && w.identifier == 'diagnostics-rec-open-channel-finder');

void main() {
  testWidgets('a busy channel shows its text and opens Channel Finder (#1778)',
      (tester) async {
    final router = await _pump(tester, _busyChannel);

    expect(find.text('Busy WiFi Channel'), findsOneWidget);
    expect(_openButton, findsOneWidget);

    await tester.tap(_openButton);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.last.route.name,
        RouteNamed.uspChannelFinder);
    expect(find.text('CHANNEL FINDER'), findsOneWidget);
  });

  testWidgets('a recommendation with another action offers no button',
      (tester) async {
    await _pump(tester, _weakWifi);

    expect(find.text('Weak WiFi Signal'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });
}
