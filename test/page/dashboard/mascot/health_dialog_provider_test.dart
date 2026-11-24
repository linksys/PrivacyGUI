import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_score.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/system_health_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/health_dialog_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/firewall_test_data.dart';
import '../../../mocks/test_data/system_health_test_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/arb_keys_read.dart';

/// Every health item scored, with Security the one that needs attention, so the
/// opening dialog shows a problem row as well as the healthy chips.
class _FixedHealth extends SystemHealthNotifier {
  @override
  Future<SystemHealthState> build() async => SystemHealthState(
        scores: {
          for (final type in HealthDimensionType.values)
            type: HealthScore(
              dimension: type,
              score: type == HealthDimensionType.security ? 50 : 100,
              evaluatedAt: DateTime(2026, 11, 12),
            ),
        },
      );
}

/// #1312: the mascot's opening dialog and a health item show no English, in
/// every locale, and fit the speech bubble.
///
/// 220px is `MascotSpeechBubble`'s default `maxWidth`, which `MascotOverlay`
/// uses. Real fonts, so a RenderFlex overflow in a long translation fails the
/// test (the layout gate renders no mascot surface).
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
  final mascotKeys = arbKeysReadBy(['lib/page/dashboard/mascot']);

  /// The ARB file for [locale]; `es_AR` lives in `app_es_ar.arb`.
  Map arbOf(Locale locale) => jsonDecode(Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .singleWhere((f) =>
          f.uri.pathSegments.last.toLowerCase() ==
          'app_${locale.toString().toLowerCase()}.arb')
      .readAsStringSync()) as Map;

  /// The English of every key the mascot reads, as patterns, leaving out what
  /// is not evidence of untranslated text:
  ///
  /// - a single word [locale] spells the same: `Firmware`, `System`, `FAQ`,
  ///   `CPU` are those languages' own words too;
  /// - a loanword in [locale], in any case: English its ARB already writes in
  ///   strings the mascot does not read. Greek has a word for firewall but
  ///   writes "Firewall SPI IPv4" elsewhere, so "Firewall IPv4" is Greek;
  /// - a value with a placeholder, which is never rendered as-is.
  ///
  /// A phrase identical to English is not exempt: an English string pasted
  /// into a locale's ARB is identical too, and that is what this guards
  /// (checked: "DMZ Active" pasted into `app_ja.arb` fails).
  List<RegExp> englishFor(Locale locale) {
    final translated = arbOf(locale);
    final elsewhere = [
      for (final MapEntry(:key, :value) in translated.entries)
        if (value is String && !mascotKeys.contains(key)) value,
    ];
    RegExp word(String text, {bool caseSensitive = true}) =>
        RegExp('(?<![A-Za-z])${RegExp.escape(text)}(?![A-Za-z])',
            caseSensitive: caseSensitive);
    bool isCognate(String key, String english) =>
        translated[key] == english && !english.contains(RegExp(r'\s'));
    bool isLoanword(String english) =>
        elsewhere.any(word(english, caseSensitive: false).hasMatch);
    return [
      for (final key in mascotKeys)
        if (en[key] case final String english
            when !english.contains('{') &&
                !isCognate(key, english) &&
                !isLoanword(english))
          word(english),
    ];
  }

  List<String> englishIn(List<RegExp> english, Iterable<String> texts) => [
        for (final text in texts)
          for (final word in english)
            if (word.hasMatch(text)) '"${word.pattern}" in "$text"',
      ];

  Iterable<String> shownText(WidgetTester tester) => [
        for (final t in tester.widgetList<Text>(find.byType(Text)))
          t.data ?? t.textSpan?.toPlainText() ?? '',
        for (final t in tester.widgetList<Tooltip>(find.byType(Tooltip)))
          t.message ?? '',
      ];

  for (final locale in AppLocalizations.supportedLocales
      .where((l) => l.languageCode != 'en')) {
    testWidgets('the opening dialog and a health item, in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final l10n = lookupAppLocalizations(locale);
      final english = englishFor(locale);
      final controller = MascotController();
      addTearDown(controller.dispose);
      late HealthDialogProvider dialogs;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthEvaluationContextProvider.overrideWithValue(
            SystemHealthTestData.createContext(
              wan: SystemHealthTestData.createWanData(),
              firewall: FirewallTestData.createFirewallData(
                dmzModel: FirewallTestData.createEnabledDmzUIModel(),
              ),
            ),
          ),
          systemHealthProvider.overrideWith(_FixedHealth.new),
        ],
        child: MaterialApp(
          // Flat: the default style animates its borders, so nothing settles.
          theme: AppTheme.create(
            brightness: Brightness.light,
            seedColor: Colors.blue,
            designThemeBuilder: (c) =>
                CustomDesignTheme.fromJson({'style': 'flat'}),
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(builder: (context, ref, _) {
              dialogs = HealthDialogProvider(
                ref: ref,
                controller: controller,
                onPrintReport: () async {},
                onOpenThemeStudio: () {},
                onOpenAiAssistant: () {},
                onNavigate: (_) {},
                getLocale: () => locale,
                getFaqCategoryTitle: (category) =>
                    category.displayString(context),
                getFaqItemTitle: (item) => item.displayString(context),
                isThemeStudioEnabled: false,
                // Morning, so the greeting comes from the morning set.
                getRouterTime: () => DateTime(2026, 11, 12, 9),
                l10n: l10n,
              );
              return Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) =>
                        controller.currentDialog?.contentBuilder
                            ?.call(context, Colors.black) ??
                        const SizedBox.shrink(),
                  ),
                ),
              );
            }),
          ),
        ),
      ));

      controller.showDialog(await dialogs.getInitialDialog());
      await tester.pump();
      await tester.pump();

      final opening = controller.currentDialog!;
      expect(
        [
          l10n.mascotGreetingMorning1,
          l10n.mascotGreetingMorning2,
          l10n.mascotGreetingMorning3,
          l10n.mascotGreetingMorning4,
        ],
        contains(opening.text),
        reason: 'the greeting a screen reader announces',
      );
      expect(find.text(l10n.mascotSecurityDmzActive), findsOneWidget,
          reason: 'the premise: Security is a problem row, with its status');
      expect(englishIn(english, [opening.text, ...shownText(tester)]), isEmpty);

      await tester.tap(find.text(l10n.security));
      await tester.pump();
      await tester.pump();

      final item = controller.currentDialog!;
      expect(item.text, l10n.security);
      expect(find.text(l10n.ipv4Firewall), findsOneWidget,
          reason: 'the premise: the Security item lists its rows');
      expect(englishIn(english, [item.text, ...shownText(tester)]), isEmpty);
    });
  }
}
