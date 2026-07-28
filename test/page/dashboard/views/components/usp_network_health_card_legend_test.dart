@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_network_health_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// White-box widget tests for the [UspNetworkHealthCard] chart legends (#1145).
///
/// Regression coverage for the Errors and Loss tabs: each legend entry must be
/// prefixed with its series name (Errors / Discards / Loss), so the two "Avg"
/// values are distinguishable — consistent with the labeled charts elsewhere
/// (System Status card labels CPU / Memory next to each legend dot).
void main() {
  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: cardOverrides(trafficAnalysisState: testTrafficWithHistory),
        child: MaterialApp(
          theme: _testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: UspNetworkHealthCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations locOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(UspNetworkHealthCard)))!;

  /// Finds a Text/AppText whose rendered data contains [substring].
  Finder textContaining(String substring) => find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains(substring) ?? false),
      );

  testWidgets('Errors tab legend labels both series (Errors + Discards)',
      (tester) async {
    await pumpCard(tester);
    final l = locOf(tester);

    // Switch to the Errors tab.
    await tester.tap(find.text(l.errors).first);
    await tester.pumpAndSettle();

    // Errors series: "Errors  Avg: ...  Peak: ..." (single string, prefixed).
    expect(
      textContaining('${l.errors}  '),
      findsOneWidget,
      reason: 'Errors legend entry must be prefixed with its series name',
    );
    // Discards series: "Discards  Avg: ..." (single string, prefixed).
    expect(
      textContaining('${l.discards}  '),
      findsOneWidget,
      reason: 'Discards legend entry must be prefixed with its series name',
    );
  });

  testWidgets('Loss tab legend labels the series (Loss)', (tester) async {
    await pumpCard(tester);
    final l = locOf(tester);

    // Switch to the Loss tab.
    await tester.tap(find.text(l.loss).first);
    await tester.pumpAndSettle();

    expect(
      textContaining('${l.loss}  '),
      findsOneWidget,
      reason: 'Loss legend entry must be prefixed with its series name',
    );
  });

  testWidgets(
      'Errors tab Discards legend renders the formatted non-zero avg value',
      (tester) async {
    // Base fixture leaves discards at 0; this variant supplies a constant
    // 3.0/s WAN discard rate so the formatted value path is exercised.
    await tester.pumpWidget(
      ProviderScope(
        overrides: cardOverrides(trafficAnalysisState: testTrafficWithDiscards),
        child: MaterialApp(
          theme: _testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: UspNetworkHealthCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l = locOf(tester);

    // Switch to the Errors tab.
    await tester.tap(find.text(l.errors).first);
    await tester.pumpAndSettle();

    // Discards series carries a real, formatted rate — not the default 0.
    // avg = (1.5 + 1.5)/s constant across snapshots => formatFaultRate => "3.0/s".
    expect(
      textContaining(l.seriesAvgValue(l.discards, '3.0/s')),
      findsOneWidget,
      reason: 'Discards legend must render the formatted non-zero avg value',
    );
  });
}
