import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_card.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_admin.dart';

/// Verifies the E2E identifier hooks on [FirmwareOtaCard], added by #1549.
///
/// Three hooks, named for symmetry with the manual card's `firmware-card-*`
/// family: the card arrival anchor, the check CTA, and the current-version
/// value. `firmware-ota-card-check` is deliberately distinct from the OTA
/// *page*'s own `firmware-check` — the card opens the page, so a spec that
/// confused them would tap the wrong surface and still pass on the way in.
///
/// **This card owns "current version" for the whole Administration page.** It
/// took the hook over from [FirmwareUpdateCard] because the manual card is the
/// one hidden in remote assistance; the absent half of that decision is
/// asserted in `firmware_update_card_identifier_widget_test.dart`, so the pair
/// pins one owner from both sides.
///
/// Deliberately NOT tagged `ui`, matching its sibling: this repo's CI runs only
/// `run_tests.sh` (`--exclude-tags=golden||loc||ui`), and the identifier
/// contract is worth gating there.
void main() {
  const cardAnchor = 'firmware-ota-card';
  const checkHook = 'firmware-ota-card-check';
  const versionHook = 'firmware-ota-card-version';

  // From the shared admin fixture `gateAdminSystemInfo`, whose one active bank
  // carries this version. The card reads it as `activeVersion`.
  const activeVersion = '1.0.16.213451';

  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return ProviderScope(
      // The card watches only `systemInfoDataProvider`; `adminPageOverrides`
      // pins it to the fixture with an active firmware bank so the version
      // value and the CTA both render (the loading branch hides both).
      overrides: adminPageOverrides(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        home: const Scaffold(body: FirmwareOtaCard()),
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

  group('FirmwareOtaCard identifiers', () {
    testWidgets('the card anchor, CTA, and version are each locatable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final matched = <Element>{};
      for (final id in <String>[cardAnchor, checkHook, versionHook]) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(3),
          reason: 'the three hooks must target distinct widgets');

      handle.dispose();
    });

    testWidgets('the version hook wraps the active firmware version text',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      // The pinned node carries the identifier; the version string it wraps is
      // what E2E asserts against, so prove they are the same subtree.
      final version = find.descendant(
        of: find.bySemanticsIdentifier(versionHook),
        matching: find.text(activeVersion),
      );
      expect(version, findsOneWidget,
          reason:
              '"$versionHook" must wrap the active version "$activeVersion"');

      handle.dispose();
    });

    testWidgets('the CTA is hidden while the router info is still loading',
        (tester) async {
      // The loading branch renders a skeleton in place of the version and drops
      // the button entirely, so a spec cannot tap "check for updates" before
      // there is a version to compare against. Pinned because the skeleton
      // moved to this card with the version block, and a hook that appears one
      // frame early is exactly the flake E2E cannot diagnose.
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: adminPageLoadingFirmwareOverrides(),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
            home: const Scaffold(body: FirmwareOtaCard()),
          ),
        ),
      );
      // Not `pumpAndSettle`: the loading state never completes by design.
      await tester.pump();

      expect(find.bySemanticsIdentifier(cardAnchor), findsOneWidget,
          reason: 'the card itself is on screen either way — only its contents '
              'change');
      expect(find.bySemanticsIdentifier(checkHook), findsNothing);
      expect(find.bySemanticsIdentifier(versionHook), findsNothing);

      handle.dispose();
    });
  });
}
