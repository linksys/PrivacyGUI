// #1497 acceptance 7b: the SSE banner renders under the Remote Assistance
// profile, and says the right thing when it does.
//
// THE BEHAVIOUR CHANGE. This is the one surface in phase 7 that is not a pure
// refactor, so it is the one that needs its own assertions rather than a
// composition check. The banner used to open with
//
//     if (GlobalConfig.remote.isActive) return const SizedBox.shrink();
//
// on the stated grounds that SSE is "not supported via the Guardian proxy". It is
// supported — the stream runs, it is just short-lived: Guardian force-closes the
// proxied stream at roughly ten minutes. So a support engineer had a dashboard
// that silently stopped updating with no indication, while the router's owner in
// the same situation got a red banner.
//
// Deleting the early return alone would have swapped one wrong answer for
// another: local classifies `disconnected` as a fault, and in a support session
// the most routine event in the session would then be permanently red. Hence
// `SurfaceStrategy.connectionBannerLevel` — the same states, reported at a
// different volume — and hence the three claims this file makes:
//
//   1. Remote sees the banner at all (the deleted early return).
//   2. A routine ~10-minute close is a WARNING, after the grace period, not
//      danger. Local's same state is danger, immediately.
//   3. "Reconnect" is offered in both, and re-registers subscriptions rather than
//      just reopening a socket.
//
// Claim 3's second half lives at the other end of the wire, in
// `test/core/usp/services/sse_remote_strategy_test.dart`: this file verifies the
// button asks `SseManager.tryReconnect()`, that file verifies what the remote
// strategy does on the resulting `onSseConnected`. Split because the seam between
// them is the manager, which is mocked here.
//
// WHAT THE "401 shows session-revoked" CLAUSE BECAME. The issue also asked for a
// 401 on the RA bridge to surface as a session-revoked message here. It cannot: a
// 401 calls `onAuthFailed` → `logout()`, which tears the session down and unmounts
// the shell this banner lives in. There is no frame in which a revoked-session
// banner could be read. The clause was dropped rather than implemented; the
// terminal surface for that path is the confirm page's session-ended view, which
// `#1323` phase 5 already routes to.
//
// Not tagged `ui`: `run_tests.sh` excludes golden||loc||ui, and this must run in
// the one CI test job.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/sse_connection_banner.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../core/usp/mocks.dart';

/// Seeds `authenticated` without running the real `build()`, which listens to
/// `authProvider` and `sseConnectionStateProvider` and wires
/// `onReconnectFailed` — none of which this banner reads. The banner's only
/// interest in this provider is the one early return for
/// [AppConnectionState.waitingForRecovery], and that is asserted by driving the
/// state, not by driving what produces it.
class _StubConnectionState extends AppConnectionStateNotifier {
  _StubConnectionState(this._seed);
  final AppConnectionState _seed;

  @override
  AppConnectionState build() => _seed;
}

/// The theme carries the real [AppColorScheme], so the warning/danger assertions
/// compare against the colours the app ships rather than the widget's
/// `Colors.orange`/`Colors.red` fallbacks — which would pass whether or not the
/// extension was found.
final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

