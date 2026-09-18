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
//   6. A local build shows no entry point, and the page degrades explicitly if
//      reached by URL.
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

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/test_data/scenes/notification_history_scene_data.dart';

class MockUspNotificationHistoryService extends Mock
    implements UspNotificationHistoryService {}

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

  Future<void> pump(WidgetTester tester, {bool available = true}) async {
    tester.view.physicalSize = const Size(1280, 2400);
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
    when(() => service.fetchState()).thenAnswer((_) async =>
        state ?? const SessionUspStateUIModel(deviceUuid: 'uuid-1'));
    when(() => service.fetchHistory()).thenAnswer((_) async => entries);
  }

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
      stub(state: SessionUspStateUIModel(deviceUuid: 'u', lastBoot: boot));

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
  group('UspNotificationHistoryView - the list', () {
    testWidgets('renders a row per entry, Unknown included', (tester) async {
      stub(entries: [
        notificationEntry('m1', 'ValueChange'),
        notificationEntry('m2', 'OperationComplete', commandKey: 'key-abc'),
        notificationEntry('m3', 'Unknown'),
      ]);

      await pump(tester);

      expect(find.text('ValueChange'), findsOneWidget);
      expect(find.text('OperationComplete'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('m3'), findsOneWidget);
      expect(find.text(loc.notificationHistoryEmpty), findsNothing);
    });

    testWidgets('the command key line appears only on the row that has one',
        (tester) async {
      stub(entries: [
        notificationEntry('m1', 'ValueChange'),
        notificationEntry('m2', 'OperationComplete', commandKey: 'key-abc'),
      ]);

      await pump(tester);

      expect(find.text(loc.notificationHistoryCommandKey), findsOneWidget);
      expect(find.text('key-abc'), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acceptance 3 — a row opens its body, and a 404 is ordinary
  // ═════════════════════════════════════════════════════════════════════════
  group('UspNotificationHistoryView - opening a row', () {
    testWidgets('fetches and renders its body', (tester) async {
      stub(entries: [notificationEntry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: notificationEntry('m1', 'ValueChange'),
          body: const ValueChangeBodyUIModel(
            paramPath: 'Device.WiFi.SSID.1.SSID',
            paramValue: 'Linksys-Guest',
          ),
        ),
      );
      await pump(tester);

      await tester.tap(find.text('m1'));
      await tester.pumpAndSettle();

      expect(find.text('param_path'), findsOneWidget);
      expect(find.text('Device.WiFi.SSID.1.SSID'), findsOneWidget);
      expect(find.text('Linksys-Guest'), findsOneWidget);
      verify(() => service.fetchDetail('m1')).called(1);
    });

    testWidgets('a 404 says "no longer available", not a crash',
        (tester) async {
      stub(entries: [notificationEntry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1'))
          .thenThrow(const ResourceNotFoundError(code: 404));
      await pump(tester);

      await tester.tap(find.text('m1'));
      await tester.pumpAndSettle();

      expect(find.text(loc.notificationHistoryGone), findsOneWidget);
      // The spec makes 404 cover "gone" and "not yours" without distinguishing
      // them, so the generic failure copy would be reporting a fault that is
      // not one.
      expect(find.text(loc.failedToLoadSettings), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refused OperationComplete shows its error, not its args',
        (tester) async {
      stub(entries: [
        notificationEntry('m2', 'OperationComplete', commandKey: 'k')
      ]);
      when(() => service.fetchDetail('m2')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: notificationEntry('m2', 'OperationComplete', commandKey: 'k'),
          body: const OperationCompleteBodyUIModel(
            commandName: 'Device.IP.Diagnostics.IPPing()',
            commandKey: 'k',
            errorCode: '7004',
            errorMessage: 'refused',
            refused: true,
          ),
        ),
      );
      await pump(tester);

      await tester.tap(find.text('m2'));
      await tester.pumpAndSettle();

      expect(find.text('err_code'), findsOneWidget);
      expect(find.text('7004'), findsOneWidget);
      expect(find.text('refused'), findsOneWidget);
    });

    testWidgets('an unrecognised body is shown as JSON rather than dropped',
        (tester) async {
      stub(entries: [notificationEntry('m9', 'Unknown')]);
      when(() => service.fetchDetail('m9')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: notificationEntry('m9', 'Unknown'),
          body: const RawBodyUIModel('{\n  "obj_creation": {}\n}'),
        ),
      );
      await pump(tester);

      await tester.tap(find.text('m9'));
      await tester.pumpAndSettle();

      expect(find.textContaining('obj_creation'), findsOneWidget);
    });
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
