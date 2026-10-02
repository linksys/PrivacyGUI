// #1580 / epic #1575 — what the notification history page renders.
//
// THE DECISION GUARDED. #1580's six acceptance rows, all of which are about states
// that are easy to render as each other's:
//
//   1. Null `lastBoot` / `lastUspActivity` render as an em dash, **not** an error.
//      Both being null is the normal state of a device that has produced nothing.
//   2. An empty history is an ordinary empty state that says *this session* has
//      produced nothing — not "no data", which reads like a fault.
//   3. Opening a row fetches its body; a 404 reports "no longer available" rather
//      than crashing or reading as a broken session.
//   4. A `notificationType: Unknown` row is rendered. It is a real stored value.
//   6. A local build shows no entry point (the popup that carries it is mounted
//      only by the remote surface — see `remote_session_chip_widget_test.dart`),
//      and the page degrades explicitly if reached by URL.
//
// Row 5 (no timed request) is asserted where it can be counted, in
// `usp_notification_history_notifier_test.dart`.
//
// HOW IT COULD SILENTLY REVERT. Every one of these is a *substitution*, not a
// crash: a null timestamp routed into the error arm, the empty state given the
// generic "no data" string, an `Unknown` row filtered out as a placeholder, or the
// unavailable state replaced by go_router's error page. All five look like working
// software until someone reads the screen.
//
// WHY THIS TEST TYPE. Widget tests at one wide width. The geometry of these cards
// is the layout gate's job — every one of them is in the page-surface sweep at
// nine widths in 26 locales — so this file pumps a width where nothing wraps and
// asserts only which strings are on screen.
//
// Not tagged `ui`: the two CI jobs exclude `golden||loc||ui`, so a tagged case
// would never run.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_notifier.dart';
import 'package:privacy_gui/page/notification_history/services/usp_notification_history_service.dart';
import 'package:privacy_gui/page/notification_history/views/usp_notification_history_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/notification_history_test_data.dart';
import '../../../mocks/provider_overrides/mock_common.dart';

class MockUspNotificationHistoryService extends Mock
    implements UspNotificationHistoryService {}

NotificationDetailUIModel detail(String msgId, NotificationBodyUIModel body) =>
    NotificationDetailUIModel(
      entry: NotificationHistoryTestData.entry(msgId, 'ValueChange'),
      body: body,
    );

String stamp(int ms) {
  final at = DateTime.fromMillisecondsSinceEpoch(ms);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
}

