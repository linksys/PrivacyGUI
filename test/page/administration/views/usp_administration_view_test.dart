import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/providers/usp_administration_notifier.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';
import 'package:privacy_gui/page/administration/views/usp_administration_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../util/app_test_fonts.dart';

class MockUspAdministrationService extends Mock
    implements UspAdministrationService {}

/// Advanced Settings → Administration (#1660) on the real page, over the real
/// notifier and a mocked service: what the switch shows, what Save sends, what a
/// failure leaves on screen, and that leaving with an edit is caught.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late MockUspAdministrationService svc;
  late bool deviceValue;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    svc = MockUspAdministrationService();
    deviceValue = true;
    when(() => svc.fetch()).thenAnswer(
        (_) async => AdministrationSettings(upnpEnabled: deviceValue));
  });

  final upnpSwitch = find.byWidgetPredicate(
      (w) => w is AppSwitch && w.identifier == 'administration-upnp');

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// [extraRoutes] gives the page somewhere to leave to, through the same
  /// `LinksysRoute` + `preservableProvider` pair `lib/route` declares.
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: Builder(
        builder: (context) => TextButton(
          onPressed: () => context.push('/administration'),
          child: const Text('open'),
        ),
      ),
      locale: const Locale('en'),
      overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
      extraRoutes: [
        LinksysRoute(
          path: '/administration',
          builder: (context, state) => const UspAdministrationView(),
          preservableProvider: uspAdministrationProvider.notifier,
        ),
      ],
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    // Let the push transition finish: a pop while the route is still entering
    // trips the navigator's lifecycle assertion.
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<AppSwitch>(upnpSwitch).value;

  group('UspAdministrationView - UPnP switch', () {
    testWidgets('the switch shows Device.UPnP.Device.Enable', (tester) async {
      await pumpPage(tester);

      expect(find.text('UPnP'), findsOneWidget);
      expect(switchValue(tester), isTrue);
      expect(find.widgetWithText(AppButton, 'Save'), findsNothing,
          reason: 'nothing edited, so no Save bar');
    });

    testWidgets('flipping writes nothing; Save sends one Set', (tester) async {
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {
        deviceValue = false;
      });
      await pumpPage(tester);

      await tester.tap(upnpSwitch);
      await settle(tester);
      expect(switchValue(tester), isFalse);
      verifyNever(() => svc.setUpnpEnabled(any()));

      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await settle(tester);

      verify(() => svc.setUpnpEnabled(false)).called(1);
      expect(switchValue(tester), isFalse);
      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsNothing);
    });

    testWidgets('a failed Set shows an error and the device value',
        (tester) async {
      // Fails after a beat, as a real Set does. `doSomethingWithSpinner` starts
      // listening to the task ~100ms in, so a mock that throws synchronously
      // fails the task before anything is listening and the test framework
      // reports it as unhandled — a property of the stub, not of the page.
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw const NetworkError(detail: 'unreachable');
      });
      await pumpPage(tester);

      await tester.tap(upnpSwitch);
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await settle(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Changes saved'), findsNothing);
      expect(switchValue(tester), isTrue, reason: 'the router still holds on');
    });

    testWidgets('leaving with an unsaved change asks first', (tester) async {
      await pumpPage(tester);

      await tester.tap(upnpSwitch);
      await settle(tester);
      GoRouter.of(tester.element(upnpSwitch)).pop();
      await settle(tester);

      expect(find.text('You have unsaved changes on this page'), findsOneWidget,
          reason: "the route's dirty guard is this notifier");
      expect(upnpSwitch, findsOneWidget, reason: 'still on the page');
    });

    testWidgets('leaving with nothing edited does not ask', (tester) async {
      await pumpPage(tester);

      GoRouter.of(tester.element(upnpSwitch)).pop();
      // The exit transition, not just the async `onExit`.
      await tester.pumpAndSettle();

      expect(find.text('You have unsaved changes on this page'), findsNothing);
      expect(upnpSwitch, findsNothing, reason: 'the page is gone');
      expect(find.text('open'), findsOneWidget);
    });
  });
}
