import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_state.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_view.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class _ExitData extends AutoIPoEDataNotifier {
  _ExitData(this.snapshot);
  final AutoIPoESnapshot snapshot;
  int exits = 0;
  Future<void> Function()? cleanup;

  @override
  Future<AutoIPoESnapshot> build() async => snapshot;

  @override
  Future<void> leavePnp({bool resetIfIdle = false}) async {
    exits++;
    await cleanup?.call();
  }

  void publish(AutoIPoESnapshot snapshot) => state = AsyncData(snapshot);
}

class _ExitPage extends AutoIPoEPageNotifier {
  _ExitPage(this.snapshot, {this.dirty = false});
  final AutoIPoESnapshot snapshot;
  final bool dirty;
  int saves = 0;
  Future<void> Function()? onSave;

  @override
  AutoIPoEPageState build() => AutoIPoEPageState(
        settings: Preservable(
          original:
              dirty ? const AutoIPoESettings.init() : AutoIPoETestData.settings,
          current: AutoIPoETestData.settings,
        ),
        status: AutoIPoEPageStatus(snapshot: snapshot),
      );

  @override
  Future<void> saveForPnp() async {
    saves++;
    await onSave?.call();
  }

  void publish(AutoIPoESnapshot snapshot) {
    state = state.copyWith(status: AutoIPoEPageStatus(snapshot: snapshot));
  }
}

class _ExitService extends Mock implements AutoIPoEService {}

class _ExitPnp extends PnpNotifier {
  int starts = 0;
  @override
  PnpState build() => PnpState.initial();
  @override
  Future<void> startPostLoginFlow() async => starts++;
}

GoRouter _router() {
  final picker = pnpNoInternetRoute.routes.whereType<GoRoute>().singleWhere(
        (route) => route.name == RouteNamed.pnpIspTypeSelection,
      );
  // Use the production LinksysRoute, including both exit and dirty guards.
  final ipoe = picker.routes.whereType<GoRoute>().singleWhere(
        (route) => route.name == RouteNamed.pnpAutoIPoE,
      );
  return GoRouter(
    initialLocation: '/wan/${RoutePath.pnpAutoIPoE}',
    routes: [
      GoRoute(
        path: '/wan',
        name: RouteNamed.pnpIspTypeSelection,
        builder: (_, __) => const Text('WAN selection'),
        routes: [ipoe],
      ),
      GoRoute(
          path: RoutePath.pnp,
          builder: (_, __) => const Text('Next setup step')),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  GoRouter router,
  _ExitData data,
  _ExitPage page,
  _ExitPnp pnp, {
  AutoIPoESubmission? submission,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...commonOverrides(),
      appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      autoIPoEDataProvider.overrideWith(() => data),
      autoIPoEPageProvider.overrideWith(() => page),
      autoIPoEServiceProvider.overrideWithValue(_ExitService()),
      autoIPoESubmissionProvider.overrideWith((ref) => submission),
      pnpProvider.overrideWith(() => pnp),
    ],
    child: MaterialApp.router(
      theme: AppTheme.create(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(AutoIPoEView)));
}

void main() {
  for (final fails in [false, true]) {
    testWidgets(
        'browser Back waits for setup cleanup on a clean draft: fails=$fails',
        (tester) async {
      final snapshot =
          AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, busy: true);
      final data = _ExitData(snapshot);
      final done = Completer<void>();
      data.cleanup = () => done.future;
      final page = _ExitPage(snapshot);
      final router = _router();
      addTearDown(router.dispose);
      final container = await _pump(
        tester,
        router,
        data,
        page,
        _ExitPnp(),
        submission: const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
      );
      final guard = container.read(autoIPoEPnpExitGuardProvider);
      expect(page.isDirty(), isFalse);
      router.pop();
      await tester.pump();
      expect(data.exits, 1);
      expect(find.byType(AutoIPoEView), findsOneWidget);
      if (fails) {
        done.completeError(const ConnectivityError());
      } else {
        done.complete();
      }
      if (fails) {
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      } else {
        // The exit guard and the Navigator transition finish asynchronously.
        // Wait for both instead of counting frames of the outgoing page.
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/wan');
      }
      expect(find.byType(AutoIPoEView), fails ? findsOneWidget : findsNothing);
      expect(data.exits, 1);
      if (!fails) expect(guard.onExit, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'verified forward completion saves the draft without resetting WAN',
      (tester) async {
    final initial = AutoIPoETestData.snapshot();
    final data = _ExitData(initial);
    final page = _ExitPage(initial, dirty: true);
    final pnp = _ExitPnp();
    final router = _router();
    addTearDown(router.dispose);
    final container = await _pump(tester, router, data, page, pnp);
    final guard = container.read(autoIPoEPnpExitGuardProvider);
    page.onSave = () async {
      container.read(autoIPoESubmissionProvider.notifier).state =
          const AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      final completed = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id,
        exitCode: 0,
        verified: true,
      );
      data.publish(completed);
      page.publish(completed);
    };
    expect(page.isDirty(), isTrue);
    final execute = find.byWidgetPredicate(
      (widget) =>
          widget is AppButton && widget.identifier == 'auto-ipoe-pnp-continue',
    );
    tester.widget<AppButton>(execute).onTap!();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Next setup step'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(page.saves, 1);
    expect(pnp.starts, 1);
    expect(data.exits, 0);
    expect(guard.onExit, isNull);
    expect(tester.takeException(), isNull);
  });
}
