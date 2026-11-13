@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_scroll_region.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/locale_tag.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/card_data_profiles.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/dashboard/text_readability_probe.dart';

/// The Firewall card's rows read in every locale, at the narrowest width of each
/// form (#1130).
///
/// The gate only asks whether a `RenderFlex` overflowed, and this card's first
/// draft passed it while unreadable: at 288px, one line per row lost the second
/// half of "IPv4 and IPv6 off" and broke a MAC address mid-token, with no overflow
/// reported. So each form is held to the two readability verdicts — no text
/// ellipsized, no break inside a word — at its floor, which by monotonicity
/// covers every width above it up to the next form:
///
/// * **normal** from the spec's `normalAbove`, 272px. That number is this test's
///   to defend: it is the narrowest width at which the DMZ host by MAC, the widest
///   unbreakable string the card prints, stays whole.
/// * **compact** from [kPopupBelow], 200px, where the compact form gives up the
///   flag column and `(i)`. Near that floor a label or a MAC host still does not
///   fit, so there the one verdict is relaxed, and only there: text may be cut
///   with an ellipsis if it is an [AppOverflowText], whose tooltip shows the whole
///   string. A break inside a word is damage in both forms.
///
/// Below 200px the card is its popup form, which the popup sweep measures.
///
/// Each profile is a state of the router: the default fixture (some rules on),
/// everything open (the longest values, and flags), and a new router (the
/// sentence that replaces a value).
void main() {
  setUpAll(() async => loadAppFonts());

  const cardId = 'firewall_overview';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);

  final profiles = <String, List<Override> Function()>{
    'default': () => const [],
    firewallAllOpenProfile.key: firewallAllOpenProfile.overrides,
    firewallNewRouterProfile.key: firewallNewRouterProfile.overrides,
  };

  final forms = <(CardDensity, double)>[
    (CardDensity.normal, spec.normalAbove!),
    (CardDensity.compact, kPopupBelow),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required double cardWidth,
    required Locale locale,
    required List<Override> overrides,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: CardWidthCase(
          screenWidth: 1440,
          cardWidth: cardWidth,
          columnSpan: spec.getConstraints(DisplayMode.normal).preferredColumns,
          label: 'floor',
        ),
        cardHeightRows: spec.getConstraints(DisplayMode.normal).minHeightRows,
        tabIndex: 0,
        locale: locale,
        extraOverrides: overrides,
      );

  for (final MapEntry(key: profile, value: overrides) in profiles.entries) {
    for (final (form, width) in forms) {
      testWidgets(
          '$profile, ${form.name} form at its ${width.toStringAsFixed(0)}px '
          'floor: every row reads in every locale', (tester) async {
        final damage = <String>[];
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await pump(tester,
              cardWidth: width, locale: locale, overrides: overrides());

          // The premise: the width selected the form this case is about.
          // `(i)` is the normal form's and only the normal form's, and every
          // profile here has UPnP on, so the normal form always shows one.
          expect(find.byIcon(Icons.info_outline),
              form == CardDensity.normal ? findsWidgets : findsNothing,
              reason: '$tag at ${width}px did not render the ${form.name} '
                  'form, so this case would be measuring the other one');

          // The card's content: its rows and the new-router sentence, but not
          // the template's title and footer, which ellipsize by design.
          final texts = find.descendant(
            of: find.byType(CardScrollRegion),
            matching: find.byType(RichText),
          );
          expect(texts, findsWidgets);
          for (final element in texts.evaluate()) {
            final text = find.byWidget(element.widget);
            final plain = tester.paragraphOf(text).text.toPlainText();
            final box = tester.paragraphOf(text).size.width;
            // Cut, with the whole text a hover or long-press away: the compact
            // form's trade, and the only clipping either form may do.
            final revealed = form == CardDensity.compact &&
                find
                    .ancestor(of: text, matching: find.byType(AppOverflowText))
                    .evaluate()
                    .isNotEmpty;
            if (tester.isTextClipped(text)) {
              if (!revealed) {
                damage.add('$tag: "$plain" ellipsized in ${box}px');
              }
              continue;
            }
            if (!kLocalesWithoutWordSpaces.contains(tag) &&
                tester.hasSplitToken(text)) {
              damage.add('$tag: "$plain" broken mid-word — granted '
                  '${box.toStringAsFixed(1)}px, widest token '
                  '${tester.widestTokenWidth(text).toStringAsFixed(1)}px');
            }
          }
        }
        expect(damage, isEmpty, reason: damage.join('\n'));
      });
    }
  }

  // 6×3 is the card's size because three rows hold its tallest state (#1130).
  // Held at the width most users see it at — six columns on a 1440px screen —
  // since at the narrowest six-column realization (288px) the DMZ host wraps and
  // the card scrolls a little, which the full form accepts.
  testWidgets('the tallest state fits three rows at the desktop width',
      (tester) async {
    final scrolls = <String>[];
    final desktop = cardWidthAt(1440, 6);
    for (final locale in AppLocalizations.supportedLocales) {
      await pump(tester,
          cardWidth: desktop,
          locale: locale,
          overrides: firewallAllOpenProfile.overrides());
      final shortfall = cardContentScrollShortfall(tester);
      expect(shortfall, isNotNull, reason: 'the card has no scroll region');
      if (shortfall! > 0) {
        scrolls.add('${localeTag(locale)}: scrolls ${shortfall}px');
      }
    }
    expect(scrolls, isEmpty, reason: scrolls.join('\n'));
  });
}
