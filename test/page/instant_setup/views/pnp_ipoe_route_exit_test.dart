import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_ipoe_view.dart';
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

  void fail(ServiceError error) {
    state = AsyncError<AutoIPoESnapshot>(error, StackTrace.current)
        .copyWithPrevious(state);
  }
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

class _ExitAuth extends AuthNotifier {
  int logouts = 0;
  EndCause? cause;

  @override
  Future<AuthState> build() async => AuthState.empty();

  @override
  Future<void> logout({EndCause cause = EndCause.sessionLost}) async {
    logouts++;
    this.cause = cause;
    state = AsyncData(AuthState.empty());
  }
}

class _ExitPnp extends PnpNotifier {
  int starts = 0;
  Future<void> Function()? onStart;
  @override
  PnpState build() => PnpState.initial();
  @override
  Future<void> startPostLoginFlow() async {
    starts++;
    await onStart?.call();
  }
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
          path: RoutePath.localLoginPassword,
          builder: (_, __) => const Text('Sign in again')),
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
  _ExitAuth? auth,
  AutoIPoEService Function()? serviceFactory,
  StateProvider<DeviceCapabilities>? capabilities,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...commonOverrides(),
      deviceCapabilitiesProvider.overrideWith((ref) => capabilities == null
          ? DeviceCapabilities({DeviceCapability.autoIPoE})
          : ref.watch(capabilities)),
      if (auth != null) authProvider.overrideWith(() => auth),
      appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      autoIPoEDataProvider.overrideWith(() => data),
      autoIPoEPageProvider.overrideWith(() => page),
      autoIPoEServiceProvider.overrideWith((ref) {
        if (!ref
            .watch(deviceCapabilitiesProvider)
            .has(DeviceCapability.autoIPoE)) {
          throw const ResourceNotFoundError();
        }
        return serviceFactory?.call() ?? _ExitService();
      }),
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
  return ProviderScope.containerOf(tester.element(find.byType(PnpIPoEView)));
}

void main() {
  group('Auto-IPoE PnP', _pnpTests);
}

