import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class _Service extends Mock implements AutoIPoEService {}

Finder _button(String identifier) => find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.identifier == identifier,
    );

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpPicker(WidgetTester tester, _Service service) async {
  final picker = pnpNoInternetRoute.routes.whereType<GoRoute>().singleWhere(
        (route) => route.name == RouteNamed.pnpIspTypeSelection,
      );
  final router = GoRouter(
    initialLocation: '/wan',
    routes: [
      GoRoute(
        path: '/wan',
        name: RouteNamed.pnpIspTypeSelection,
        builder: (_, __) => const PnpIspSettingsView(),
        routes: picker.routes,
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...commonOverrides(),
      appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      autoIPoEServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp.router(
      theme: AppTheme.create(brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await _pumpFrames(tester);
}

void main() {
  group('Auto-IPoE enabled recovery', () {
    setUpAll(() {
      registerFallbackValue(
        const AutoIPoESubmission(AutoIPoETestData.id, reset: true),
      );
    });

    late _Service service;
    setUp(() {
      service = _Service();
      when(() => service.loadSubmission()).thenAnswer((_) async => null);
      when(() => service.storeSubmission(any())).thenAnswer((_) async {});
      when(() => service.clearSubmission()).thenAnswer((_) async {});
    });

    for (final available in [false, true]) {
      for (final rejected in [false, true]) {
        testWidgets(
            'managed WAN remains recoverable: capabilitiesAvailable=$available, resetRejected=$rejected',
            (tester) async {
          var current = Future.value(AutoIPoETestData.recoverySnapshot(
            capabilitiesAvailable: available,
          ));
          when(() => service.fetch()).thenAnswer((_) => current);
          final completion = Completer<AutoIPoESnapshot>();
          AutoIPoESubmission? reset;
          when(() => service.submit(any(),
                  settings: any(named: 'settings'),
                  resetFirst: any(named: 'resetFirst')))
              .thenAnswer((invocation) async {
            reset = invocation.positionalArguments.single as AutoIPoESubmission;
            expectSync(reset!.reset, isTrue);
            expectSync(invocation.namedArguments[#settings], isNull);
            if (!rejected) current = completion.future;
            return AutoIPoEReceipt(accepted: !rejected);
          });
          await _pumpPicker(tester, service);
          // Exhaust the bounded capability retries. Recovery cannot depend on
          // an automatic read eventually succeeding.
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(seconds: 3));
            await tester.pump();
          }
          expect(find.text('DHCP'), findsNothing);
          expect(find.text('PPPoE'), findsNothing);
          expect(find.text('IPoE'), findsOneWidget);
          await tester.tap(find.text('IPoE'));
          await _pumpFrames(tester);
          expect(find.byType(AutoIPoEView), findsOneWidget);
          expect(find.byType(AutoIPoESection), findsNothing);
          expect(_button('auto-ipoe-pnp-continue'), findsNothing);
          expect(_button('auto-ipoe-pnp-retry-settings'), findsOneWidget);
          final recovery = _button('auto-ipoe-pnp-recovery-reset');
          expect(recovery, findsOneWidget);
          final callback = tester.widget<AppButton>(recovery).onTap!;
          callback();
          callback();
          await _pumpFrames(tester);
          verify(() => service.submit(any(),
              settings: any(named: 'settings'),
              resetFirst: any(named: 'resetFirst'))).called(1);
          expect(find.text('DHCP'), findsNothing);

          if (rejected) {
            final context = tester.element(find.byType(AutoIPoEView));
            expect(
                find.text(
                    localizeServiceError(context, const UnexpectedError())),
                findsOneWidget);
            expect(recovery, findsOneWidget);
            expect(_button('auto-ipoe-pnp-retry-settings'), findsOneWidget);
            verifyNever(() => service.clearSubmission());
          } else {
            expect(find.byType(AppLoader), findsOneWidget);
            expect(recovery, findsNothing);
            completion.complete(AutoIPoETestData.recoverySnapshot(
              capabilitiesAvailable: available,
              resetRequestId: reset!.requestId,
            ));
            await _pumpFrames(tester);
            expect(find.byType(AutoIPoEView), findsNothing);
            expect(find.byType(PnpIspSettingsView), findsOneWidget);
            expect(find.text('DHCP'), findsOneWidget);
            expect(find.text('PPPoE'), findsOneWidget);
            // Unsupported IPoE must not become a new selectable connection.
            expect(find.text('IPoE'), findsNothing);
            verify(() => service.clearSubmission()).called(1);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }

      testWidgets('retry restores capabilities without writing: $available',
          (tester) async {
        var snapshot = AutoIPoETestData.recoverySnapshot(
          capabilitiesAvailable: available,
        );
        when(() => service.fetch()).thenAnswer((_) async => snapshot);
        await _pumpPicker(tester, service);
        await tester.tap(find.text('IPoE'));
        await _pumpFrames(tester);
        expect(find.byType(AutoIPoESection), findsNothing);
        snapshot = AutoIPoETestData.recoverySnapshot(
          capabilitiesAvailable: true,
          supported: true,
        );
        await tester.tap(_button('auto-ipoe-pnp-retry-settings'));
        await _pumpFrames(tester);
        expect(find.byType(AutoIPoESection), findsOneWidget);
        expect(_button('auto-ipoe-pnp-continue'), findsOneWidget);
        verifyNever(() => service.submit(any(),
            settings: any(named: 'settings'),
            resetFirst: any(named: 'resetFirst')));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }, skip: !BuildConfig.autoIPoEEnabled);
}
