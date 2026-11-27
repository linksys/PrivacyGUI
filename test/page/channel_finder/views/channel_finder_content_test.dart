import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_content.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/scenes/channel_finder_scene_data.dart';

/// The page body at phone width, so one band shows at a time and the band
/// names appear only on the band picker.
Future<void> _pump(WidgetTester tester, ChannelFinderState state) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => Scaffold(
        body: SingleChildScrollView(
          child: ChannelFinderContent(state: state, onScan: () {}),
        ),
      ),
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    theme: AppTheme.create(
      brightness: Brightness.light,
      seedColor: Colors.blue,
      designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.pumpAndSettle();
}

Finder _row(String key) => find.byWidgetPredicate(
    (w) => w is LayoutBlock && w.identifier == 'channel-finder-channel-$key');

ChannelFinderState _withBand(ChannelBandMeasurement measurement) =>
    ChannelFinderState(
      phase: ChannelFinderPhase.done,
      lastResult: ChannelFinderResultUIModel(
        scannedAt: DateTime(2026, 11, 26, 14, 13),
        bands: [
          ChannelBandScanUIModel(
            band: '5GHz',
            channelInUse: 48,
            measurement: measurement,
            channels: const [
              ChannelScanUIModel(
                  channel: 48, utilization: null, isInUse: true, neighbors: []),
            ],
          ),
        ],
      ),
    );

void main() {
  group('ChannelFinderContent (#1778)', () {
    testWidgets('the band picker switches which band\'s channels are listed',
        (tester) async {
      await _pump(tester, channelFinderDoneState);

      expect(_row('2-4ghz-11'), findsOneWidget);
      expect(_row('5ghz-149'), findsNothing);

      await tester.tap(find.text('5GHz'));
      await tester.pumpAndSettle();

      expect(_row('5ghz-149'), findsOneWidget);
      expect(_row('2-4ghz-11'), findsNothing);
    });

    testWidgets(
        'tapping a channel lists its networks in the scan\'s order, a hidden '
        'one by name, and Close closes the list', (tester) async {
      await _pump(tester, channelFinderDoneState);

      await tester.tap(_row('2-4ghz-11'));
      await tester.pumpAndSettle();

      expect(find.text('Networks on channel 11'), findsOneWidget);
      // -52, -71 (no SSID) and -80 dBm in the fixture. The service sorts
      // them strongest first; the list keeps that order.
      final cafe = tester.getTopLeft(find.text('Cafe')).dy;
      final hidden = tester.getTopLeft(find.text('Hidden network')).dy;
      final office = tester.getTopLeft(find.text('Office')).dy;
      expect(cafe, lessThan(hidden));
      expect(hidden, lessThan(office));

      await tester.tap(find.byWidgetPredicate((w) =>
          w is AppButton && w.identifier == 'channel-finder-networks-close'));
      await tester.pumpAndSettle();

      expect(find.text('Networks on channel 11'), findsNothing);
    });

    testWidgets('a channel with no network says so', (tester) async {
      await _pump(tester, channelFinderDoneState);

      await tester.tap(_row('2-4ghz-1'));
      await tester.pumpAndSettle();

      expect(find.text('Networks on channel 1'), findsOneWidget);
      expect(find.text('The router heard no networks on this channel.'),
          findsOneWidget);
    });

    testWidgets('a band the router did not measure says so', (tester) async {
      await _pump(tester, _withBand(ChannelBandMeasurement.refused));

      expect(
          find.text(
              "The router did not measure how busy this band's channels are."),
          findsOneWidget);
    });

    testWidgets('a band whose measurement did not finish says to scan again',
        (tester) async {
      await _pump(tester, _withBand(ChannelBandMeasurement.unanswered));

      expect(
          find.text("Measuring how busy this band's channels are did not "
              'finish. Scan again to try once more.'),
          findsOneWidget);
    });

    testWidgets('a measured band has no such note', (tester) async {
      await _pump(tester, _withBand(ChannelBandMeasurement.measured));

      expect(find.textContaining('did not measure'), findsNothing);
      expect(find.textContaining('did not finish'), findsNothing);
    });
  });
}
