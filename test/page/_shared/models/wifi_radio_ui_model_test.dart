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

    test('accessPoints defaults to empty list', () {
      final model = WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.1.',
        band: '5GHz',
        enable: true,
        transmitPower: 100,
        maxBitRate: 1200,
        channel: 36,
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

    group('channelDisplay', () {
      test('includes "(Auto)" when autoChannelEnable is true', () {
        final model = _createRadio(channel: 6, autoChannelEnable: true);
        expect(model.channelDisplay, '6 (Auto)');
      });

      test('shows only channel number when autoChannelEnable is false', () {
        final model = _createRadio(channel: 36, autoChannelEnable: false);
        expect(model.channelDisplay, '36');
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
  bool autoChannelEnable = true,
  String channelBandwidth = '20MHz',
  String supportedStandards = 'ax',
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
    autoChannelEnable: autoChannelEnable,
    channelBandwidth: channelBandwidth,
    supportedStandards: supportedStandards,
    possibleChannels: possibleChannels,
    accessPoints: accessPoints,
  );
}
