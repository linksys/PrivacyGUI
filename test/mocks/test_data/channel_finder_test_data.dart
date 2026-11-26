import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';

/// Raw Get rows and operate results for `ChannelFinderService` tests, and
/// UI models for provider and view tests (constitution Article I §1.6.2).
///
/// Shaped after the M60 bench on FW `2.0.4.26112521` (#1778, 2026-11-26): the
/// Wi-Fi radios are numbered 2.4 GHz first, the controller's DataElements
/// radios 5 GHz first, and they are joined through a shared BSSID.
class ChannelFinderTestData {
  static const controllerId = '74:12:13:21:55:02';
  static const bssid24 = '74:12:13:21:55:03';
  static const bssid5 = '74:12:13:21:55:04';

  /// The controller's DataElements radio for each band, as on the bench.
  static const dataElements5 =
      'Device.WiFi.DataElements.Network.Device.1.Radio.1.';
  static const dataElements24 =
      'Device.WiFi.DataElements.Network.Device.1.Radio.2.';

  /// `Device.WiFi.Radio.{1,2}.` rows: 2.4 GHz on channel 1 (channels 1–11),
  /// 5 GHz on 48 (36–48, 52 and 149, 52 being DFS).
  static Map<String, dynamic> radiosRows({
    bool dfsEnabled = false,
    bool radio24Enabled = true,
    String channelsInUse5 = '48',
  }) =>
      {
        ..._radio(1,
            band: '2.4GHz',
            channel: 1,
            channelsInUse: '1',
            possibleChannels: '1-11',
            enable: radio24Enabled,
            dfsEnabled: false),
        ..._radio(2,
            band: '5GHz',
            channel: 44,
            channelsInUse: channelsInUse5,
            possibleChannels: '36,40,44,48,52,149',
            enable: true,
            dfsEnabled: dfsEnabled),
      };

  static Map<String, dynamic> _radio(
    int i, {
    required String band,
    required int channel,
    required String channelsInUse,
    required String possibleChannels,
    required bool enable,
    required bool dfsEnabled,
  }) {
    final p = 'Device.WiFi.Radio.$i.';
    return {
      '${p}Enable': enable,
      '${p}Status': enable ? 'Up' : 'Down',
      '${p}Channel': channel,
      '${p}ChannelsInUse': channelsInUse,
      '${p}OperatingFrequencyBand': band,
      '${p}OperatingChannelBandwidth': band == '2.4GHz' ? '20MHz' : '80MHz',
      '${p}PossibleChannels': possibleChannels,
      '${p}OperatingStandards': 'ax',
      '${p}SupportedStandards': 'ax',
      '${p}TransmitPower': 100,
      '${p}MaxBitRate': 1200,
      '${p}AutoChannelEnable': band == '2.4GHz',
      '${p}IEEE80211hEnabled': dfsEnabled,
      '${p}SupportedOperatingChannelBandwidths': 'Auto,20MHz,40MHz,80MHz',
    };
  }

  /// `Device.WiFi.SSID.{1,2}.`: the main network on each radio.
  static Map<String, dynamic> ssidsRows() => {
        ..._ssid(1, bssid: bssid24, radio: 1),
        ..._ssid(2, bssid: bssid5, radio: 2),
      };

  static Map<String, dynamic> _ssid(int i,
      {required String bssid, required int radio}) {
    final p = 'Device.WiFi.SSID.$i.';
    return {
      '${p}SSID': 'Home',
      '${p}Enable': true,
      '${p}Status': 'Up',
      '${p}BSSID': bssid,
      '${p}LowerLayers': 'Device.WiFi.Radio.$radio.',
      '${p}Alias': 'ssid-$i',
      '${p}MACAddress': bssid,
    };
  }

  /// `DataElementsNetwork` rows: the controller, with its 5 GHz radio as
  /// `Radio.1` and its 2.4 GHz radio as `Radio.2`. [bssid24OnDataElements]
  /// stands in for a radio whose BSS the SSID table does not know.
  static Map<String, dynamic> dataElementsRows(
      {String bssid24OnDataElements = bssid24}) {
    const node = 'Device.WiFi.DataElements.Network.Device.1.';
    return {
      '${node}ID': controllerId,
      '${dataElements5}ID': bssid5,
      '${dataElements5}BSS.1.BSSID': bssid5,
      '${dataElements5}BSS.1.SSID': 'Home',
      '${dataElements24}ID': '72:12:13:21:55:03',
      '${dataElements24}BSS.1.BSSID': bssid24OnDataElements,
      '${dataElements24}BSS.1.SSID': 'Home',
    };
  }

  /// `DataElementsNetworkInfo` rows.
  static Map<String, dynamic> networkInfoRows({String id = controllerId}) =>
      {'Device.WiFi.DataElements.Network.ControllerID': id};

