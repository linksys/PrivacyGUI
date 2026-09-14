import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_admin.dart';

/// Verifies the E2E identifier hooks on [FirmwareUpdateCard] for
/// PrivacyGUI#1447 (unblocks PrivacyGUI-USP-E2E#85): the card arrival anchor and
/// the manual-update CTA — each locatable via
/// [CommonFinders.bySemanticsIdentifier], never positional.
///
/// The card is the Administration-page entry into the MANUAL firmware update
/// flow. It lives under `firmware_update/views/` while being rendered by the
/// admin view, which is why #1391's nine-page pass did not reach it.
///
/// **`firmware-card-version` is gone as of #1549, and its absence is asserted
/// rather than merely untested.** That split gave the page two entry cards, and
/// "current version" has exactly one owner: [FirmwareOtaCard], because the
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

  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return ProviderScope(
      // The card reads no provider at all since #1549 — it is a
      // `StatelessWidget` whose only job is to push the manual page. The scope
      // stays because the card sits inside one in production, and
      // `adminPageOverrides` keeps this file's fixture the same as its OTA
      // sibling's so the two are read side by side.
      overrides: adminPageOverrides(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        home: const Scaffold(body: FirmwareUpdateCard()),
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
    testWidgets('the card anchor and the CTA are each locatable',
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
  });
}
