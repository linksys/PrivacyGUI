// The Remote Assistance "setting up live updates" gate (Austin, 2026-10-01).
//
// THE DECISION GUARDED. Under RA the dashboard renders and fetches first and
// subscribes through Guardian afterwards — about a minute on the QA router, one
// subscription every few seconds. An agent acting in that window acts on a page
// that will not update itself. So the shell holds them behind a dialog until the
// core subscriptions are in, with the dashboard visibly filling in behind it.
//
// Three claims:
//   1. It blocks while pending, and lets go once ready.
//   2. It can never trap the agent: it gives up after 90 s, and a registration
//      with failures ends the wait like a clean one — saying so.
//   3. It is for the start of a session only. Once it has let go it stays gone,
//      however the subscription state moves afterwards (a ~10-minute stream
//      close puts it back to pending, and must not raise the dialog).
//
// HOW IT COULD SILENTLY REVERT. A gate keyed on the stream state instead of the
// subscription state lets go the moment the stream opens — 30 s early, with
// nothing subscribed. A gate with no timeout traps the agent forever on the day
// Guardian refuses a subscription.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/remote_session_readiness_gate.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  late AppLocalizations loc;
  late StreamController<CoreSubscriptionState> subs;
  var tapped = 0;

  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    subs = StreamController<CoreSubscriptionState>.broadcast();
    tapped = 0;
  });
  tearDown(() => subs.close());

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sseCoreSubscriptionsProvider.overrideWith((ref) => subs.stream),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        home: Scaffold(
          body: Stack(children: [
            // Stands in for the dashboard behind the gate.
            Center(
              child: TextButton(
                onPressed: () => tapped++,
                child: const Text('dashboard'),
              ),
            ),
            const RemoteSessionReadinessGate(),
          ]),
        ),
      ),
    ));
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, CoreSubscriptionState state) async {
    subs.add(state);
    await tester.pump();
    await tester.pump();
  }

  group('RemoteSessionReadinessGate - waiting', () {
    testWidgets('shows while the core subscriptions are pending',
        (tester) async {
      await pumpGate(tester);
      await emit(tester, const CoreSubscriptionsPending());

      expect(find.text(loc.raPreparingTitle), findsOneWidget);
      expect(find.text(loc.raPreparingBody), findsOneWidget);
    });

    testWidgets('the dashboard behind it is visible but not usable',
        (tester) async {
      await pumpGate(tester);
      await emit(tester, const CoreSubscriptionsPending());

      expect(find.text('dashboard'), findsOneWidget,
          reason: 'the point of a dialog over the page rather than a loader '
              'instead of it: the agent watches the page fill in');
      await tester.tap(find.text('dashboard'), warnIfMissed: false);
      expect(tapped, 0);
    });

    testWidgets('it shows before the first state arrives', (tester) async {
      // The provider has not emitted at all yet — the manager is still being
      // built. That is the start of the wait, not the end of it.
      await pumpGate(tester);

      expect(find.text(loc.raPreparingTitle), findsOneWidget);
    });
  });

  group('RemoteSessionReadinessGate - letting go', () {
    testWidgets('ready closes it, and the dashboard takes taps',
        (tester) async {
      await pumpGate(tester);
      await emit(tester, const CoreSubscriptionsPending());
      await emit(
          tester, const CoreSubscriptionsReady(registered: 7, failed: 0));
      await tester.pumpAndSettle();

      expect(find.text(loc.raPreparingTitle), findsNothing);
      await tester.tap(find.text('dashboard'));
      expect(tapped, 1);
    });

    testWidgets('a registration with failures still closes it, and says so',
        (tester) async {
      await pumpGate(tester);
      await emit(tester, const CoreSubscriptionsPending());
      await emit(
          tester, const CoreSubscriptionsReady(registered: 5, failed: 2));
      await tester.pump();

      expect(find.text(loc.raPreparingTitle), findsNothing);
      expect(find.text(loc.raPreparingPartial), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
      await tester.tap(find.text('dashboard'));
      expect(tapped, 1);
    });

    testWidgets('it gives up after 90 seconds, so it cannot trap the agent',
        (tester) async {
      await pumpGate(tester);
      await emit(tester, const CoreSubscriptionsPending());

      await tester.pump(const Duration(seconds: 89));
      expect(find.text(loc.raPreparingTitle), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text(loc.raPreparingTitle), findsNothing);
      expect(find.text(loc.raPreparingPartial), findsOneWidget,
          reason: 'giving up is the same as a partial registration: the page '
              'works, it may just not update itself');
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('once it has let go it does not come back', (tester) async {
      // A routine Guardian stream close puts the subscriptions back to
      // pending; raising the dialog over a session in progress would be wrong.
      await pumpGate(tester);
      await emit(
          tester, const CoreSubscriptionsReady(registered: 7, failed: 0));
      await tester.pumpAndSettle();

      await emit(tester, const CoreSubscriptionsPending());
      await tester.pumpAndSettle();

      expect(find.text(loc.raPreparingTitle), findsNothing);
    });
  });
}