  /// One `ScanResult.{instance}` under [radioPath], with one `ChannelScan` row
  /// per entry of [utilization] (channel → value).
  static Map<String, dynamic> scanResultRows({
    required String radioPath,
    required int instance,
    required String timeStamp,
    required Map<int, int> utilization,
  }) {
    final scan = '${radioPath}ScanResult.$instance.';
    var row = 0;
    return {
      'Device.WiFi.DataElements.Network.Device.1.ID': controllerId,
      '${radioPath}ID':
          radioPath == dataElements5 ? bssid5 : '72:12:13:21:55:03',
      '${scan}TimeStamp': timeStamp,
      '${scan}OpClassScan.1.OperatingClass': '115',
      for (final entry in utilization.entries) ...{
        '${scan}OpClassScan.1.ChannelScan.${++row}.Channel': '${entry.key}',
        '${scan}OpClassScan.1.ChannelScan.$row.Utilization': '${entry.value}',
        '${scan}OpClassScan.1.ChannelScan.$row.Noise': '28',
      },
    };
  }

  /// One network as `NeighboringWiFiDiagnostic()` reports it.
  static ({String radio, int channel, String ssid, String bssid, int signal})
      neighbor({
    String radio = 'Device.WiFi.Radio.2',
    required int channel,
    String ssid = 'Neighbour',
    String bssid = 'aa:bb:cc:00:00:01',
    required int signal,
  }) =>
          (
            radio: radio,
            channel: channel,
            ssid: ssid,
            bssid: bssid,
            signal: signal,
          );

  /// The OperationComplete of `NeighboringWiFiDiagnostic()` carrying
  /// [neighbors] as `Result.{i}.*`, numbered from 1.
  static OperateResult neighborScanResult(
    List<({String radio, int channel, String ssid, String bssid, int signal})>
        neighbors, {
    String status = 'Complete',
  }) {
    final args = <String, String>{'Status': status};
    for (var i = 0; i < neighbors.length; i++) {
      final n = neighbors[i];
      final p = 'Result.${i + 1}.';
      args['${p}Radio'] = n.radio;
      args['${p}SSID'] = n.ssid;
      args['${p}BSSID'] = n.bssid;
      args['${p}Channel'] = '${n.channel}';
      args['${p}SignalStrength'] = '${n.signal}';
      args['${p}OperatingFrequencyBand'] =
          n.radio.endsWith('.1') ? '2.4GHz' : '5GHz';
    }
    return OperateResult(
      commandName: 'NeighboringWiFiDiagnostic()',
      commandKey: 'ck-1778',
      status: status,
      outputArgs: args,
    );
  }

  /// A finished scan, for provider and view tests: 2.4 GHz on 1 and 5 GHz on
  /// 48, with neighbours on a few channels.
  static ChannelFinderResultUIModel result({DateTime? scannedAt}) =>
      ChannelFinderResultUIModel(
        scannedAt: scannedAt ?? DateTime(2026, 11, 26, 10, 54),
        bands: const [
          ChannelBandScanUIModel(band: '2.4GHz', channelInUse: 1, channels: [
            ChannelScanUIModel(
                channel: 1,
                utilization: 60,
                isInUse: true,
                neighbors: [
                  ChannelNeighborUIModel(
                      ssid: 'Cafe', bssid: 'aa:bb:cc:00:01:01', signalDbm: -52),
                  ChannelNeighborUIModel(
                      ssid: '', bssid: 'aa:bb:cc:00:01:02', signalDbm: -80),
                ]),
            ChannelScanUIModel(
                channel: 6,
                utilization: 84,
                isInUse: false,
                neighbors: [
                  ChannelNeighborUIModel(
                      ssid: 'Office',
                      bssid: 'aa:bb:cc:00:06:01',
                      signalDbm: -80),
                ]),
            ChannelScanUIModel(
                channel: 11, utilization: 52, isInUse: false, neighbors: []),
          ]),
          ChannelBandScanUIModel(band: '5GHz', channelInUse: 48, channels: [
            ChannelScanUIModel(
                channel: 36,
                utilization: 10,
                isInUse: false,
                neighbors: [
                  ChannelNeighborUIModel(
                      ssid: 'Upstairs',
                      bssid: 'aa:bb:cc:00:24:01',
                      signalDbm: -29),
                ]),
            ChannelScanUIModel(
                channel: 40, utilization: 2, isInUse: false, neighbors: []),
            ChannelScanUIModel(
                channel: 48,
                utilization: 11,
                isInUse: true,
                neighbors: [
                  ChannelNeighborUIModel(
                      ssid: 'Lobby',
                      bssid: 'aa:bb:cc:00:30:01',
                      signalDbm: -45),
                ]),
            ChannelScanUIModel(
                channel: 149, utilization: null, isInUse: false, neighbors: []),
          ]),
        ],
      );
}
