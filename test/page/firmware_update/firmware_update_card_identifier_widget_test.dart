import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_admin.dart';

/// Verifies the E2E identifier hooks on [FirmwareUpdateCard] for
/// PrivacyGUI#1447 (unblocks PrivacyGUI-USP-E2E#85): the card arrival anchor and
/// the manual-update entry — each locatable via
/// [CommonFinders.bySemanticsIdentifier], never positional.
///
/// The card is the Administration-page entry into the MANUAL firmware update
/// flow. It lives under `firmware_update/views/` while being rendered by the
/// admin view, which is why #1391's nine-page pass did not reach it.
///
/// **`firmware-card-update` is now on a whole-block tap, not on a button**
/// (2026-09-16). The `Update` label promised a flash and a reboot and delivered a
/// route change, so it went the way the OTA card's `checkForUpdates` did. The
/// **id did not go with it**, and that is the one place the two cards
/// deliberately differ: `tests/F06-firmware-journey.spec.ts` item 1 resolves
/// `IDS.firmwareCardUpdate`, asserts a count of one and clicks it, so renaming it
/// to `-open` would have been a cross-repo change bought for nothing. What the
/// spec needs is that the hook is on the thing that navigates and that it still
/// resolves once — both asserted below, the first through a real `GoRouter`
/// rather than by reading the source.
///
/// **`firmware-card-version` is gone as of #1549, and its absence is asserted
/// rather than merely untested.** That split gave the page two entry cards, and
/// "current version" has exactly one owner: `FirmwareOtaCard`, because the
/// manual card is the one that disappears in remote assistance — leaving the
/// version here would have shown a support agent no firmware version at all.
/// The hook did not move by accident and it did not vanish: it is
/// `firmware-ota-card-version` now, pinned in
/// `firmware_ota_card_identifier_widget_test.dart`. The E2E harvest reads Dart
/// source as text, so a renamed hook is silent in both directions; a failing
/// assertion here is the only thing that says which name won.
///
/// Deliberately NOT tagged `ui`: this repo's CI runs only `run_tests.sh`
/// (`--exclude-tags=golden||loc||ui`), and the identifier contract is worth
/// gating there. Assertion shape mirrors
/// `test/page/statistics/usp_statistics_identifier_widget_test.dart`.
void main() {
  const cardAnchor = 'firmware-card';
  const updateHook = 'firmware-card-update';
  const retiredVersionHook = 'firmware-card-version';

  /// Where a tap on the block landed, or null if nothing navigated.
  String? navigatedTo;

  setUp(() => navigatedTo = null);

  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    // A router rather than `home:`, because the card's one action is
    // `pushNamed` — under a plain `MaterialApp` a tap throws instead of
    // navigating, which is a pass nobody asked for.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) =>
              const Scaffold(body: FirmwareUpdateCard()),
        ),
        GoRoute(
          path: '/manual',
          name: RouteNamed.uspFirmwareUpdate,
          builder: (context, state) {
            navigatedTo = RouteNamed.uspFirmwareUpdate;
            return const Scaffold(body: Text('manual update page'));
          },
        ),
      ],
    );
    return ProviderScope(
      // The card reads no provider at all since #1549 — it is a
      // `StatelessWidget` whose only job is to push the manual page. The scope
      // stays because the card sits inside one in production, and
      // `adminPageOverrides` keeps this file's fixture the same as its OTA
      // sibling's so the two are read side by side.
      overrides: adminPageOverrides(),
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  group('FirmwareUpdateCard identifiers', () {
    testWidgets('the card anchor and the entry are each locatable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final matched = <Element>{};
      for (final id in <String>[cardAnchor, updateHook]) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(2),
          reason: 'the two hooks must target distinct widgets');

      handle.dispose();
    });

    testWidgets('the retired version hook is not on this card', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(find.bySemanticsIdentifier(retiredVersionHook), findsNothing,
          reason: '"$retiredVersionHook" moved to the OTA card in #1549. If it '
              'is back here, one version is being rendered twice and the E2E '
              'specs cannot tell which card they landed on');

      handle.dispose();
    });

    testWidgets('the Update button is gone, and its hook stayed',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final loc = await AppLocalizations.delegate.load(const Locale('en'));
      // The label, not just the widget: `AppButton` could be swapped for another
      // kit button and the copy would still be making the promise the card
      // cannot keep.
      expect(find.text(loc.update), findsNothing,
          reason: 'the `update` label promised a flash and a reboot while only '
              'pushing a page; the block navigates and says so');
      expect(find.byType(AppButton), findsNothing,
          reason: 'this card is an entry point — there is nothing on it to '
              'press that is not the whole row');
      // The other half, and the reason this test is not two: the hook the E2E
      // spec resolves has to survive the button it used to sit on.
      expect(find.bySemanticsIdentifier(updateHook), findsOneWidget,
          reason: 'F06 item 1 clicks "$updateHook"; removing the button must '
              'not remove the hook');

      handle.dispose();
    });

    testWidgets('the row carries the navigation chevron', (tester) async {
      await pumpCard(tester);

      expect(find.byIcon(AppFontIcons.chevronRight), findsOneWidget,
          reason: 'the chevron is what tells a sighted user the row opens a '
              'page, now that no button says so');
    });
  });

  group('FirmwareUpdateCard entry', () {
    testWidgets('tapping the block opens the manual update page',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(navigatedTo, isNull,
          reason: 'nothing may navigate before the tap');
      await tester.tap(find.bySemanticsIdentifier(updateHook));
      await tester.pumpAndSettle();

      expect(navigatedTo, RouteNamed.uspFirmwareUpdate,
          reason: 'the hook E2E clicks must be the thing that navigates');

      handle.dispose();
    });

    testWidgets('the block announces itself as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      // What replaced the button has to keep what the button gave assistive
      // tech: a row that is tappable but announced as text is a control a screen
      // reader user cannot find.
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(updateHook)),
        isSemantics(isButton: true, hasTapAction: true),
      );

      handle.dispose();
    });
  });
}
