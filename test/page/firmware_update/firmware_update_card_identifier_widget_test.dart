import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_admin.dart';

/// Verifies the E2E identifier hooks added to [FirmwareUpdateCard] for
/// PrivacyGUI#1447 (unblocks PrivacyGUI-USP-E2E#85): the card arrival anchor,
/// the manual-update CTA, and the current-version value — each locatable via
/// [CommonFinders.bySemanticsIdentifier], never positional.
///
/// The card is the Administration-page entry into the manual firmware update
/// flow; it lives under `firmware_update/views/` while being rendered by the
/// admin view, which is why #1391's nine-page pass did not reach it.
///
/// Deliberately NOT tagged `ui`: this repo's CI runs only `run_tests.sh`
/// (`--exclude-tags=golden||loc||ui`), and the identifier contract is worth
/// gating there. Assertion shape mirrors
/// `test/page/statistics/usp_statistics_identifier_widget_test.dart`.
void main() {
  const cardAnchor = 'firmware-card';
  const updateHook = 'firmware-card-update';
  const versionHook = 'firmware-card-version';

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
        home: const Scaffold(body: FirmwareUpdateCard()),
      ),
    );
  }

  group('FirmwareUpdateCard identifiers', () {
    testWidgets('the card anchor, CTA, and version are each locatable',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final matched = <Element>{};
      for (final id in <String>[cardAnchor, updateHook, versionHook]) {
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
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

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
  });
}