void main() {
  late AppLocalizations loc;
  late MockUspNotificationHistoryService service;

  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() => service = MockUspNotificationHistoryService());

  Widget wrap({required bool available}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspNotificationHistoryView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        notificationHistoryAvailableProvider.overrideWithValue(available),
        uspNotificationHistoryServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    bool available = true,
    Size size = const Size(1280, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(available: available));
    await tester.pumpAndSettle();
  }

  void stub({
    SessionUspStateUIModel? state,
    List<NotificationHistoryEntryUIModel> entries = const [],
  }) {
    when(() => service.fetchState())
        .thenAnswer((_) async => state ?? const SessionUspStateUIModel());
    when(() => service.fetchHistory()).thenAnswer((_) async => entries);
    // Every row fetches its body as it is built, so every test needs an answer
    // for every row. An empty raw body is the one that renders nothing inline;
    // a test that cares registers its own afterwards, and mocktail matches the
    // most recent stub first.
    when(() => service.fetchDetail(any())).thenAnswer((inv) async => detail(
        inv.positionalArguments.first as String, const RawBodyUIModel('')));
  }

  void answer(String msgId, NotificationBodyUIModel body) =>
      when(() => service.fetchDetail(msgId))
          .thenAnswer((_) async => detail(msgId, body));

  Finder inDialog(Finder dialog, String text) =>
      find.descendant(of: dialog, matching: find.text(text));

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 1 — the two timestamps, including their null case
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - session state', () {
    testWidgets('both labels render, and nulls read as an em dash',
        (tester) async {
      stub();

      await pump(tester);

      expect(find.text(loc.notificationHistoryLastBoot), findsOneWidget);
      expect(find.text(loc.notificationHistoryLastActivity), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      // The row that must NOT appear: a null timestamp is not a failure.
      expect(find.text(loc.failedToLoadSettings), findsNothing);
    });

    testWidgets('a present timestamp renders as a fixed local stamp',
        (tester) async {
      // A fixed `YYYY-MM-DD HH:MM:SS` rather than a locale format, because these
      // values get correlated against router logs by eye. Built from the
      // rendered DateTime so the assertion does not depend on the test machine's
      // zone.
      final boot = DateTime.fromMillisecondsSinceEpoch(1757000000000);
      stub(state: SessionUspStateUIModel(lastBoot: boot));

      await pump(tester);

      String two(int n) => n.toString().padLeft(2, '0');
      final expected = '${boot.year}-${two(boot.month)}-${two(boot.day)} '
          '${two(boot.hour)}:${two(boot.minute)}:${two(boot.second)}';
      expect(find.text(expected), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 2 — empty is normal
  // ═════════════════════════════════════════════════════════════════════════
  testWidgets('an empty history is an ordinary empty state', (tester) async {
    stub(entries: []);

    await pump(tester);

    expect(find.text(loc.notificationHistoryEmpty), findsOneWidget);
    expect(find.text(loc.failedToLoadSettings), findsNothing);
    // And not the local-build sentence: this session simply has no rows yet.
    expect(find.text(loc.notificationHistoryUnavailable), findsNothing);
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 4 — Unknown is a value, not a placeholder
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - the timeline', () {
    testWidgets('renders a row per entry, Unknown included', (tester) async {
      stub(entries: [
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m2', 'OperationComplete',
            commandKey: 'key-abc'),
        NotificationHistoryTestData.entry('m3', 'Unknown'),
      ]);

      await pump(tester);

      expect(find.byType(AppSliverTimeline), findsOneWidget);
      expect(find.text('ValueChange'), findsOneWidget);
      expect(find.text('OperationComplete'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text(loc.notificationHistoryEmpty), findsNothing);
    });

    testWidgets(
        'the message id and command key live in the dialog, not the row',
        (tester) async {
      // The two UUIDs were half of every row and nobody scans a list by them;
      // what a support engineer scans by is the path and value. They are still
      // one tap away, because they are what gets pasted into a ticket.
      stub(entries: [
        NotificationHistoryTestData.entry('m2', 'OperationComplete',
            commandKey: 'key-abc'),
      ]);
      await pump(tester);

      expect(find.text('m2'), findsNothing);
      expect(find.text('key-abc'), findsNothing);
      expect(find.text(loc.notificationHistoryMessageId), findsNothing);

      await tester.tap(find.text('OperationComplete'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AppDialog);
      expect(
          inDialog(dialog, loc.notificationHistoryMessageId), findsOneWidget);
      expect(inDialog(dialog, 'm2'), findsOneWidget);
      expect(
          inDialog(dialog, loc.notificationHistoryCommandKey), findsOneWidget);
      expect(inDialog(dialog, 'key-abc'), findsOneWidget);
    });

    testWidgets('a row without a command key has no command key line',
        (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      await pump(tester);

      await tester.tap(find.text('ValueChange'));
      await tester.pumpAndSettle();

      expect(find.text(loc.notificationHistoryMessageId), findsOneWidget);
      expect(find.text(loc.notificationHistoryCommandKey), findsNothing);
    });

    testWidgets('the E2E id is still on the row', (tester) async {
      final handle = tester.ensureSemantics();
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      await pump(tester);

      final row = find.bySemanticsIdentifier('notification-history-row-m1');
      expect(row, findsOneWidget);

      await tester.tap(row, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      handle.dispose();
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Same-second bursts share one heading
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - grouping', () {
    testWidgets('entries in the same second sit under one timestamp heading',
        (tester) async {
      // A subscription fires ~28 notifies in one second. One heading per burst
      // is what makes the burst readable as one thing; 28 identical stamps is
      // what the card list rendered.
      const t0 = 1757000000000;
      stub(entries: [
        NotificationHistoryTestData.entry('m1', 'ValueChange', ms: t0),
        NotificationHistoryTestData.entry('m2', 'ValueChange', ms: t0 + 400),
        NotificationHistoryTestData.entry('m3', 'Event', ms: t0 + 5000),
      ]);

      await pump(tester);

      // Once, not twice: `m1` and `m2` share it.
      expect(find.text(stamp(t0)), findsOneWidget);
      expect(find.text(stamp(t0 + 5000)), findsOneWidget);
    });

    testWidgets('a row with no timestamp sits last, under an em dash',
        (tester) async {
      // Not a "1970-01-01" heading: that would be a fabricated reading of a clock
      // the row never reported.
      stub(entries: [
        const NotificationHistoryEntryUIModel(
          msgId: 'undated',
          notificationType: 'Event',
        ),
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
      ]);

      await pump(tester);

      expect(find.textContaining('1970'), findsNothing);
      // The em dash heading, beside the two em-dash session timestamps.
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('a burst that crosses a second boundary gets two headings',
        (tester) async {
      // Grouped on the second the heading shows, not on a window: 300ms apart
      // across `:00` is two different stamps, and one heading over both would
      // print a time one of them does not have.
      const t0 = 1757000000900;
      stub(entries: [
        NotificationHistoryTestData.entry('m1', 'ValueChange', ms: t0),
        NotificationHistoryTestData.entry('m2', 'ValueChange', ms: t0 + 300),
      ]);

      await pump(tester);

      expect(stamp(t0), isNot(stamp(t0 + 300)));
      expect(find.text(stamp(t0)), findsOneWidget);
      expect(find.text(stamp(t0 + 300)), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // What each type shows inline, fetched as the row is built
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - inline summary', () {
    testWidgets('a ValueChange shows its path and value without a tap',
        (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      answer(
          'm1',
          const ValueChangeBodyUIModel(
            paramPath: 'Device.WiFi.SSID.1.SSID',
            paramValue: 'Linksys-Guest',
          ));

      await pump(tester);

      expect(find.text('Device.WiFi.SSID.1.SSID'), findsOneWidget);
      expect(find.text('Linksys-Guest'), findsOneWidget);
      verify(() => service.fetchDetail('m1')).called(1);
    });

    testWidgets('an OperationComplete shows its command and its outcome',
        (tester) async {
      stub(entries: [
        NotificationHistoryTestData.entry('ok', 'OperationComplete',
            ms: 1757000001000),
        NotificationHistoryTestData.entry('no', 'OperationComplete',
            ms: 1757000000000),
      ]);
      answer(
          'ok',
          const OperationCompleteBodyUIModel(
            commandName: 'Device.WiFi.NeighboringWiFiDiagnostic()',
            commandKey: 'k1',
          ));
      answer(
          'no',
          const OperationCompleteBodyUIModel(
            commandName: 'Device.IP.Diagnostics.IPPing()',
            commandKey: 'k2',
            refused: true,
          ));

      await pump(tester);

      expect(
          find.text('Device.WiFi.NeighboringWiFiDiagnostic()'), findsOneWidget);
      expect(find.text(loc.success), findsOneWidget);
      expect(find.text('Device.IP.Diagnostics.IPPing()'), findsOneWidget);
      // Decided by `refused`, not by the error code: a refusal with no code is
      // still a refusal.
      expect(find.text(loc.failed), findsOneWidget);
    });

    testWidgets('an Event shows its name', (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('e1', 'Event')]);
      answer(
          'e1',
          const EventBodyUIModel(
            eventName: 'Device.LocalAgent.Periodic!',
            params: {'Hidden': 'param'},
          ));

      await pump(tester);

      expect(find.text('Device.LocalAgent.Periodic!'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets(
        'a type with no summary shows the type alone, and reads nothing',
        (tester) async {
      // Only three types have a line worth showing. Every other row would spend a
      // Guardian read on a body the row then does not draw — and would flash
      // "Loading…" under a type that is the whole row.
      final pending = Completer<NotificationDetailUIModel>();
      stub(entries: [
        NotificationHistoryTestData.entry('m8', 'ObjectCreation',
            ms: 1757000001000),
        NotificationHistoryTestData.entry('m9', 'Unknown'),
      ]);
      when(() => service.fetchDetail(any())).thenAnswer((_) => pending.future);

      await tester.pumpWidget(const SizedBox());
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(available: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('ObjectCreation'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text(loc.loading), findsNothing);
      verifyNever(() => service.fetchDetail(any()));

      // The dialog still reads it: the whole body is what a tap is for.
      await tester.tap(find.text('Unknown'));
      await tester.pump();
      verify(() => service.fetchDetail('m9')).called(1);
      pending.complete(detail('m9', const RawBodyUIModel('')));
      await tester.pumpAndSettle();
    });

    testWidgets('a row still loading says so, then fills in', (tester) async {
      final pending = Completer<NotificationDetailUIModel>();
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1')).thenAnswer((_) => pending.future);

      await pump(tester);
      expect(find.text(loc.loading), findsOneWidget);

      pending.complete(detail(
          'm1',
          const ValueChangeBodyUIModel(
            paramPath: 'Device.X',
            paramValue: 'v',
          )));
      await tester.pumpAndSettle();

      expect(find.text(loc.loading), findsNothing);
      expect(find.text('Device.X'), findsOneWidget);
    });

    testWidgets('only rows in or near view are fetched', (tester) async {
      // The point of the sliver: 25 rows on the first page must not be 25
      // body reads before the user has scrolled. Each one is a Guardian read.
      final entries = [
        for (var i = 0; i < 25; i++)
          NotificationHistoryTestData.entry('m$i', 'ValueChange',
              ms: 1757000000000 - i * 60000),
      ];
      stub(entries: entries);

      await pump(tester, size: const Size(1280, 800));

      verify(() => service.fetchDetail('m0')).called(1);
      verifyNever(() => service.fetchDetail('m24'));

      await tester.drag(
          find.byType(CustomScrollView).first, const Offset(0, -20000));
      await tester.pumpAndSettle();

      verify(() => service.fetchDetail('m24')).called(1);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 3 — the dialog, and a 404 is ordinary
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - opening a row', () {
    testWidgets('renders the full body, from the fetch the row already made',
        (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      answer(
          'm1',
          const ValueChangeBodyUIModel(
            paramPath: 'Device.WiFi.SSID.1.SSID',
            paramValue: 'Linksys-Guest',
          ));
      await pump(tester);

      await tester.tap(find.text('ValueChange'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AppDialog);
      expect(inDialog(dialog, 'param_path'), findsOneWidget);
      expect(inDialog(dialog, 'Device.WiFi.SSID.1.SSID'), findsOneWidget);
      expect(inDialog(dialog, 'Linksys-Guest'), findsOneWidget);
      verify(() => service.fetchDetail('m1')).called(1);
    });

    testWidgets('a 404 says "no longer available", not a crash',
        (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1'))
          .thenThrow(const ResourceNotFoundError(code: 404));
      await pump(tester);

      // Inline first: the row is built, so its read has already happened.
      expect(find.text(loc.notificationHistoryGone), findsOneWidget);

      await tester.tap(find.text('ValueChange'));
      await tester.pumpAndSettle();

      expect(inDialog(find.byType(AppDialog), loc.notificationHistoryGone),
          findsOneWidget);
      // The spec makes 404 cover "gone" and "not yours" without distinguishing
      // them, so the generic failure copy would be reporting a fault that is
      // not one.
      expect(find.text(loc.notificationHistoryLoadFailed), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('any other failure reads as one', (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1'))
          .thenThrow(const UnexpectedError(detail: 'boom'));
      await pump(tester);

      // Its own sentence, not the page's "Failed to load settings": a row is a
      // notification, and there are no settings on this page.
      expect(find.text(loc.notificationHistoryLoadFailed), findsOneWidget);
      expect(find.text(loc.failedToLoadSettings), findsNothing);
      expect(find.text(loc.notificationHistoryGone), findsNothing);

      await tester.tap(find.text('ValueChange'));
      await tester.pumpAndSettle();
      expect(
          inDialog(find.byType(AppDialog), loc.notificationHistoryLoadFailed),
          findsOneWidget);
    });

    testWidgets('a refused OperationComplete shows its error, not its args',
        (tester) async {
      stub(entries: [
        NotificationHistoryTestData.entry('m2', 'OperationComplete',
            commandKey: 'k')
      ]);
      answer(
          'm2',
          const OperationCompleteBodyUIModel(
            commandName: 'Device.IP.Diagnostics.IPPing()',
            commandKey: 'k',
            errorCode: '7004',
            errorMessage: 'refused',
            refused: true,
          ));
      await pump(tester);

      await tester.tap(find.text('OperationComplete'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AppDialog);
      expect(inDialog(dialog, 'err_code'), findsOneWidget);
      expect(inDialog(dialog, '7004'), findsOneWidget);
      expect(inDialog(dialog, 'refused'), findsOneWidget);
    });

    testWidgets('an unrecognised body is shown as JSON rather than dropped',
        (tester) async {
      stub(entries: [NotificationHistoryTestData.entry('m9', 'Unknown')]);
      answer('m9', const RawBodyUIModel('{\n  "obj_creation": {}\n}'));
      await pump(tester);

      await tester.tap(find.text('Unknown'));
      await tester.pumpAndSettle();

      expect(find.textContaining('obj_creation'), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // A failed pull keeps the list
  // ═════════════════════════════════════════════════════════════════════════
  testWidgets('a failed pull keeps the rows and the filter, and says it failed',
      (tester) async {
    // The rows are an older answer, not a wrong one. Before, a failed pull put
    // the page in its full-page error, and that error's retry reloads the page,
    // dropping the filter the viewer had set.
    stub(entries: [
      NotificationHistoryTestData.entry('m1', 'ValueChange'),
      NotificationHistoryTestData.entry('m2', 'OperationComplete'),
    ]);
    await pump(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(UspNotificationHistoryView)));
    container
        .read(uspNotificationHistoryProvider.notifier)
        .setTypeFilter('ValueChange');
    await tester.pumpAndSettle();
    when(() => service.fetchHistory())
        .thenThrow(const UnexpectedError(detail: 'the pull failed'));

    await tester.fling(
        find.byType(CustomScrollView).first, const Offset(0, 600), 1000);
    await tester.pumpAndSettle();

    verify(() => service.fetchHistory()).called(2);
    expect(find.text('the pull failed'), findsOneWidget);
    expect(find.text(loc.failedToLoadSettings), findsNothing);
    expect(find.text('ValueChange'), findsWidgets);
    expect(
        container.read(uspNotificationHistoryProvider).requireValue.typeFilter,
        'ValueChange');
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 6 — the local build
  // ═════════════════════════════════════════════════════════════════════════
  testWidgets('a build with no notification store says so explicitly',
      (tester) async {
    // Reached by a hand-typed URL: the route is registered in every mode because
    // the shared dashboard's children are one table. The alternative to this
    // sentence is go_router's developer error page.
    await pump(tester, available: false);

    expect(find.text(loc.notificationHistoryUnavailable), findsOneWidget);
    expect(find.text(loc.notificationHistoryEmpty), findsNothing);
    expect(find.text(loc.notificationHistoryLastBoot), findsNothing);
    // And nothing is read: there is nothing to read from.
    verifyNever(() => service.fetchState());
    verifyNever(() => service.fetchHistory());
  });
}
