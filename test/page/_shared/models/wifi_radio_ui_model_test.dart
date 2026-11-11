import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';

void main() {
  group('WifiRadioUIModel', () {
    test('creates with required parameters', () {
      final model = WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.1.',
        band: '2.4GHz',
        enable: true,
        transmitPower: 80,
        maxBitRate: 300,
        channel: 6,
        channelInUse: 6,
        autoChannelEnable: true,
        channelBandwidth: '20MHz',
        supportedStandards: 'ax',
      );

      expect(model.instancePath, 'Device.WiFi.Radio.1.');
      expect(model.band, '2.4GHz');
      expect(model.enable, true);
      expect(model.transmitPower, 80);
      expect(model.maxBitRate, 300);
      expect(model.channel, 6);
      expect(model.channelInUse, 6);
      expect(model.autoChannelEnable, true);
      expect(model.channelBandwidth, '20MHz');
      expect(model.supportedStandards, 'ax');
      expect(model.accessPoints, isEmpty);
    });

    test('possibleChannels defaults to empty list', () {
      final model = WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.1.',
        band: '2.4GHz',
        enable: true,
        transmitPower: 80,
        maxBitRate: 300,
        channel: 6,
        channelInUse: 6,
        autoChannelEnable: true,
        channelBandwidth: '20MHz',
        supportedStandards: 'ax',
      );

      expect(model.possibleChannels, isA<List<int>>());
      expect(model.possibleChannels, isEmpty);
    });

    test('possibleChannels is retained and included in equality', () {
      final model1 = _createRadio(possibleChannels: const [1, 6, 11]);
      final model2 = _createRadio(possibleChannels: const [1, 6, 11]);
      final model3 = _createRadio(possibleChannels: const [1, 6]);

      expect(model1.possibleChannels, [1, 6, 11]);
      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });

    // The radio can move without its configured channel changing (#1782), so
    // a model that differs only in the channel in use must not compare equal,
    // or a provider holding it would not rebuild the cards that print it.
    test('channelInUse is included in equality', () {
      expect(_createRadio(channel: 40, channelInUse: 36),
          isNot(equals(_createRadio(channel: 40, channelInUse: 40))));
    });

    // Utilization changes about once a minute with nothing else on the radio
    // changing (#1295), so it must count for equality: a re-read that brings
    // only a new reading must still rebuild the Channels tab.
    test('utilization is included in equality', () {
      expect(_createRadio(utilization: 46),
          isNot(equals(_createRadio(utilization: 58))));
    });

    group('utilizationPercent', () {
      // DataElements reports 0–255, where 255 is 100 %. The readings are the
      // bench's (FW 2.0.4.26103108, 2026-11-09): 46 on 2.4 GHz, 11 on 5 GHz.
      test('converts the 0–255 reading to a whole percent', () {
        expect(_createRadio(utilization: 46).utilizationPercent, 18);
        expect(_createRadio(utilization: 11).utilizationPercent, 4);
        expect(_createRadio(utilization: 255).utilizationPercent, 100);
        expect(_createRadio(utilization: 0).utilizationPercent, 0);
      });

      test('an unknown utilization is null, never 0', () {
        expect(_createRadio(utilization: null).utilizationPercent, isNull);
      });
    });

    test('accessPoints defaults to empty list', () {
      final model = WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.1.',
        band: '5GHz',
        enable: true,
        transmitPower: 100,
        maxBitRate: 1200,
        channel: 36,
        channelInUse: 36,
        autoChannelEnable: false,
        channelBandwidth: '80MHz',
        supportedStandards: 'ax',
      );

      expect(model.accessPoints, isA<List<WifiAccessPointUIModel>>());
      expect(model.accessPoints, isEmpty);
    });

    group('txPowerPercent', () {
      test('returns 100 when transmitPower is -1 (max)', () {
        final model = _createRadio(transmitPower: -1);
        expect(model.txPowerPercent, 100);
      });

      test('returns clamped value for normal power', () {
        expect(_createRadio(transmitPower: 80).txPowerPercent, 80);
        expect(_createRadio(transmitPower: 0).txPowerPercent, 0);
        expect(_createRadio(transmitPower: 100).txPowerPercent, 100);
      });

      test('clamps values outside 0-100 range', () {
        expect(_createRadio(transmitPower: 150).txPowerPercent, 100);
        expect(_createRadio(transmitPower: -50).txPowerPercent, 0);
      });
    });

    group('txPowerDisplay', () {
      test('returns "Max" when transmitPower is -1', () {
        final model = _createRadio(transmitPower: -1);
        expect(model.txPowerDisplay, 'Max');
      });

      test('returns percentage string for normal power', () {
        expect(_createRadio(transmitPower: 80).txPowerDisplay, '80%');
        expect(_createRadio(transmitPower: 50).txPowerDisplay, '50%');
        expect(_createRadio(transmitPower: 100).txPowerDisplay, '100%');
      });
    });

    group('channelInUseDisplay', () {
      test('includes "(Auto)" when autoChannelEnable is true', () {
        final model =
            _createRadio(channel: 6, channelInUse: 6, autoChannelEnable: true);
        expect(model.channelInUseDisplay, '6 (Auto)');
      });

      test('shows only channel number when autoChannelEnable is false', () {
        final model = _createRadio(
            channel: 36, channelInUse: 36, autoChannelEnable: false);
        expect(model.channelInUseDisplay, '36');
      });

      // #1782: set to 40, hostapd's 20/40 MHz coexistence check moved the
      // radio to 36 (bench 2.0.4.26103108, #1295). The radio is on 36.
      test('shows the channel the radio is on, not the configured one', () {
        final model = _createRadio(
            channel: 40, channelInUse: 36, autoChannelEnable: false);
        expect(model.channelInUseDisplay, '36');
      });

      test('an unknown channel in use shows "--", never 0 or the configured',
          () {
        expect(
            _createRadio(
                    channel: 40, channelInUse: null, autoChannelEnable: false)
                .channelInUseDisplay,
            '--');
        expect(
            _createRadio(
                    channel: 40, channelInUse: null, autoChannelEnable: true)
                .channelInUseDisplay,
            '-- (Auto)');
      });
    });

    group('bitRateNormalized', () {
      test('normalizes 2.4GHz band against 600 Mbps max', () {
        final model = _createRadio(band: '2.4GHz', maxBitRate: 300);
        expect(model.bitRateNormalized, 50.0);
      });

      test('normalizes 5GHz band against 4800 Mbps max', () {
        final model = _createRadio(band: '5GHz', maxBitRate: 2400);
        expect(model.bitRateNormalized, 50.0);
      });

      test('normalizes 6GHz band against 9600 Mbps max', () {
        final model = _createRadio(band: '6GHz', maxBitRate: 4800);
        expect(model.bitRateNormalized, 50.0);
      });

      test('clamps result to 0-100 range', () {
        final overMax = _createRadio(band: '2.4GHz', maxBitRate: 1200);
        expect(overMax.bitRateNormalized, 100.0);

        final zero = _createRadio(band: '5GHz', maxBitRate: 0);
        expect(zero.bitRateNormalized, 0.0);
      });
    });

    test('equality based on all properties', () {
      final model1 = _createRadio();
      final model2 = _createRadio();
      final model3 = _createRadio(band: '5GHz');

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });

  group('WifiAccessPointUIModel', () {
    test('creates with required parameters', () {
      final ap = WifiAccessPointUIModel(
        enable: true,
        ssidName: 'MyNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      );

      expect(ap.enable, true);
      expect(ap.ssidName, 'MyNetwork');
      expect(ap.securityMode, 'WPA3-Personal');
      expect(ap.encryptionMode, 'AES');
      expect(ap.isGuest, false);
    });

    test('isGuest defaults to false', () {
      final ap = WifiAccessPointUIModel(
        enable: true,
        ssidName: 'Test',
        securityMode: 'WPA2',
        encryptionMode: 'AES',
      );
      expect(ap.isGuest, false);
    });

    test('can set isGuest to true', () {
      final ap = WifiAccessPointUIModel(
        enable: true,
        ssidName: 'Guest Network',
        securityMode: 'WPA2',
        encryptionMode: 'AES',
        isGuest: true,
      );
      expect(ap.isGuest, true);
    });

    test('equality based on all properties', () {
      final ap1 = WifiAccessPointUIModel(
        enable: true,
        ssidName: 'Test',
        securityMode: 'WPA3',
        encryptionMode: 'AES',
      );
      final ap2 = WifiAccessPointUIModel(
        enable: true,
        ssidName: 'Test',
        securityMode: 'WPA3',
        encryptionMode: 'AES',
      );
      final ap3 = WifiAccessPointUIModel(
        enable: false,
        ssidName: 'Test',
        securityMode: 'WPA3',
        encryptionMode: 'AES',
      );

      expect(ap1, equals(ap2));
      expect(ap1, isNot(equals(ap3)));
    });
  });
}

WifiRadioUIModel _createRadio({
  String instancePath = 'Device.WiFi.Radio.1.',
  String band = '2.4GHz',
  bool enable = true,
  int transmitPower = 80,
  int maxBitRate = 300,
  int channel = 6,
  int? channelInUse = 6,
  bool autoChannelEnable = true,
  String channelBandwidth = '20MHz',
  String supportedStandards = 'ax',
  int? utilization,
  List<int> possibleChannels = const [],
  List<WifiAccessPointUIModel> accessPoints = const [],
}) {
  return WifiRadioUIModel(
    instancePath: instancePath,
    band: band,
    enable: enable,
    transmitPower: transmitPower,
    maxBitRate: maxBitRate,
    channel: channel,
    channelInUse: channelInUse,
    autoChannelEnable: autoChannelEnable,
    channelBandwidth: channelBandwidth,
    supportedStandards: supportedStandards,
    utilization: utilization,
    possibleChannels: possibleChannels,
    accessPoints: accessPoints,
  );
}
