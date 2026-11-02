import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/local_network/cards/usp_dhcp_reservations_card.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_dhcp.dart'
    show FixedDevicesDataNotifier, FixedDhcpDataNotifier, FixedLanDataNotifier;
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' show testLanInfo;
import '../../../util/app_test_fonts.dart';

class MockUspDhcpService extends Mock implements UspDhcpService {}

/// linksys/PrivacyGUI#1698 on the real DHCP page and the real Dashboard card,
/// over the real reservations notifier and a mocked service.
///
/// The service and notifier suites prove what is thrown and re-read; the
/// dialog suite proves the name rule inside the dialog. What only a pumped
/// page can show is the wiring between them: that the detail page's Save
/// shows FW's check rather than the generic text, that the Dashboard card's
/// Add does the same, and that a name FW would refuse never leaves the dialog
/// the page opens.
///
/// **Untagged on purpose** so `run_tests.sh` (and so CI's Unit Tests job) runs it.
void main() {
  late MockUspDhcpService svc;
  late AppLocalizations l;

  final saved = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.120',
    enable: true,
  );

  const refused = InvalidInputError(
    field: DhcpReservationRefusalNames.invalidIp,
    code: 7012,
    detail: DhcpReservationRefusalNames.invalidIp,
  );

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(<DhcpReservationUIModel>[]);
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() => svc = MockUspDhcpService());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pump(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: view,
      locale: const Locale('en'),
      overrides: [
        uspDhcpServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        lanDataProvider.overrideWith(
            () => FixedLanDataNotifier(LanData(model: testLanInfo))),
        dhcpDataProvider.overrideWith(() => FixedDhcpDataNotifier(
            DhcpData(clientModels: const [], reservationModels: [saved]))),
        devicesDataProvider.overrideWith(() => FixedDevicesDataNotifier()),
      ],
    ));
    await settle(tester);
    await tester.pumpAndSettle();
  }

  Finder byId<T extends Widget>(String id) => find.byWidgetPredicate(
        (w) =>
            (w is AppTextField && w.identifier == id) ||
            (w is AppButton && w.identifier == id) ||
            (w is AppIconButton && w.identifier == id),
        description: "identifier '$id'",
      );

  Future<void> enter(WidgetTester tester, String id, String text) async {
    await tester.enterText(
        find.descendant(of: byId(id), matching: find.byType(TextField)), text);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus(); // validates on blur
    await tester.pumpAndSettle();
  }

  String snackText(WidgetTester tester) {
    final bar = find.byType(SnackBar);
    expect(bar, findsOneWidget, reason: 'a failed save must say so');
    return find
        .descendant(of: bar, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .join(' ');
  }

  group('DHCP detail page', () {
    testWidgets(
        'Save that FW refuses shows FW\'s check, not the generic text, '
        'and the list shows what the router holds', (tester) async {
      // What the router holds after the refused Set: obuspa committed the
      // name, FW refused the IP (FWDEV#211, to do 4).
      final onRouter = saved.copyWith(name: 'tv');
      var refusedOnce = false;
      when(() => svc.fetchReservations())
          .thenAnswer((_) async => refusedOnce ? [onRouter] : [saved]);
      // Fails after a beat, as a real Set does: `doSomethingWithSpinner`
      // starts listening ~100ms in.
      when(() => svc.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        refusedOnce = true;
        throw refused;
      });
      await pump(tester, const UspDhcpDetailView());
      expect(find.text(saved.ip), findsOneWidget);

      await tester.tap(byId('dhcp-reservation-edit-${saved.identifierKey}'));
      await tester.pumpAndSettle();
      await enter(tester, 'dhcp-reservation-ip', '192.168.1.121');
      await tester.tap(byId('dhcp-reservation-submit'));
      await tester.pumpAndSettle();
      expect(find.text('192.168.1.121'), findsOneWidget,
          reason: 'the edit is pending on the page');

      await tester.tap(byId('page-save'));
      await settle(tester);
      await tester.pumpAndSettle();

      final text = snackText(tester);
      expect(text, contains(l.invalidIpAddress),
          reason: 'FW named the check it refused (FWDEV#211)');
      expect(text, isNot(contains(l.errorInvalidInput)),
          reason: 'the generic text is what #1698 replaces');
      expect(find.text(l.dhcpReservationsSaved), findsNothing);
      expect(find.text('tv'), findsOneWidget,
          reason: 'the page re-reads the router: the committed name shows');
      expect(find.text(saved.ip), findsOneWidget,
          reason: 'and the IP FW refused is the one the router kept');
      expect(find.text('192.168.1.121'), findsNothing);
    });

    testWidgets(
        'a name FW would refuse is stopped in the dialog the page opens',
        (tester) async {
      when(() => svc.fetchReservations()).thenAnswer((_) async => [saved]);
      await pump(tester, const UspDhcpDetailView());

      await tester.tap(find.descendant(
          of: find.byType(UspDhcpDetailView),
          matching: find.byIcon(Icons.add)));
      await tester.pumpAndSettle();
      await enter(tester, 'dhcp-reservation-mac', 'AA:BB:CC:DD:EE:99');
      await enter(tester, 'dhcp-reservation-ip', '192.168.1.130');
      await enter(tester, 'dhcp-reservation-name', '-tv');

      final field = tester.widget<AppTextField>(byId('dhcp-reservation-name'));
      expect(field.errorText, l.reservationNameInvalid);
      await tester.tap(byId('dhcp-reservation-submit'));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget,
          reason: 'Add must stay disabled');
      expect(byId('page-save'), findsNothing,
          reason: 'nothing reached the page, so nothing can be sent');
      verifyNever(() => svc.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          ));
    });

    testWidgets('a valid name reaches the batch the page sends',
        (tester) async {
      when(() => svc.fetchReservations()).thenAnswer((_) async => [saved]);
      when(() => svc.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return (added: 1, updated: 0, deleted: 0);
      });
      await pump(tester, const UspDhcpDetailView());

      await tester.tap(find.descendant(
          of: find.byType(UspDhcpDetailView),
          matching: find.byIcon(Icons.add)));
      await tester.pumpAndSettle();
      await enter(tester, 'dhcp-reservation-mac', 'AA:BB:CC:DD:EE:99');
      await enter(tester, 'dhcp-reservation-ip', '192.168.1.130');
      await enter(tester, 'dhcp-reservation-name', 'Printer-2');
      await tester.tap(byId('dhcp-reservation-submit'));
      await tester.pumpAndSettle();
      await tester.tap(byId('page-save'));
      await settle(tester);
      await tester.pumpAndSettle();

      final current = verify(() => svc.saveBatch(
            original: any(named: 'original'),
            current: captureAny(named: 'current'),
          )).captured.single as List<DhcpReservationUIModel>;
      expect(current.where((r) => r.mac == 'AA:BB:CC:DD:EE:99').single.name,
          'Printer-2');
    });
  });

  group('Dashboard DHCP card', () {
    testWidgets('Add that FW refuses shows FW\'s check, not the generic text',
        (tester) async {
      when(() => svc.fetchReservations()).thenAnswer((_) async => [saved]);
      when(() => svc.immediateAdd(
            mac: any(named: 'mac'),
            ip: any(named: 'ip'),
            enable: any(named: 'enable'),
            name: any(named: 'name'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw refused;
      });
      await pump(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
                width: 500, height: 700, child: UspDhcpReservationsCard()),
          ),
        ),
      );

      await tester.tap(find.descendant(
          of: find.byType(UspDhcpReservationsCard),
          matching: find.byIcon(Icons.add)));
      await tester.pumpAndSettle();
      await enter(tester, 'dhcp-reservation-mac', 'AA:BB:CC:DD:EE:99');
      await enter(tester, 'dhcp-reservation-ip', '192.168.1.130');
      await tester.tap(byId('dhcp-reservation-submit'));
      await settle(tester);
      await tester.pumpAndSettle();

      final text = snackText(tester);
      expect(text, contains(l.invalidIpAddress));
      expect(text, isNot(contains(l.errorInvalidInput)));
      expect(find.text(l.reservationAdded), findsNothing);
    });
  });
}
