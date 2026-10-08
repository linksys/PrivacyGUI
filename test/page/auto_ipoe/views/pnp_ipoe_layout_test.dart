import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_view.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';

class FakeIPoE extends AutoIPoEDataNotifier {
  int exits = 0;
  bool? resetOnExit;
  Future<void> Function()? onExit;
  @override
  Future<void> leavePnp({bool resetIfIdle = false}) async {
    exits++;
    resetOnExit = resetIfIdle;
    await onExit?.call();
  }

  @override
  Future<AutoIPoESnapshot> build() async => const AutoIPoESnapshot(
        capabilities: AutoIPoECapabilities(
          isSupported: true,
          supportedModes: [AutoIPoEMode.auto],
          blocksManualIPv6Configuration: true,
          requiresResetOnExit: true,
        ),
      );
}

class RetryReadData extends FakeIPoE {
  int checks = 0;
  int reads = 0;
  void fail(AutoIPoESnapshot snapshot) {
    state = AsyncError<AutoIPoESnapshot>(
      const ConnectivityError(),
      StackTrace.current,
    ).copyWithPrevious(AsyncData(snapshot));
  }

  void recover(AutoIPoESnapshot snapshot) {
    state = AsyncData(snapshot);
  }

  @override
  void continueChecking() {
    checks++;
  }

  @override
  Future<AutoIPoESnapshot?> refresh() async {
    reads++;
    return state.valueOrNull;
  }
}

class ControlledIPoE extends AutoIPoEDataNotifier {
  ControlledIPoE(this.result);
  final Future<AutoIPoESnapshot> result;
  @override
  Future<AutoIPoESnapshot> build() => result;
}

class ActionService extends Mock implements AutoIPoEService {}

class ActionPage extends AutoIPoEPageNotifier {
  ActionPage(this.initial, {this.onSave});
  final Future<void> Function()? onSave;
  void publish(AutoIPoESnapshot snapshot) {
    state = state.copyWith(status: AutoIPoEPageStatus(snapshot: snapshot));
  }

  final AutoIPoEPageState initial;
  int saves = 0;
  @override
  AutoIPoEPageState build() => initial;
  @override
  Future<void> saveForPnp() async {
    saves++;
    await onSave?.call();
  }
}

class ActionPnp extends PnpNotifier {
  int starts = 0;
  @override
  PnpState build() => PnpState.initial();
  @override
  Future<void> startPostLoginFlow() async {
    starts++;
  }
}

