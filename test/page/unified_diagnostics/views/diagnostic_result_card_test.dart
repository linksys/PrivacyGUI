import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/diagnostic_result_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

Future<void> _pump(WidgetTester tester, DiagnosticStepUIModel result,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    theme: AppTheme.create(
      brightness: Brightness.light,
      seedColor: Colors.blue,
      designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: DiagnosticResultCard(result: result)),
  ));
  await tester.pumpAndSettle();
}

WifiSignalCheckUIModel _wifi(int clients) => WifiSignalCheckUIModel(
      rssi: -48,
      channel: 36,
      channelInUse: 48,
      band: '5GHz',
      connectedDevices: clients,
      severity: DiagnosticSeverity.ok,
      titleKey: 'diagnostics_wifi_signal',
      descriptionKey: 'diagnostics_wifi_signal_desc',
    );

ChannelCongestionCheckUIModel get _congestion =>
    ChannelCongestionCheckUIModel(radios: const [
      ChannelCongestionRadioUIModel(
          band: '2.4GHz', channel: 1, utilization: 71),
    ]);

void main() {
  group('DiagnosticResultCard reads its text from the ARB files (#1778)', () {
    testWidgets('counts clients in the singular and the plural',
        (tester) async {
      await _pump(tester, _wifi(1));
      expect(find.text('1 client on 5GHz'), findsOneWidget);

      await _pump(tester, _wifi(3));
      expect(find.text('3 clients on 5GHz'), findsOneWidget);
    });

    testWidgets('shows the title, status and summary in the app\'s language',
        (tester) async {
      const zhTw = Locale('zh', 'TW');
      final l = lookupAppLocalizations(zhTw);
      await _pump(tester, _congestion, locale: zhTw);

      expect(find.text(l.diagnosticsChannelCongestion), findsOneWidget);
      expect(find.text(l.diagnosticsStatusOk), findsOneWidget);
      expect(
          find.text(l.diagnosticsBusiestChannel(1, '2.4GHz')), findsOneWidget);
      // None of the English it used to write.
      expect(find.text('Channel Congestion'), findsNothing);
      expect(find.text('Busiest: channel 1 on 2.4GHz'), findsNothing);
    });
  });
}
