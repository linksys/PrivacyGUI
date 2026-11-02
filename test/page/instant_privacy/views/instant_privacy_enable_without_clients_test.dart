import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_fetch_result.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../util/app_test_fonts.dart';

class _MockMacFilterService extends Mock implements UspMacFilterService {}

/// #1735 as reported: with no client online — e.g. the admin is the only device
/// and is wired — tapping the Instant Privacy switch did nothing.
///
/// Product rule (issue comments): Instant Privacy can be turned on with no
/// connected client, regardless of LAN ports, and an empty `Allow` list can be
/// saved. 2.x keeps its toggle + Save flow: the switch only stages the change,
/// and the device is written on Save.
///
/// The real notifier runs here over a mocked service, so the staged state
/// (toggled, not saved — nothing written) and the after-Save state (the write
/// that went out, and the page reading back clean and on) are both asserted.
///
/// **Untagged on purpose**, like the other view tests in this directory, so
/// `run_tests.sh` (which excludes `golden||loc||ui`) runs it.
void main() {
  late _MockMacFilterService service;

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(MacFilterMode.disabled);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    service = _MockMacFilterService();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder switchFinder() => find.byWidgetPredicate(
      (w) => w is AppSwitch && w.identifier == 'instant-privacy-enable');
  Finder saveFinder() => find
      .byWidgetPredicate((w) => w is AppButton && w.identifier == 'page-save');

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const InstantPrivacyView(),
      locale: const Locale('en'),
      overrides: [uspMacFilterServiceProvider.overrideWithValue(service)],
    ));
    await settle(tester);
  }

  testWidgets(
      'no client online: the switch stages on, and Save writes Allow with an '
      'empty list', (tester) async {
    // What the device reads before Save: off, nothing online.
    var onDevice = const MacFilterFetchResult(
      mode: MacFilterMode.disabled,
      macs: [],
      connectedDevices: [],
    );
    when(() => service.fetchAll()).thenAnswer((_) async => onDevice);
    when(() => service.setMacFilter(any(), any())).thenAnswer((inv) async {
      onDevice = MacFilterFetchResult(
        mode: inv.positionalArguments[0] as MacFilterMode,
        macs: List<String>.from(inv.positionalArguments[1] as List),
        connectedDevices: const [],
      );
    });

    await pumpPage(tester);

    expect(tester.widget<AppSwitch>(switchFinder()).value, isFalse);
    expect(tester.widget<AppSwitch>(switchFinder()).onChanged, isNotNull,
        reason: 'the switch must respond with no client online (#1735)');
    expect(saveFinder(), findsNothing, reason: 'nothing changed yet');

    // --- Staged: toggled, not saved ---------------------------------------
    await tester.tap(switchFinder());
    await settle(tester);

    expect(tester.widget<AppSwitch>(switchFinder()).value, isTrue,
        reason: 'tapping the switch turns Instant Privacy on (staged)');
    expect(find.text('No devices in the allowed list.'), findsOneWidget);
    expect(saveFinder(), findsOneWidget, reason: 'the change awaits Save');
    expect(tester.widget<AppButton>(saveFinder()).onTap, isNotNull,
        reason: 'an empty Allow list can be saved (#1735)');
    verifyNever(() => service.setMacFilter(any(), any()));

    // --- After Save ---------------------------------------------------------
    await tester.tap(saveFinder());
    await settle(tester);

    verify(() => service.setMacFilter(MacFilterMode.allow, <String>[]))
        .called(1);
    expect(tester.widget<AppSwitch>(switchFinder()).value, isTrue,
        reason: 'the page reads Allow back after Save');
    expect(saveFinder(), findsNothing, reason: 'saved: nothing left to save');
  });
}
