import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/diagnostic_running_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

Future<void> _pump(WidgetTester tester, UnifiedDiagnosticsState state) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.create(
        brightness: Brightness.light,
        seedColor: Colors.blue,
        designThemeBuilder: (c) =>
            CustomDesignTheme.fromJson({'style': 'flat'}),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: DiagnosticRunningView(state: state)),
      ),
    ),
  ));
  await tester.pump();
}

ChannelCongestionCheckUIModel _congestion(
        int? utilization24, int? utilization5) =>
    ChannelCongestionCheckUIModel(radios: [
      ChannelCongestionRadioUIModel(
          band: '2.4GHz', channel: 1, utilization: utilization24),
      ChannelCongestionRadioUIModel(
          band: '5GHz', channel: 48, utilization: utilization5),
    ]);

void main() {
  group('WiFi coverage flow, channel congestion step (#1778)', () {
    testWidgets('names the step while it runs, not "Loading…"', (tester) async {
      await _pump(
        tester,
        const UnifiedDiagnosticsState(
          flow: DiagnosticFlow.wifiCoverage,
          step: DiagnosticStep.checkingChannelCongestion,
        ),
      );

      expect(find.text('Channel Congestion'), findsOneWidget);
      expect(find.text('Loading…'), findsNothing);
    });

    testWidgets('says how busy the busiest channel was once it is done',
        (tester) async {
      await _pump(
        tester,
        UnifiedDiagnosticsState(
          flow: DiagnosticFlow.wifiCoverage,
          step: DiagnosticStep.analyzing,
          // 71 of 255 is 28 %, the busier of the two.
          results: [_congestion(71, 8)],
        ),
      );

      expect(find.text('28% busy'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('says "Skipped" when no radio had a reading', (tester) async {
      await _pump(
        tester,
        UnifiedDiagnosticsState(
          flow: DiagnosticFlow.wifiCoverage,
          step: DiagnosticStep.analyzing,
          results: [_congestion(null, null)],
        ),
      );

      expect(find.text('Skipped'), findsOneWidget);
    });
  });
}