void main() {
  for (final scenario in [
    'success',
    'failure',
    'unrelated',
    'edited',
    'disposed',
    'session',
    'readFailure',
    'saveFailure',
  ]) {
    testWidgets('single click waits for its verified request: $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late ProviderContainer container;
      final dispatched = Completer<void>();
      const id = AutoIPoETestData.id;
      final snapshot = AutoIPoETestData.snapshot();
      final page = ActionPage(
        AutoIPoEPageState(
          settings: Preservable(
            original: snapshot.settings,
            current: snapshot.settings,
          ),
          status: AutoIPoEPageStatus(snapshot: snapshot),
        ),
        onSave: () async {
          container.read(autoIPoESubmissionProvider.notifier).state =
              const AutoIPoESubmission(id, reset: false);
          await dispatched.future;
          if (scenario == 'saveFailure') throw const ConnectivityError();
        },
      );
      final pnp = ActionPnp();
      final retryData = RetryReadData();
      final router = GoRouter(
        initialLocation: '/ipoe',
        routes: [
          GoRoute(
            path: '/ipoe',
            builder: (_, __) => const AutoIPoEView(pnp: true),
          ),
          GoRoute(
            path: RoutePath.pnp,
            builder: (_, __) => const Text('pnp continued'),
          ),
          GoRoute(path: '/away', builder: (_, __) => const Text('away')),
          GoRoute(
            path: '/wan',
            name: RouteNamed.pnpIspTypeSelection,
            builder: (_, __) => const Text('WAN selection'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides(),
            autoIPoEDataProvider.overrideWith(() => retryData),
            autoIPoEPageProvider.overrideWith(() => page),
            autoIPoEServiceProvider.overrideWith((ref) => ActionService()),
            pnpProvider.overrideWith(() => pnp),
          ],
          child: MaterialApp.router(
            theme: AppTheme.create(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      container = ProviderScope.containerOf(
        tester.element(find.byType(AutoIPoEView)),
      );
      final next = find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == 'auto-ipoe-pnp-continue',
      );
      // Even a second callback before the next frame cannot dispatch twice.
      final callback = tester.widget<AppButton>(next).onTap!;
      callback();
      callback();
      await tester.pump();
      expect(page.saves, 1);
      expect(pnp.starts, 0);
      expect(next, findsNothing);
      expect(find.byKey(const ValueKey('auto-ipoe-pnp-back')), findsNothing);
      expect(find.byType(AutoIPoESection), findsNothing);
      expect(
        find.byKey(const ValueKey('auto-ipoe-log-toggle')),
        findsOneWidget,
      );
      if (scenario == 'disposed') router.go('/away');
      if (scenario == 'session') container.invalidate(autoIPoEServiceProvider);
      dispatched.complete();
      await tester.pump();
      await tester.pump();
      expect(pnp.starts, 0);
      if (scenario == 'disposed') {
        expect(find.text('away'), findsOneWidget);
        expect(tester.takeException(), isNull);
        return;
      }
      if (scenario == 'saveFailure') {
        expect(next, findsNothing);
        expect(find.byType(AutoIPoESection), findsNothing);
        expect(find.text('Idle'), findsNothing);
        expect(
          find.byKey(const ValueKey('auto-ipoe-pnp-back')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('auto-ipoe-log-toggle')),
          findsOneWidget,
        );
        expect(page.saves, 1);
        expect(pnp.starts, 0);
        return;
      }
      if (scenario == 'readFailure') {
        final pending = AutoIPoETestData.snapshot(requestId: id);
        page.publish(pending);
        retryData.fail(pending);
        await tester.pump();
        await tester.pump();
        expect(next, findsNothing);
        expect(
          find.byKey(const ValueKey('auto-ipoe-pnp-back')),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsNothing);
        expect(page.saves, 1);
        expect(retryData.checks, 0);
        expect(retryData.reads, 0);
        expect(pnp.starts, 0);
        retryData.recover(pending);
      }
      if (scenario == 'edited') {
        page.updateSettings(
          snapshot.settings.copyWith(
            selectedMode: AutoIPoEMode.ocnVirtualConnectStaticIp,
          ),
        );
      }
      page.publish(
        AutoIPoETestData.snapshot(
          requestId: scenario == 'unrelated' ? 'other' : id,
          exitCode: scenario == 'failure' ? 1 : 0,
          verified: scenario != 'failure',
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(pnp.starts, ['success', 'readFailure'].contains(scenario) ? 1 : 0);
      expect(page.saves, 1);
      if (scenario == 'failure') {
        expect(find.text('Retry'), findsNothing);
        expect(next, findsNothing);
        expect(
          find.byKey(const ValueKey('auto-ipoe-pnp-back')),
          findsOneWidget,
        );
        expect(find.byType(AutoIPoESection), findsNothing);
        expect(container.read(autoIPoEPageProvider).current, snapshot.settings);
        expect(
          find.byKey(const ValueKey('auto-ipoe-log-toggle')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('auto-ipoe-pnp-back')));
        await tester.pump();
        await tester.pump();
        expect(find.text('WAN selection'), findsOneWidget);
        expect(page.saves, 1);
        expect(pnp.starts, 0);
        expect(retryData.exits, 1);
        expect(retryData.resetOnExit, true);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in [
    'initial',
    'pending',
    'failed',
    'ready',
    'edited',
    'back',
  ]) {
    testWidgets(
      'PnP Execute handles $scenario without reset or skipped edits',
      (tester) async {
        final ready = scenario == 'ready' || scenario == 'edited';
        final snapshot = AutoIPoETestData.snapshot(
          requestId: ['initial', 'back'].contains(scenario)
              ? null
              : AutoIPoETestData.id,
          exitCode: ready
              ? 0
              : scenario == 'failed'
                  ? 1
                  : null,
          verified: ready,
          busy: scenario == 'pending',
        );
        final page = ActionPage(
          AutoIPoEPageState(
            settings: Preservable(
              original: snapshot.settings,
              current: scenario == 'edited'
                  ? snapshot.settings.copyWith(
                      selectedMode: AutoIPoEMode.ocnVirtualConnectStaticIp,
                    )
                  : snapshot.settings,
            ),
            status: AutoIPoEPageStatus(snapshot: snapshot),
          ),
        );
        final pnp = ActionPnp();
        final router = GoRouter(
          initialLocation: '/ipoe',
          routes: [
            GoRoute(
              path: '/ipoe',
              builder: (_, __) => const AutoIPoEView(pnp: true),
            ),
            GoRoute(
              path: '/wan',
              name: RouteNamed.pnpIspTypeSelection,
              builder: (_, __) => const Text('WAN selection'),
            ),
            GoRoute(
              path: RoutePath.pnp,
              builder: (_, __) => const Text('pnp continued'),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonOverrides(),
              autoIPoEDataProvider.overrideWith(FakeIPoE.new),
              autoIPoEPageProvider.overrideWith(() => page),
              autoIPoEServiceProvider.overrideWithValue(ActionService()),
              autoIPoESubmissionProvider.overrideWith(
                (ref) => ['initial', 'back'].contains(scenario)
                    ? null
                    : const AutoIPoESubmission(
                        AutoIPoETestData.id,
                        reset: false,
                      ),
              ),
              pnpProvider.overrideWith(() => pnp),
            ],
            child: MaterialApp.router(
              theme: AppTheme.create(brightness: Brightness.dark),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        final next = find.byWidgetPredicate(
          (w) => w is AppButton && w.identifier == 'auto-ipoe-pnp-continue',
        );
        expect(next, scenario == 'pending' ? findsNothing : findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppButton &&
                [
                  'auto-ipoe-apply',
                  'auto-ipoe-reset',
                  'auto-ipoe-cancel',
                ].contains(w.identifier),
          ),
          findsNothing,
        );
        final back = find.byKey(const ValueKey('auto-ipoe-pnp-back'));
        expect(back, scenario == 'pending' ? findsNothing : findsOneWidget);
        if (scenario != 'pending') {
          final button = tester.widget<TextButton>(back);
          for (final states in <Set<WidgetState>>[
            {},
            {WidgetState.hovered},
            {WidgetState.pressed},
            {WidgetState.focused},
          ]) {
            expect(
              button.style!.backgroundColor!.resolve(states),
              Colors.transparent,
            );
            expect(
              button.style!.overlayColor!.resolve(states),
              Colors.transparent,
            );
            expect(button.style!.side!.resolve(states), BorderSide.none);
          }
        }
        if (scenario == 'back') {
          await tester.ensureVisible(back);
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(back);
          await tester.pump();
          await tester.pump();
          expect(find.text('WAN selection'), findsOneWidget);
          expect(page.saves, 0);
          expect(pnp.starts, 0);
          expect(tester.takeException(), isNull);
          return;
        }
        if (scenario != 'pending') {
          await tester.ensureVisible(next);
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(next);
          await tester.pump();
          await tester.pump();
        }
        expect(
          page.saves,
          ['initial', 'failed', 'edited'].contains(scenario) ? 1 : 0,
        );
        expect(pnp.starts, scenario == 'ready' ? 1 : 0);
        expect(
          find.text('pnp continued'),
          scenario == 'ready' ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fenced stale UUID restores Execute on clean idle CPE', (
    tester,
  ) async {
    final data = RetryReadData();
    final clean = await data.build();
    final page = ActionPage(
      AutoIPoEPageState(
        settings: Preservable(
          original: clean.settings,
          current: clean.settings,
        ),
        status: AutoIPoEPageStatus(snapshot: clean),
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AutoIPoEView(pnp: true)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonOverrides(),
          autoIPoEDataProvider.overrideWith(() => data),
          autoIPoEPageProvider.overrideWith(() => page),
          autoIPoESubmissionProvider.overrideWith(
            (ref) =>
                const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final execute = find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == 'auto-ipoe-pnp-continue',
    );
    expect(execute, findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AutoIPoEView)),
    );
    container.read(autoIPoESubmissionProvider.notifier).state = null;
    await tester.pump();
    await tester.pump();
    expect(execute, findsOneWidget);
    expect(find.byKey(const ValueKey('auto-ipoe-pnp-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('auto-ipoe-log-toggle')), findsNothing);
    expect(find.byType(AutoIPoESection), findsOneWidget);
  });

  for (final reset in [false, true]) {
    testWidgets('reopening completed operation restores form: reset=$reset', (
      tester,
    ) async {
      final done = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id,
        exitCode: 0,
        verified: !reset,
        reset: reset,
      );
      final ready = reset
          ? AutoIPoESnapshot(
              capabilities: done.capabilities,
              settings: const AutoIPoESettings.init(),
              runtime: done.runtime.copyWith(isEnabled: false),
              requestId: done.requestId,
              operationId: done.operationId,
              exitCode: 0,
              accepted: true,
            )
          : done;
      final fetch = Completer<AutoIPoESnapshot>();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const AutoIPoEView(pnp: true)),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides(),
            autoIPoEDataProvider.overrideWith(
              () => ControlledIPoE(fetch.future),
            ),
            autoIPoESubmissionProvider.overrideWith(
              (ref) => AutoIPoESubmission(AutoIPoETestData.id, reset: reset),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.create(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      fetch.complete(ready);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.byType(AutoIPoESection), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.identifier == 'auto-ipoe-pnp-continue',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('auto-ipoe-pnp-back')), findsOneWidget);
      expect(find.byKey(const ValueKey('auto-ipoe-log-toggle')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final fails in [false, true]) {
    testWidgets('Back waits for cleanup and handles failure=$fails', (
      tester,
    ) async {
      final data = FakeIPoE();
      final done = Completer<void>();
      data.onExit = () => done.future;
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const AutoIPoEView(pnp: true)),
          GoRoute(
            path: '/wan',
            name: RouteNamed.pnpIspTypeSelection,
            builder: (_, __) => const Text('WAN selection'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides(),
            autoIPoEDataProvider.overrideWith(() => data),
            autoIPoEServiceProvider.overrideWithValue(ActionService()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.create(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final back = find.byKey(const ValueKey('auto-ipoe-pnp-back'));
      final callback = tester.widget<TextButton>(back).onPressed!;
      callback();
      callback();
      await tester.pump();
      expect(data.exits, 1);
      expect(find.text('WAN selection'), findsNothing);
      expect(find.byType(AppLoader), findsOneWidget);
      if (fails) {
        done.completeError(const ConnectivityError());
      } else {
        done.complete();
      }
      await tester.pump();
      await tester.pump();
      expect(find.text('WAN selection'), fails ? findsNothing : findsOneWidget);
      if (fails) expect(back, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'direct picker load waits for capability result before WAN choices',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const PnpIspSettingsView()),
        ],
      );
      addTearDown(router.dispose);
      final result = Completer<AutoIPoESnapshot>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides(),
            autoIPoEDataProvider.overrideWith(
              () => ControlledIPoE(result.future),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.create(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('DHCP'), findsNothing);
      result.complete(await FakeIPoE().build());
      await tester.pump();
      await tester.pump();
      expect(find.text('IPoE'), findsOneWidget);
      expect(find.text('DHCP'), findsOneWidget);
    },
  );

  for (final unsupported in [false, true]) {
    testWidgets(
      'picker distinguishes unsupported from failed read: $unsupported',
      (tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const PnpIspSettingsView()),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonOverrides(),
              autoIPoEDataProvider.overrideWith(
                () => ControlledIPoE(
                  Future.error(
                    unsupported
                        ? const ResourceNotFoundError()
                        : const ConnectivityError(),
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.create(brightness: Brightness.dark),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('DHCP'), unsupported ? findsOneWidget : findsNothing);
        expect(find.text('IPoE'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final outcome in [
    AutoIPoEOutcome.pending,
    AutoIPoEOutcome.rejected,
    AutoIPoEOutcome.retryScheduled,
    AutoIPoEOutcome.busy,
  ]) {
    testWidgets('PnP hides recovery controls but keeps status for $outcome', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides(),
            autoIPoEDataProvider.overrideWith(FakeIPoE.new),
          ],
          child: MaterialApp(
            theme: AppTheme.create(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => buildAutoIPoERuntime(
                  context,
                  ref,
                  const AutoIPoESnapshot(),
                  outcome,
                  const AutoIPoESubmission('pending', reset: false),
                  inline: true,
                  showRecoveryActions: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AppButton &&
              [
                'auto-ipoe-resolve-pending',
                'auto-ipoe-continue-checking',
              ].contains(w.identifier),
        ),
        findsNothing,
      );
      final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l.autoIpoeResolvePendingDescription), findsNothing);
      expect(find.text(l.autoIpoeRecoveryNoDuplicateApply), findsNothing);
      if (outcome == AutoIPoEOutcome.pending) {
        expect(find.byType(AppLoader), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final locale in ['en', 'ja']) {
    for (final width in [390.0, 1024.0]) {
      testWidgets(
        'PnP IPoE uses an ISP card and a compact form on $locale width $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            initialLocation: '/select',
            routes: [
              GoRoute(
                path: '/select',
                builder: (_, __) => const PnpIspSettingsView(),
              ),
              GoRoute(
                path: '/ipoe',
                name: RouteNamed.pnpAutoIPoE,
                builder: (_, __) => const AutoIPoEView(pnp: true),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...commonOverrides(),
                autoIPoEDataProvider.overrideWith(FakeIPoE.new),
              ],
              child: MaterialApp.router(
                theme: AppTheme.create(brightness: Brightness.dark),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              ),
            ),
          );
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(AppCard), findsNWidgets(4));
          expect(
            find.ancestor(
              of: find.text('IPoE'),
              matching: find.byType(AppCard),
            ),
            findsOneWidget,
          );
          final picker = AppLocalizations.of(
            tester.element(find.byType(PnpIspSettingsView)),
          )!;
          final labels = ['DHCP', 'IPoE', 'PPPoE', picker.ipAddress];
          final tops = labels
              .map((label) => tester.getTopLeft(find.text(label)).dy)
              .toList();
          expect(tops, orderedEquals([...tops]..sort()));
          await tester.tap(find.text('IPoE'));
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(AutoIPoEView), findsOneWidget);
          expect(find.byType(AppCard), findsNothing);
          final l = AppLocalizations.of(
            tester.element(find.byType(AutoIPoEView)),
          )!;
          expect(find.text(l.autoIpoeOpenSettings), findsOneWidget);
          expect(find.text(l.autoIpoeApplyStateIdle), findsNothing);
          expect(find.text(l.save), findsNothing);
          expect(find.text(l.autoIpoeReset), findsNothing);
          expect(find.text(l.autoIpoeExecute), findsOneWidget);
          expect(l.autoIpoeExecute, locale == 'ja' ? '実行' : 'Execute');
          expect(find.text(l.autoIpoeAutoDetection), findsNothing);
          expect(
            find.text(l.autoIpoeNoAdditionalParametersRequired),
            findsNothing,
          );
          final nextButton = find.byWidgetPredicate(
            (w) => w is AppButton && w.identifier == 'auto-ipoe-pnp-continue',
          );
          final title = find.text(l.autoIpoeOpenSettings);
          expect(
            tester.getTopLeft(nextButton).dx,
            closeTo(tester.getTopLeft(title).dx, 1),
          );
          expect(
            find.byKey(const ValueKey('auto-ipoe-log-toggle')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
