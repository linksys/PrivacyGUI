// #1580 / epic #1575 — where notification history is entered from.
//
// THE DECISION GUARDED. The way in to notification history lives in the popup the
// Remote Assistance chip opens, not in the menu. The history is *this session's*:
// Guardian scopes it by the session id and it cannot be read once the session is
// over, so it belongs beside the session's status and its End Session button. It
// also needs no mode check of its own — only the remote surface mounts this chip
// (`RemoteSurface.sessionIndicator`), so "a local build has no way in" is true by
// the chip not existing there.
//
// HOW IT COULD SILENTLY REVERT. Four substitutions, none of which crash:
//   - the entry wired with `go` instead of `push`, which replaces the stack — so
//     the back arrow lands on the page's `backFallback` rather than on the page
//     the popup was opened over (the class of bug in #1029/#1420/#1421);
//   - navigating without closing the popup, which leaves an `OverlayEntry` sitting
//     over the history page with its transparent full-screen backdrop swallowing
//     every tap;
//   - `pushNamed` instead of `pushNamedIfNotCurrent`: the chip is on the history
//     page too, so a tap there stacks a duplicate the screen does not show, and
//     back needs an extra press to leave;
//   - the E2E identifier composed or renamed, which the harvester reads as source
//     text and so drops silently on both sides.
//
// WHY THIS TEST TYPE. A widget test with a real `GoRouter` holding two stub
// routes: the assertion that matters is about the navigation stack, which only a
// router can answer. The chip's geometry is not asserted — nothing here is a
// layout claim.
//
// Not tagged `ui`: the two CI jobs exclude `golden||loc||ui`, so a tagged case
// would never run.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/remote_session_chip.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../../core/usp/mocks.dart';
import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/test_data/remote_assistance_test_data.dart';
import '../../../util/app_test_fonts.dart';

/// Holds a fixed session and starts nothing.
///
/// The real `build()` restores from `sessionStorage` and, when it finds a
/// session, starts a one-second countdown and a poll — neither of which has
/// anything to talk to in a VM test, and a periodic timer keeps `pumpAndSettle`
/// from ever settling.
class _FixedRemoteAccessNotifier extends RemoteAccessNotifier {
  @override
  RemoteAccessState build() => RemoteAccessState(
        sessionInfo: RemoteAssistanceTestData.activeSession(),
        sessionToken: RemoteAssistanceTestData.testSessionToken,
        remainingSeconds: 1200,
        expiryTime: DateTime.now().add(const Duration(minutes: 20)),
      );
}

class _MockConnection extends Mock implements SseConnectionManager {}

const _originPage = Key('origin-page');
const _historyPage = Key('history-page');

