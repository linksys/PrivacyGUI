import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/wifi_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

void main() {
  group('WifiHealthDimension', () {
    late WifiHealthDimension dimension;

    setUp(() {
      dimension = WifiHealthDimension();
    });

    WifiRadioUIModel createRadio({
      required String band,
      required bool enable,
    }) {
      return WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.1',
        band: band,
        enable: enable,
        transmitPower: 100,
        maxBitRate: 1200,
        channel: 6,
        autoChannelEnable: true,
        channelBandwidth: '20MHz',
        supportedStandards: '802.11ax',
      );
    }

    group('evaluate', () {
      test('returns 100 when wifi data is null', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when all radios are enabled', () {
        final context = HealthEvaluationContext(
          wifi: WifiData(
            codegenContext: WifiCodegenContext.empty,
            radioModels: [
              createRadio(band: '2.4GHz', enable: true),
              createRadio(band: '5GHz', enable: true),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 70 when some radios are disabled', () {
        final context = HealthEvaluationContext(
          wifi: WifiData(
            codegenContext: WifiCodegenContext.empty,
            radioModels: [
              createRadio(band: '2.4GHz', enable: true),
              createRadio(band: '5GHz', enable: false),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 70);
      });

      test('returns 30 when all radios are disabled', () {
        final context = HealthEvaluationContext(
          wifi: WifiData(
            codegenContext: WifiCodegenContext.empty,
            radioModels: [
              createRadio(band: '2.4GHz', enable: false),
              createRadio(band: '5GHz', enable: false),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 30);
      });
    });

    group('getSummary', () {
      test('returns All Active when all radios enabled', () {
        final context = HealthEvaluationContext(
          wifi: WifiData(
            codegenContext: WifiCodegenContext.empty,
            radioModels: [
              createRadio(band: '2.4GHz', enable: true),
              createRadio(band: '5GHz', enable: true),
            ],
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'All Active');
        expect(summary.items.any((i) => i.label == 'Radios'), true);
      });

      test('returns All Disabled when no radios enabled', () {
        final context = HealthEvaluationContext(
          wifi: WifiData(
            codegenContext: WifiCodegenContext.empty,
            radioModels: [
              createRadio(band: '2.4GHz', enable: false),
            ],
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'All Disabled');
      });
    });

    group('watchedDomains', () {
      test('watches wifi-related domains', () {
        expect(
            dimension.watchedDomains, contains(InvalidationDomain.wifiRadios));
        expect(
            dimension.watchedDomains, contains(InvalidationDomain.wifiSsids));
      });
    });

    group('getActions', () {
      testWidgets('returns wifi settings action', (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.any((a) => a.id == 'wifi_settings'), true);
      });
    });
  });
}
