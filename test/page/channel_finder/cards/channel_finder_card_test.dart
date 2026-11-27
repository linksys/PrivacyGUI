import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/channel_finder/cards/channel_finder_card.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_provider.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/channel_finder_test_data.dart';

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The session's scan, pinned to one state, with [scan] recorded by mocktail.
class _MockChannelFinderNotifier extends Notifier<ChannelFinderState>
    with Mock
    implements ChannelFinderNotifier {
  _MockChannelFinderNotifier(this._initial);

  final ChannelFinderState _initial;

  @override
  ChannelFinderState build() => _initial;

  /// Moves the pinned state, as a finishing scan would.
  void emit(ChannelFinderState next) => state = next;
}

const _pageText = 'channel finder page';

/// The card in its normal form, in a box the size its spec prefers (three rows,
/// 392px), under a router whose only other page is the Channel Finder page.
Future<GoRouter> _pumpCard(
  WidgetTester tester,
  _MockChannelFinderNotifier notifier,
) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const Scaffold(
        body: SizedBox(
          width: 400,
          height: 392,
          child: CardDensityScope(
            density: CardDensity.normal,
            cardId: 'channel_finder',
            child: ChannelFinderCard(),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'channel-finder',
          name: RouteNamed.uspChannelFinder,
          builder: (_, __) => const Scaffold(body: Text(_pageText)),
        ),
      ],
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [channelFinderProvider.overrideWith(() => notifier)],
    child: MaterialApp.router(
      theme: _theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  // Not `pumpAndSettle`: a running scan's loader and busy button never stop
  // animating.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return router;
}

Finder get _scanButton => find.byWidgetPredicate(
    (w) => w is AppButton && w.identifier == 'channel-finder-card-scan');

AppButton _scanButtonOf(WidgetTester tester) =>
    tester.widget<AppButton>(_scanButton);

/// The name of the route on top, read from the router's own state; null for
/// the unnamed root the card sits on.
String? _topRoute(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.route.name;

void main() {
  late _MockChannelFinderNotifier notifier;

  _MockChannelFinderNotifier stub(ChannelFinderState state) {
    notifier = _MockChannelFinderNotifier(state);
    when(() => notifier.scan()).thenAnswer((_) async {});
    return notifier;
  }

  group('before any scan', () {
    testWidgets('says there is no scan and offers Scan', (tester) async {
      await _pumpCard(tester, stub(const ChannelFinderState()));

      expect(find.text('Channel Finder'), findsOneWidget);
      expect(find.text('No scan yet. Scan to see how busy each channel is.'),
          findsOneWidget);
      expect(_scanButtonOf(tester).label, 'Scan');
      expect(_scanButtonOf(tester).isLoading, isFalse);
      expect(find.textContaining('Last scan'), findsNothing);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('does not scan on its own', (tester) async {
      await _pumpCard(tester, stub(const ChannelFinderState()));

      verifyNever(() => notifier.scan());
    });

    testWidgets('has no value for the popup form, so the tile shows its name',
        (tester) async {
      await _pumpCard(tester, stub(const ChannelFinderState()));

      expect(
        tester
            .widget<DashboardCardTemplate>(find.byType(DashboardCardTemplate))
            .popupValue,
        isNull,
      );
    });
  });

  group('the Scan button', () {
    testWidgets('starts a scan, and does not open the page', (tester) async {
      final router = await _pumpCard(tester, stub(const ChannelFinderState()));

      await tester.tap(_scanButton);
      await tester.pump();

      verify(() => notifier.scan()).called(1);
      expect(_topRoute(router), isNull);
      expect(find.text(_pageText), findsNothing);
    });

    testWidgets('reads Scan again once there is a result', (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderTestData.result(),
          )));

      expect(_scanButtonOf(tester).label, 'Scan again');
    });

    testWidgets('can be pressed again once a running scan finishes',
        (tester) async {
      // A bench screenshot (#1778, 2026-11-26) showed the button pale after a
      // scan; that was its hover style, the pointer left on it. This pins that
      // the card hands the button back enabled and not loading.
      final n = stub(ChannelFinderState(
        phase: ChannelFinderPhase.scanning,
        stage: ChannelFinderScanStage.channels,
        lastResult: ChannelFinderTestData.result(),
      ));
      await _pumpCard(tester, n);
      expect(_scanButtonOf(tester).onTap, isNull);

      n.emit(ChannelFinderState(
        phase: ChannelFinderPhase.done,
        lastResult: ChannelFinderTestData.result(),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final button = _scanButtonOf(tester);
      expect(button.isLoading, isFalse);
      expect(button.onTap, isNotNull);
      expect(button.label, 'Scan again');
    });

    testWidgets('is busy and cannot be pressed while a scan runs',
        (tester) async {
      await _pumpCard(
          tester,
          stub(const ChannelFinderState(
            phase: ChannelFinderPhase.scanning,
          )));

      expect(_scanButtonOf(tester).isLoading, isTrue);
      expect(_scanButtonOf(tester).onTap, isNull);

      await tester.tap(_scanButton, warnIfMissed: false);
      await tester.pump();
      verifyNever(() => notifier.scan());
    });
  });

  group('while scanning', () {
    testWidgets('shows a running bar and that it is listening for networks',
        (tester) async {
      await _pumpCard(
          tester,
          stub(const ChannelFinderState(
            phase: ChannelFinderPhase.scanning,
            stage: ChannelFinderScanStage.neighbors,
          )));

      final loader = tester.widget<AppLoader>(find.byType(AppLoader));
      expect(loader.variant, LoaderVariant.linear);
      expect(loader.value, isNull, reason: 'a scan has no progress to show');
      expect(find.text('Listening for nearby networks…'), findsOneWidget);
      expect(find.textContaining('No scan yet'), findsNothing);
    });

    testWidgets('says when it has moved on to measuring channels',
        (tester) async {
      await _pumpCard(
          tester,
          stub(const ChannelFinderState(
            phase: ChannelFinderPhase.scanning,
            stage: ChannelFinderScanStage.channels,
          )));

      expect(find.text('Measuring how busy each channel is…'), findsOneWidget);
    });

    testWidgets('keeps the last result\'s rows under the bar', (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.scanning,
            stage: ChannelFinderScanStage.channels,
            lastResult: ChannelFinderTestData.result(),
          )));

      expect(find.text('2.4GHz'), findsOneWidget);
      expect(find.text('5GHz'), findsOneWidget);
    });
  });

  group('a finished scan', () {
    Future<void> pumpDone(WidgetTester tester) => _pumpCard(
        tester,
        stub(ChannelFinderState(
          phase: ChannelFinderPhase.done,
          lastResult: ChannelFinderTestData.result(),
        )));

    testWidgets(
        'shows each band\'s channel, how busy it is and the networks on it',
        (tester) async {
      await pumpDone(tester);

      // 2.4 GHz is on channel 1, utilization 60 of 255 (24 %), two networks.
      expect(find.text('2.4GHz'), findsOneWidget);
      expect(find.text('24% busy'), findsOneWidget);
      expect(find.text('Channel 1 · 2 networks'), findsOneWidget);
      // 5 GHz is on channel 48, utilization 11 (4 %), one network.
      expect(find.text('5GHz'), findsOneWidget);
      expect(find.text('4% busy'), findsOneWidget);
      expect(find.text('Channel 48 · 1 network'), findsOneWidget);
      // Only the channel each radio is on: not the page's list of channels.
      expect(find.text('Channel 6 · 1 network'), findsNothing);
    });

    testWidgets('says when it finished', (tester) async {
      await pumpDone(tester);

      expect(find.text('Last scan: 10:54 AM'), findsOneWidget);
    });

    testWidgets(
        'gives the busiest in-use channel to the popup form, as the page words '
        'it', (tester) async {
      await pumpDone(tester);

      expect(
        tester
            .widget<DashboardCardTemplate>(find.byType(DashboardCardTemplate))
            .popupValue,
        '24% busy',
      );
    });

    testWidgets('colours a channel at 50 % or more like the page does',
        (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderResultUIModel(
              scannedAt: DateTime(2026, 11, 26, 10, 54),
              bands: const [
                ChannelBandScanUIModel(
                    band: '2.4GHz',
                    channelInUse: 6,
                    channels: [
                      ChannelScanUIModel(
                          channel: 6,
                          utilization: 128,
                          isInUse: true,
                          neighbors: []),
                    ]),
                ChannelBandScanUIModel(
                    band: '5GHz',
                    channelInUse: 36,
                    channels: [
                      ChannelScanUIModel(
                          channel: 36,
                          utilization: 127,
                          isInUse: true,
                          neighbors: []),
                    ]),
              ],
            ),
          )));

      final element = tester.element(find.byType(ChannelFinderCard));
      final theme = Theme.of(element);
      final bars = tester
          .widgetList<AppLoader>(find.byType(AppLoader))
          .map((l) => l.color)
          .toList();
      // The theme's warning colour at 50 %, the primary below it: both
      // in-use channels, so the colour says busy or not.
      expect(bars, [
        theme.extension<AppColorScheme>()!.semanticWarning,
        theme.colorScheme.primary,
      ]);
    });

    testWidgets('says so when the in-use channel was not measured',
        (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderResultUIModel(
              scannedAt: DateTime(2026, 11, 26, 10, 54),
              bands: const [
                ChannelBandScanUIModel(
                    band: '5GHz',
                    channelInUse: 149,
                    channels: [
                      ChannelScanUIModel(
                          channel: 149,
                          utilization: null,
                          isInUse: true,
                          neighbors: []),
                    ]),
              ],
            ),
          )));

      expect(find.text('Busyness not measured'), findsOneWidget);
      expect(find.text('Channel 149 · No networks'), findsOneWidget);
      expect(
        tester
            .widget<DashboardCardTemplate>(find.byType(DashboardCardTemplate))
            .popupValue,
        'Busyness not measured',
      );
    });

    testWidgets(
        'names the channel the router reports even when no scanned channel is '
        'it', (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderResultUIModel(
              scannedAt: DateTime(2026, 11, 26, 10, 54),
              bands: const [
                ChannelBandScanUIModel(
                    band: '5GHz', channelInUse: 165, channels: []),
              ],
            ),
          )));

      expect(find.text('Busyness not measured'), findsOneWidget);
      expect(find.text('Channel 165'), findsOneWidget);
    });
  });

  group('a failed scan', () {
    testWidgets('says why, and keeps the last result', (tester) async {
      await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.failed,
            lastResult: ChannelFinderTestData.result(),
            error: const TimeoutError(),
          )));

      expect(find.text('The operation timed out. Please try again.'),
          findsOneWidget);
      expect(find.text('2.4GHz'), findsOneWidget);
      expect(_scanButtonOf(tester).label, 'Scan again');
    });

    testWidgets('with no result before it, says why and not "no scan yet"',
        (tester) async {
      await _pumpCard(
          tester,
          stub(const ChannelFinderState(
            phase: ChannelFinderPhase.failed,
            error: TimeoutError(),
          )));

      expect(find.text('The operation timed out. Please try again.'),
          findsOneWidget);
      expect(find.textContaining('No scan yet'), findsNothing);
      expect(_scanButtonOf(tester).label, 'Scan');
    });
  });

  group('View details', () {
    testWidgets('opens the Channel Finder page, and starts no scan',
        (tester) async {
      final router = await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderTestData.result(),
          )));

      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();

      expect(find.text(_pageText), findsOneWidget);
      expect(_topRoute(router), RouteNamed.uspChannelFinder);
      verifyNever(() => notifier.scan());
    });

    testWidgets('opens the page before any scan too', (tester) async {
      final router = await _pumpCard(tester, stub(const ChannelFinderState()));

      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();

      expect(_topRoute(router), RouteNamed.uspChannelFinder);
    });

    testWidgets('the band tiles only show: tapping one opens nothing',
        (tester) async {
      final router = await _pumpCard(
          tester,
          stub(ChannelFinderState(
            phase: ChannelFinderPhase.done,
            lastResult: ChannelFinderTestData.result(),
          )));

      await tester.tap(find.text('5GHz'));
      await tester.pumpAndSettle();

      expect(_topRoute(router), isNull);
      verifyNever(() => notifier.scan());
    });
  });

  group('E2E hooks (constitution Article XVI)', () {
    testWidgets(
        'the detail link and the scan button each publish one tappable node, '
        'and neither covers the other', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _pumpCard(
            tester,
            stub(ChannelFinderState(
              phase: ChannelFinderPhase.done,
              lastResult: ChannelFinderTestData.result(),
            )));

        final open = find.bySemanticsIdentifier('card-detail-channel-finder');
        final scan = find.bySemanticsIdentifier('channel-finder-card-scan');
        expect(open, findsOneWidget);
        expect(scan, findsOneWidget);
        expect(tester.getSemantics(open),
            isSemantics(isButton: true, hasTapAction: true));
        expect(tester.getSemantics(scan), isSemantics(hasTapAction: true));
        expect(tester.getRect(open).overlaps(tester.getRect(scan)), isFalse);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('tapping the detail hook navigates', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final router = await _pumpCard(
            tester,
            stub(ChannelFinderState(
              phase: ChannelFinderPhase.done,
              lastResult: ChannelFinderTestData.result(),
            )));

        await tester
            .tap(find.bySemanticsIdentifier('card-detail-channel-finder'));
        await tester.pumpAndSettle();

        expect(_topRoute(router), RouteNamed.uspChannelFinder);
      } finally {
        handle.dispose();
      }
    });
  });
}