void main() {
  late AppLocalizations loc;
  late StreamController<SseConnectionState> sse;
  late MockSseManager manager;
  late _MockConnection connection;

  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    sse = StreamController<SseConnectionState>.broadcast();
    manager = MockSseManager();
    connection = _MockConnection();
    when(() => manager.connection).thenReturn(connection);
    when(() => connection.lastDisconnectCause)
        .thenReturn(SseDisconnectCause.none);
  });

  tearDown(() => sse.close());

  final localizations = <String, AppLocalizations>{};
  AppLocalizations localizationsFor(String code) => localizations[code]!;
  setUpAll(() async {
    for (final code in ['de', 'fr', 'ru', 'el']) {
      localizations[code] = await AppLocalizations.delegate.load(Locale(code));
    }
  });

  Future<GoRouter> pump(WidgetTester tester,
      {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The chip is a `Positioned`, so it is mounted the way the dashboard shell
    // mounts it: in a `Stack` above whatever page is showing.
    final router = GoRouter(
      initialLocation: '/origin',
      routes: [
        GoRoute(
          path: '/origin',
          builder: (context, state) => const Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(key: _originPage),
                RemoteSessionChip(),
              ],
            ),
          ),
        ),
        GoRoute(
          path: RoutePath.uspNotificationHistory,
          name: RouteNamed.uspNotificationHistory,
          // The chip on this page too: the shell mounts it over every page,
          // including the one this entry opens.
          builder: (context, state) => const Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(key: _historyPage),
                RemoteSessionChip(),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        remoteAccessProvider.overrideWith(_FixedRemoteAccessNotifier.new),
        sseManagerProvider.overrideWithValue(manager),
        sseConnectionStateProvider.overrideWith((ref) => sse.stream),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
        // The app wraps the navigator in a `Material` (`lib/app.dart`), and the
        // popup depends on it: it is an `OverlayEntry`, so it sits above every
        // page's `Scaffold`, and its close button is an `InkWell`. Without this
        // layer the popup throws on build here while working in the product.
        builder: (context, child) => Material(child: child),
      ),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openPopup(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.support_agent));
    await tester.pumpAndSettle();
  }

  group('RemoteSessionChip - notification history entry in the session popup',
      () {
    testWidgets('the popup offers it, beside End Session', (tester) async {
      await pump(tester);
      await openPopup(tester);

      expect(find.text(loc.notificationHistory), findsOneWidget);
      expect(find.text(loc.endSession), findsOneWidget,
          reason: 'the popup it was added to, not some other surface');
    });

    testWidgets('it is not offered before the popup is opened', (tester) async {
      // The chip itself stays a timer. The entry is a second action, and the
      // chip's one job at rest is to say how long the session has left.
      await pump(tester);

      expect(find.text(loc.notificationHistory), findsNothing);
    });

    testWidgets('tapping it pushes the history page over the current one',
        (tester) async {
      final router = await pump(tester);
      await openPopup(tester);

      await tester.tap(find.text(loc.notificationHistory));
      await tester.pumpAndSettle();

      expect(find.byKey(_historyPage), findsOneWidget);
      // Push, not go: the popup can be opened over any page, so back must return
      // to that page. `go` would replace the stack, leave nothing to pop, and send
      // the back arrow to the history page's `backFallback` instead.
      expect(router.canPop(), isTrue,
          reason: 'the page the popup was opened over must still be under it');

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_originPage), findsOneWidget);
    });

    testWidgets('tapping it on the history page itself adds nothing to back',
        (tester) async {
      // The chip is global chrome — present on every page, the history page
      // included — and go_router does not de-duplicate a push onto the location
      // already on top. So a plain `pushNamed` here stacks a second copy of the
      // page, the screen does not change, and back needs one more press to leave.
      final router = await pump(tester);
      await openPopup(tester);
      await tester.tap(find.text(loc.notificationHistory));
      await tester.pumpAndSettle();

      await openPopup(tester);
      await tester.tap(find.text(loc.notificationHistory));
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_originPage), findsOneWidget,
          reason: 'one back from the history page must leave it, however many '
              'times the entry was tapped while it was showing');
    });

    testWidgets('the popup is gone once the history page is showing',
        (tester) async {
      // The popup is an `OverlayEntry`, above the router's own pages, with a
      // transparent full-screen backdrop that closes it on tap. Left behind, it
      // would sit over the history page and eat the first tap on it.
      await pump(tester);
      await openPopup(tester);

      await tester.tap(find.text(loc.notificationHistory));
      await tester.pumpAndSettle();

      expect(find.text(loc.endSession), findsNothing);
      expect(find.text(loc.notificationHistory), findsNothing);
    });

    testWidgets('the longest label fits the popup without overflowing',
        (tester) async {
      // The popup is a fixed 280 px and the layout gate never renders it: it is
      // an `OverlayEntry`, not a page, so no sweep reaches it. French is the
      // longest label in any locale (28 characters). Measured with the app's own
      // fonts — without them every glyph is a 12 px box and a width assertion
      // is fiction.
      await loadAppFonts();
      await pump(tester, locale: const Locale('fr'));
      await openPopup(tester);

      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(fr.notificationHistory), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'a RenderFlex overflow is reported as an exception');
    });

    testWidgets('it carries the E2E identifier as a literal', (tester) async {
      // The E2E repo harvests identifiers from this file's source text, so the
      // value asserted here is the one its specs will look for.
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await openPopup(tester);

      expect(
        find.bySemanticsIdentifier('ra-notification-history'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // The cloud stream's state, which the banner no longer shows in RA
  // ═════════════════════════════════════════════════════════════════════════
  //
  // THE DECISION GUARDED (Austin, 2026-10-01). Under Remote Assistance the
  // stream runs to Guardian, not the router, so the full-width banner's
  // "Connecting to router" named the wrong thing and sat over every login. The
  // state moved here, beside the session's other facts, worded for the cloud —
  // and #1577's "the device is offline" distinction moved with it.
  group('RemoteSessionChip - live updates row', () {
    Future<void> popupWith(WidgetTester tester, SseConnectionState state,
        {SseDisconnectCause cause = SseDisconnectCause.none}) async {
      when(() => connection.lastDisconnectCause).thenReturn(cause);
      await pump(tester);
      // After opening: the row is what subscribes to the (broadcast) stream,
      // so a state emitted before it existed would be one it never saw.
      await openPopup(tester);
      sse.add(state);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('connected says so', (tester) async {
      await popupWith(tester, SseConnectionState.connected);

      expect(find.text(loc.raLiveUpdates), findsOneWidget);
      expect(find.text(loc.connected), findsOneWidget);
    });

    testWidgets('opening says it is connecting via the cloud, not the router',
        (tester) async {
      await popupWith(tester, SseConnectionState.connecting);

      expect(find.text(loc.raLiveUpdatesConnecting), findsOneWidget);
      expect(find.text(loc.connectingToRouter), findsNothing);
    });

    testWidgets('a dropped stream says the cloud connection dropped',
        (tester) async {
      for (final state in [
        SseConnectionState.reconnecting,
        SseConnectionState.disconnected,
        SseConnectionState.suspended,
      ]) {
        await popupWith(tester, state);
        expect(find.text(loc.raLiveUpdatesDropped), findsOneWidget,
            reason: state.name);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a 400 says the router is offline instead (#1577)',
        (tester) async {
      await popupWith(tester, SseConnectionState.disconnected,
          cause: SseDisconnectCause.deviceOffline);

      expect(find.text(loc.sseRouterOffline), findsOneWidget);
      expect(find.text(loc.raLiveUpdatesDropped), findsNothing);
    });

    testWidgets('the longest row fits the popup without overflowing',
        (tester) async {
      // Same 280 px popup and the same reason as the history entry above: no
      // sweep renders it. The offline sentence is the longest value the row can
      // hold, in the longest locale for it.
      await loadAppFonts();
      when(() => connection.lastDisconnectCause)
          .thenReturn(SseDisconnectCause.deviceOffline);
      for (final code in ['de', 'fr', 'ru', 'el']) {
        await pump(tester, locale: Locale(code));
        await openPopup(tester);
        sse.add(SseConnectionState.disconnected);
        await tester.pump();
        await tester.pump();
        expect(
            find.text(localizationsFor(code).sseRouterOffline), findsOneWidget,
            reason: '$code: the row must actually hold the sentence, or the '
                'overflow check below measured an empty row');
        expect(tester.takeException(), isNull, reason: code);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // The real-router RA spec's way to End Session from the agent side
  // ═════════════════════════════════════════════════════════════════════════
  //
  // `ra-session-chip` opens the popup and `ra-session-end` ends the session —
  // the two taps `R30-remote-assistance` makes to finish its run from this end.
  // Both are asserted as literals for the reason the history entry's is: the E2E
  // repo harvests them from this source text, so a rename here is a silent
  // count-0 there.
  group('RemoteSessionChip - E2E hooks for ending the session', () {
    testWidgets('the chip is a tappable hook that opens the popup',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      final chip = find.bySemanticsIdentifier('ra-session-chip');
      expect(chip, findsOneWidget);
      // Tapped BY THE HOOK, which is what the spec does: an identifier that sits
      // beside the tap target rather than on it would pass a presence check and
      // fail the real run.
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(loc.endSession), findsOneWidget,
          reason: 'tapping the hook must open the session popup');
      semantics.dispose();
    });

    testWidgets('the chip is one button node: countdown, role and tap',
        (tester) async {
      // A bare GestureDetector projects no role, so a screen reader heard only
      // the countdown. The hook's Semantics adds the role; the tap action has to
      // be on the SAME node, because that node is the DOM element a Playwright
      // click lands on, and the countdown stays its label.
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(
        tester.getSemantics(find.bySemanticsIdentifier('ra-session-chip')),
        isSemantics(isButton: true, hasTapAction: true, label: '20:00'),
      );
      semantics.dispose();
    });

    testWidgets('End Session in the popup carries its hook', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await openPopup(tester);

      expect(find.bySemanticsIdentifier('ra-session-end'), findsOneWidget);
      semantics.dispose();
    });
  });
}