void main() {
  late MockSseManager manager;
  late StreamController<SseConnectionState> sse;

  setUp(() {
    manager = MockSseManager();
    when(() => manager.tryReconnect()).thenAnswer((_) async => true);
    sse = StreamController<SseConnectionState>.broadcast();
  });

  tearDown(() => sse.close());

  /// Pumps the banner alone under [profile].
  ///
  /// The mode is selected by overriding `appModeProfileProvider` — falsification
  /// criterion 2 of #1474 — and *not* by overriding `surfaceStrategyProvider`
  /// directly, even though that is one line shorter. Going through the profile is
  /// what proves the banner is reachable from the lever the rest of the suite
  /// pulls; a direct surface override would keep passing on the day the page root
  /// stops deriving its mode from the profile, which is the exact regression
  /// `composition_root_test.dart` was written for.
  Future<void> pumpBanner(
    WidgetTester tester, {
    required AppModeProfile profile,
    AppConnectionState connection = AppConnectionState.authenticated,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appModeProfileProvider.overrideWithValue(profile),
        sseManagerProvider.overrideWithValue(manager),
        sseConnectionStateProvider.overrideWith((ref) => sse.stream),
        appConnectionStateProvider
            .overrideWith(() => _StubConnectionState(connection)),
      ],
      child: MaterialApp(
        theme: _theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Column(children: [SseConnectionBanner()]),
        ),
      ),
    ));
    await tester.pump();
  }

  /// Pushes [state] onto the SSE stream and lets the listener run, without
  /// waiting out the grace timer.
  Future<void> emit(WidgetTester tester, SseConnectionState state) async {
    sse.add(state);
    await tester.pump();
  }

  /// The banner's background colour, or null when no banner is rendered.
  Color? bannerColor(WidgetTester tester) {
    final containers = find.descendant(
      of: find.byType(SseConnectionBanner),
      matching: find.byType(Container),
    );
    if (containers.evaluate().isEmpty) return null;
    return tester.widget<Container>(containers.first).color;
  }

  AppColorScheme colors(WidgetTester tester) => Theme.of(
        tester.element(find.byType(SseConnectionBanner)),
      ).extension<AppColorScheme>()!;

  /// A grace period plus the show animation.
  Future<void> waitOutGrace(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('the banner exists under the remote profile at all', () {
    testWidgets('a Guardian stream close is reported, not swallowed',
        (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await waitOutGrace(tester);

      expect(find.text('Disconnected'), findsOneWidget,
          reason: 'this is the deleted early return. Before #1497 the whole '
              'widget was SizedBox.shrink() in RA, so an agent whose stream had '
              'closed saw a dashboard that had silently stopped updating.');
    });

    testWidgets('a healthy stream renders nothing, same as local',
        (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.connected);
      await waitOutGrace(tester);

      expect(bannerColor(tester), isNull);
      expect(find.text('Disconnected'), findsNothing);
    });
  });

  group('severity is the surface\'s call, not the state\'s', () {
    testWidgets('remote: a closed stream is a warning, after the grace period',
        (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      expect(bannerColor(tester), isNull,
          reason:
              'a routine ten-minute close that comes straight back must not '
              'flash anything — the grace period is the whole reason the remote '
              'profile can afford to report this state at all');

      await waitOutGrace(tester);
      expect(bannerColor(tester), colors(tester).semanticWarning);
    });

    testWidgets('local: the same state is danger, immediately', (tester) async {
      await pumpBanner(tester, profile: const LocalModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await tester.pump(const Duration(milliseconds: 400));

      expect(bannerColor(tester), colors(tester).semanticDanger,
          reason:
              'the router is on the other end of a LAN; nothing on that path '
              'should be closing a stream, so a closed one is a fault and says so '
              'without waiting');
    });

    testWidgets('remote: suspended is still danger', (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.suspended);
      await tester.pump(const Duration(milliseconds: 400));

      expect(bannerColor(tester), colors(tester).semanticDanger,
          reason: 'suspended is the manager having given up after its retries, '
              'which no amount of waiting fixes. If this went warning with '
              'everything else, the enum would be a per-mode bool again.');
    });

    testWidgets(
        'remote: a stream that comes back inside the grace period never '
        'shows', (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await tester.pump(const Duration(seconds: 1));
      await emit(tester, SseConnectionState.connected);
      await waitOutGrace(tester);

      expect(bannerColor(tester), isNull);
    });
  });

  group('Reconnect is a property of the connection, not of the mode', () {
    testWidgets('offered in remote, where the state is only a warning',
        (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await waitOutGrace(tester);

      expect(find.text('Reconnect'), findsOneWidget,
          reason: 'until #1497 one `isSevere` expression decided both the '
              'colours and this button. Under the remote profile disconnected is '
              'no longer severe — and it is exactly when the agent needs the '
              'button — so the two questions had to come apart.');
    });

    testWidgets('offered in local too', (tester) async {
      await pumpBanner(tester, profile: const LocalModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Reconnect'), findsOneWidget);
    });

    testWidgets('withheld while the manager is already retrying',
        (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.reconnecting);
      await waitOutGrace(tester);

      expect(find.text('Reconnecting...'), findsOneWidget,
          reason:
              'the banner is showing, so the absence below is the button and '
              'not the banner');
      expect(find.text('Reconnect'), findsNothing,
          reason: 'the button would race the retry already in flight');
    });

    testWidgets('tapping it asks the manager to reconnect', (tester) async {
      await pumpBanner(tester, profile: const RemoteModeProfile());

      await emit(tester, SseConnectionState.disconnected);
      await waitOutGrace(tester);

      await tester.tap(find.text('Reconnect'));
      await tester.pump();

      // The other half — that a reconnect re-registers the subscriptions instead
      // of reopening an empty stream — is RemoteSseStrategy.onSseConnected, tested
      // in test/core/usp/services/sse_remote_strategy_test.dart.
      verify(() => manager.tryReconnect()).called(1);
    });
  });

  testWidgets('the recovery dialog still wins over the banner', (tester) async {
    // Not a mode question, and asserted here so the mode work is not blamed for
    // it later: while `waitingForRecovery` is showing its own modal about the
    // same disconnection, the banner stays out of the way in both modes.
    await pumpBanner(
      tester,
      profile: const RemoteModeProfile(),
      connection: AppConnectionState.waitingForRecovery,
    );

    await emit(tester, SseConnectionState.disconnected);
    await waitOutGrace(tester);

    expect(bannerColor(tester), isNull);
  });
}
