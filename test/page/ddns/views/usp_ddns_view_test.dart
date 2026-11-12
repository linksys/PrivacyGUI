import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/providers/usp_ddns_notifier.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_service.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_status_data_service.dart';
import 'package:privacy_gui/page/ddns/views/usp_ddns_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wan_data.dart';
import '../../../mocks/test_data/ddns_test_data.dart';
import '../../../util/app_test_fonts.dart';

class MockUspDdnsService extends Mock implements UspDdnsService {}

class MockUspDdnsStatusDataService extends Mock
    implements UspDdnsStatusDataService {}

/// Advanced Settings → DDNS (#641) on the real page, over the real notifiers and
/// mocked services: what the provider card and the status card show, what a
/// field check holds back, and what Save sends.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late MockUspDdnsService service;
  late MockUspDdnsStatusDataService statusService;
  late DdnsSettings device;
  late DdnsUpdateStatus deviceStatus;

  const publicWan = WanStatusUIModel(
    isUp: true,
    ipAddress: '203.0.113.7',
    subnetMask: '255.255.255.0',
    addressingType: 'DHCP',
    mtu: 1500,
  );

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(DdnsTestData.settings());
  });

  setUp(() {
    service = MockUspDdnsService();
    statusService = MockUspDdnsStatusDataService();
    device = DdnsTestData.settings();
    deviceStatus = DdnsUpdateStatus.disabled;
    when(() => service.fetch())
        .thenAnswer((_) async => (device, const DdnsStatus(isLoading: false)));
    when(() => statusService.fetch(fresh: any(named: 'fresh')))
        .thenAnswer((_) async => deviceStatus);
  });

  final providerDropdown = find.byWidgetPredicate(
      (w) => w is AppDropdown && w.identifier == 'ddns-provider');
  final usernameField = find.byWidgetPredicate(
      (w) => w is AppTextField && w.identifier == 'ddns-username');
  final passwordField = find.byWidgetPredicate(
      (w) => w is AppTextField && w.identifier == 'ddns-password');
  final hostnameField = find.byWidgetPredicate(
      (w) => w is AppTextField && w.identifier == 'ddns-hostname');
  final saveButton = find.widgetWithText(AppButton, 'Save');

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    WanStatusUIModel wan = publicWan,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: Builder(
        builder: (context) => TextButton(
          onPressed: () => context.push('/ddns'),
          child: const Text('open'),
        ),
      ),
      locale: const Locale('en'),
      overrides: [
        uspDdnsServiceProvider.overrideWithValue(service),
        uspDdnsStatusDataServiceProvider.overrideWithValue(statusService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        wanDataOverride(wan),
      ],
      extraRoutes: [
        LinksysRoute(
          path: '/ddns',
          builder: (context, state) => const UspDdnsView(),
          preservableProvider: uspDdnsProvider.notifier,
        ),
      ],
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.pumpAndSettle();
  }

  Future<void> chooseProvider(WidgetTester tester, String name) async {
    await tester.tap(providerDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<AppButton>(saveButton).onTap != null;

  group('UspDdnsView - provider card', () {
    testWidgets('the shipped rows read "Disabled" with no fields',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('Disabled'), findsOneWidget);
      expect(usernameField, findsNothing);
      expect(passwordField, findsNothing);
      expect(hostnameField, findsNothing);
    });

    testWidgets('the dropdown lists "Disabled" and the router\'s providers',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(providerDropdown);
      await tester.pumpAndSettle();

      expect(find.text('DynDNS'), findsOneWidget);
      expect(find.text('No-IP'), findsOneWidget);
    });

    testWidgets('a stored account fills the fields, and the password keeps it',
        (tester) async {
      device = DdnsTestData.configuredSettings();
      await pumpPage(tester);

      expect(find.text('No-IP'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('home.example.net'), findsOneWidget);
      expect(find.text('Leave blank to keep the current password'),
          findsOneWidget);
    });

    testWidgets('a new provider drops the keep hint: its password is needed',
        (tester) async {
      device = DdnsTestData.configuredSettings();
      await pumpPage(tester);

      await chooseProvider(tester, 'DynDNS');

      expect(
          find.text('Leave blank to keep the current password'), findsNothing);
    });

    testWidgets('with no account stored the password field has no keep hint',
        (tester) async {
      await pumpPage(tester);

      await chooseProvider(tester, 'No-IP');

      expect(passwordField, findsOneWidget);
      expect(
          find.text('Leave blank to keep the current password'), findsNothing);
    });
  });

  group('UspDdnsView - field checks', () {
    testWidgets('Save stays off until every field passes', (tester) async {
      await pumpPage(tester);

      await chooseProvider(tester, 'No-IP');
      expect(saveEnabled(tester), isFalse, reason: 'the fields are empty');

      await tester.enterText(usernameField, 'user@example.com');
      await tester.enterText(passwordField, 'secret');
      await tester.enterText(hostnameField, 'my_home.example.net');
      await settle(tester);
      expect(saveEnabled(tester), isFalse, reason: '_ is not allowed');

      await tester.enterText(hostnameField, 'home.example.net');
      await settle(tester);
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('a failing field shows its error when it loses focus',
        (tester) async {
      await pumpPage(tester);
      await chooseProvider(tester, 'No-IP');

      await tester.enterText(hostnameField, 'bad..name');
      await settle(tester);
      expect(find.text('Invalid host name'), findsNothing,
          reason: 'not while it is being typed');

      await tester.tap(usernameField);
      await settle(tester);

      expect(find.text('Invalid host name'), findsOneWidget);
    });
  });

  group('UspDdnsView - field order', () {
    testWidgets('leaving one field does not mark the ones not reached yet',
        (tester) async {
      await pumpPage(tester);
      await chooseProvider(tester, 'No-IP');

      await tester.enterText(usernameField, 'user@example.com');
      await tester.tap(passwordField);
      await settle(tester);

      expect(find.text('Invalid password'), findsNothing);
      expect(find.text('Invalid host name'), findsNothing);
    });
  });

  group('UspDdnsView - save', () {
    testWidgets('Save sends what the fields hold', (tester) async {
      when(() => service.save(any())).thenAnswer((_) async {});
      await pumpPage(tester);
      await chooseProvider(tester, 'No-IP');
      await tester.enterText(usernameField, 'user@example.com');
      await tester.enterText(passwordField, 'secret');
      await tester.enterText(hostnameField, 'home.example.net');
      await settle(tester);

      await tester.tap(saveButton);
      await settle(tester);

      final saved = verify(() => service.save(captureAny())).captured.single
          as DdnsSettings;
      expect(saved.providerPath, DdnsTestData.noIpPath);
      expect(saved.username, 'user@example.com');
      expect(saved.password, 'secret');
      expect(saved.hostname, 'home.example.net');
      expect(find.text('Changes saved'), findsOneWidget);
    });

    testWidgets(
        'choosing "Disabled" over a stored account saves with no '
        'field check', (tester) async {
      device = DdnsTestData.configuredSettings();
      when(() => service.save(any())).thenAnswer((_) async {});
      await pumpPage(tester);

      await chooseProvider(tester, 'Disabled');
      expect(saveEnabled(tester), isTrue);
      await tester.tap(saveButton);
      await settle(tester);

      final saved = verify(() => service.save(captureAny())).captured.single
          as DdnsSettings;
      expect(saved.isEnabled, isFalse);
    });
  });

  group('UspDdnsView - status card', () {
    testWidgets('absent while the router\'s client is disabled',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('DDNS status'), findsNothing);
    });

    testWidgets('shows the Internet IP address and the status', (tester) async {
      device = DdnsTestData.configuredSettings();
      deviceStatus = DdnsUpdateStatus.authenticationFailed;
      await pumpPage(tester);

      expect(find.text('DDNS status'), findsOneWidget);
      expect(find.text('203.0.113.7'), findsOneWidget);
      expect(find.text('Authentication failed'), findsOneWidget);
    });

    testWidgets('a connection failure behind a private address says why',
        (tester) async {
      device = DdnsTestData.configuredSettings();
      deviceStatus = DdnsUpdateStatus.connectionFailed;
      await pumpPage(tester, wan: wanUpModel);

      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('is private'), findsOneWidget);
    });

    testWidgets('a connection failure on a public address does not',
        (tester) async {
      device = DdnsTestData.configuredSettings();
      deviceStatus = DdnsUpdateStatus.connectionFailed;
      await pumpPage(tester);

      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('is private'), findsNothing);
    });

    testWidgets('a status read that fails still shows the card, as unknown',
        (tester) async {
      device = DdnsTestData.configuredSettings();
      when(() => statusService.fetch(fresh: any(named: 'fresh')))
          .thenThrow(const NetworkError(detail: 'read failed'));
      await pumpPage(tester);

      expect(find.text('DDNS status'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              w is AppIconButton && w.identifier == 'ddns-status-refresh'),
          findsOneWidget);
    });

    testWidgets('the refresh icon reads the status again', (tester) async {
      device = DdnsTestData.configuredSettings();
      deviceStatus = DdnsUpdateStatus.connecting;
      await pumpPage(tester);
      expect(find.text('Connecting...'), findsOneWidget);
      deviceStatus = DdnsUpdateStatus.success;

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == 'ddns-status-refresh'));
      await settle(tester);

      verify(() => statusService.fetch(fresh: true)).called(1);
      expect(find.text('Success'), findsOneWidget);
    });
  });
}