void _pnpTests() {
  for (final error in <ServiceError>[
    const NotAuthenticatedError(),
    const SessionTokenExpiredError(),
    const InvalidSessionTokenError(),
    const ConnectivityError(),
    const NetworkError(),
    const ResourceNotFoundError(),
    const UnauthorizedError(),
  ]) {
    testWidgets('PnP recovers only expired authentication: $error',
        (tester) async {
      final isSessionError = error is NotAuthenticatedError ||
          error is SessionTokenExpiredError ||
          error is InvalidSessionTokenError;
      const savedKey = 'auto-ipoe-submission:https://192.168.1.1';
      const savedRequest =
          '{"requestId":"${AutoIPoETestData.id}","reset":false}';
      SharedPreferences.setMockInitialValues({savedKey: savedRequest});
      final snapshot =
          AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, busy: true);
      final data = _ExitData(snapshot);
      final page = _ExitPage(snapshot, dirty: true);
      final auth = _ExitAuth();
      final pnp = _ExitPnp();
      final router = _router();
      addTearDown(router.dispose);
      const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      final container = await _pump(tester, router, data, page, pnp,
          submission: submission, auth: auth);
      data.fail(error);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Sign in again'),
          isSessionError ? findsOneWidget : findsNothing);
      expect(auth.logouts, isSessionError ? 1 : 0);
      if (isSessionError) expect(auth.cause, EndCause.sessionLost);
      expect(data.exits, 0);
      expect(page.saves, 0);
      expect(pnp.starts, 0);
      expect(container.read(autoIPoESubmissionProvider), submission);
      expect((await SharedPreferences.getInstance()).getString(savedKey),
          savedRequest);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a superseded auth failure cannot end the replacement session',
      (tester) async {
    final snapshot =
        AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, busy: true);
    final data = _ExitData(snapshot);
    final page = _ExitPage(snapshot);
    final auth = _ExitAuth();
    final router = _router();
    addTearDown(router.dispose);
    final container = await _pump(tester, router, data, page, _ExitPnp(),
        auth: auth,
        submission:
            const AutoIPoESubmission(AutoIPoETestData.id, reset: false));
    data.fail(const NotAuthenticatedError());
    // Runs before the recovery callback scheduled by the upcoming build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      container.invalidate(autoIPoEServiceProvider);
      data.publish(snapshot);
    });
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(auth.logouts, 0);
    expect(data.exits, 0);
    expect(page.saves, 0);
    expect(find.byType(PnpIPoEView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final timing in ['replaceBeforeError', 'replaceAfterError', 'rebind']) {
    final rebind = timing == 'rebind';
    testWidgets('late Apply error cannot end a newer session: $timing',
        (tester) async {
      final snapshot = AutoIPoETestData.snapshot();
      final data = _ExitData(snapshot);
      final page = _ExitPage(snapshot, dirty: true);
      final auth = _ExitAuth();
      final router = _router();
      final service = _ExitService();
      bool generationChanged = false;
      when(() => service.checkConnection()).thenAnswer((_) {
        if (generationChanged) throw const NotAuthenticatedError();
      });
      addTearDown(router.dispose);
      final container = await _pump(tester, router, data, page, _ExitPnp(),
          auth: auth, serviceFactory: rebind ? () => service : null);
      final completed = Completer<void>();
      page.onSave = () => completed.future;
      final execute = find.byWidgetPredicate((widget) =>
          widget is AppButton && widget.identifier == 'auto-ipoe-pnp-continue');
      tester.widget<AppButton>(execute).onTap!();
      await tester.pump();
      if (timing == 'replaceAfterError') {
        completed.completeError(const NotAuthenticatedError());
        await tester.idle();
        container.invalidate(autoIPoEServiceProvider);
      } else {
        if (rebind) {
          generationChanged = true;
        } else {
          container.invalidate(autoIPoEServiceProvider);
        }
        completed.completeError(const NotAuthenticatedError());
      }
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(auth.logouts, 0);
      expect(data.exits, 0);
      expect(page.saves, 1);
      expect(find.byType(PnpIPoEView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('read error from a rebound client does not end its new session',
      (tester) async {
    final snapshot =
        AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, busy: true);
    final data = _ExitData(snapshot);
    final page = _ExitPage(snapshot);
    final auth = _ExitAuth();
    final router = _router();
    final service = _ExitService();
    bool generationChanged = false;
    when(() => service.checkConnection()).thenAnswer((_) {
      if (generationChanged) throw const NotAuthenticatedError();
    });
    addTearDown(router.dispose);
    await _pump(tester, router, data, page, _ExitPnp(),
        auth: auth, serviceFactory: () => service);
    generationChanged = true;
    data.fail(const NotAuthenticatedError());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(auth.logouts, 0);
    expect(data.exits, 0);
    expect(find.byType(PnpIPoEView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authentication loss on Apply goes to login without replay',
      (tester) async {
    final snapshot = AutoIPoETestData.snapshot();
    final data = _ExitData(snapshot);
    final page = _ExitPage(snapshot, dirty: true);
    final auth = _ExitAuth();
    final pnp = _ExitPnp();
    final router = _router();
    addTearDown(router.dispose);
    final container = await _pump(tester, router, data, page, pnp, auth: auth);
    page.onSave = () async {
      container.read(autoIPoESubmissionProvider.notifier).state =
          const AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      throw const NotAuthenticatedError();
    };
    final execute = find.byWidgetPredicate((widget) =>
        widget is AppButton && widget.identifier == 'auto-ipoe-pnp-continue');
    tester.widget<AppButton>(execute).onTap!();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Sign in again'), findsOneWidget);
    expect(auth.logouts, 1);
    expect(page.saves, 1);
    expect(data.exits, 0);
    expect(pnp.starts, 0);
    expect(container.read(autoIPoESubmissionProvider)?.requestId,
        AutoIPoETestData.id);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capability withdrawal permits Back without service work',
      (tester) async {
    final snapshot = AutoIPoETestData.snapshot();
    final data = _ExitData(snapshot);
    final page = _ExitPage(snapshot, dirty: true);
    final pnp = _ExitPnp();
    final auth = _ExitAuth();
    final service = _ExitService();
    final capabilities = StateProvider<DeviceCapabilities>(
        (_) => DeviceCapabilities({DeviceCapability.autoIPoE}));
    final router = _router();
    addTearDown(router.dispose);
    final container = await _pump(tester, router, data, page, pnp,
        auth: auth, capabilities: capabilities, serviceFactory: () => service);
    final execute = tester
        .widget<AppButton>(find.byWidgetPredicate((widget) =>
            widget is AppButton &&
            widget.identifier == 'auto-ipoe-pnp-continue'))
        .onTap!;
    expect(page.isDirty(), isTrue);

    container.read(capabilities.notifier).state = DeviceCapabilities.empty;
    data.fail(const NotAuthenticatedError());
    await tester.pump();
    execute(); // A callback retained from before capability withdrawal.
    await tester.pump();

    expect(find.byType(PnpIPoEView), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is AppButton &&
            widget.identifier == 'auto-ipoe-pnp-continue'),
        findsNothing);
    expect(auth.logouts, 0);
    expect(page.saves, 0);
    expect(pnp.starts, 0);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('auto-ipoe-pnp-back')));
    await tester.pumpAndSettle();

    expect(find.text('WAN selection'), findsOneWidget);
    expect(find.byType(PnpIPoEView), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(data.exits, 0);
    expect(page.saves, 0);
    expect(auth.logouts, 0);
    expect(pnp.starts, 0);
    verifyZeroInteractions(service);
    expect(tester.takeException(), isNull);
  });

  for (final stage in ['apply', 'continue']) {
    testWidgets('capability withdrawal stops late $stage completion',
        (tester) async {
      final continuing = stage == 'continue';
      final snapshot = AutoIPoETestData.snapshot(
          requestId: continuing ? AutoIPoETestData.id : null,
          exitCode: continuing ? 0 : null,
          verified: continuing);
      final data = _ExitData(snapshot);
      final page = _ExitPage(snapshot, dirty: !continuing);
      final pnp = _ExitPnp();
      final done = Completer<void>();
      final capabilities = StateProvider<DeviceCapabilities>(
          (_) => DeviceCapabilities({DeviceCapability.autoIPoE}));
      final router = _router();
      addTearDown(router.dispose);
      final container = await _pump(tester, router, data, page, pnp,
          capabilities: capabilities,
          submission: continuing
              ? const AutoIPoESubmission(AutoIPoETestData.id, reset: false)
              : null);
      if (continuing) {
        pnp.onStart = () => done.future;
      } else {
        page.onSave = () async {
          container.read(autoIPoESubmissionProvider.notifier).state =
              const AutoIPoESubmission(AutoIPoETestData.id, reset: false);
          await done.future;
          final completed = AutoIPoETestData.snapshot(
              requestId: AutoIPoETestData.id, exitCode: 0, verified: true);
          data.publish(completed);
          page.publish(completed);
        };
      }
      final execute = find.byWidgetPredicate((widget) =>
          widget is AppButton && widget.identifier == 'auto-ipoe-pnp-continue');
      tester.widget<AppButton>(execute).onTap!();
      await tester.pump();

      container.read(capabilities.notifier).state = DeviceCapabilities.empty;
      done.complete();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(PnpIPoEView), findsOneWidget);
      expect(find.text('Next setup step'), findsNothing);
      expect(page.saves, continuing ? 0 : 1);
      expect(pnp.starts, continuing ? 1 : 0);
      expect(data.exits, 0);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('auto-ipoe-pnp-back')));
      await tester.pumpAndSettle();
      expect(find.text('WAN selection'), findsOneWidget);
      expect(data.exits, 0);
      expect(tester.takeException(), isNull);
    });
  }

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
      expect(find.byType(PnpIPoEView), findsOneWidget);
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
      expect(find.byType(PnpIPoEView), fails ? findsOneWidget : findsNothing);
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
