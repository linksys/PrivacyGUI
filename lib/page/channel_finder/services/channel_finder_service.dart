import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/data_elements_network_info.g.dart';
import 'package:privacy_gui/generated/data_elements_network_operations.g.dart';
import 'package:privacy_gui/generated/data_elements_scan_results.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';

/// How long each part of a scan may take. A provider so tests can shorten it.
class ChannelFinderTimings {
  /// Limit for `NeighboringWiFiDiagnostic()`, which takes about 31 s (#1778).
  final Duration neighborScanTimeout;

  /// Wait before the first read of a radio's channel scan result. The result
  /// appeared 4–6 s after the call on the bench (#1778).
  final Duration channelScanFirstRead;

  /// Wait between later reads. Longer than the bridge client's 5 s GET cache,
  /// which a generated `fetch()` cannot bypass, so every read is a fresh one.
  final Duration channelScanReadInterval;

  /// Limit for one radio's channel scan, from the call to its result.
  final Duration channelScanTimeout;

  const ChannelFinderTimings({
    this.neighborScanTimeout = const Duration(seconds: 90),
    this.channelScanFirstRead = const Duration(seconds: 4),
    this.channelScanReadInterval = const Duration(milliseconds: 5500),
    this.channelScanTimeout = const Duration(seconds: 30),
  });
}

final channelFinderTimingsProvider =
    Provider<ChannelFinderTimings>((ref) => const ChannelFinderTimings());

final channelFinderServiceProvider = Provider<ChannelFinderService>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  final manager = ref.watch(sseManagerProvider);
  return ChannelFinderService(
    usp,
    ref.watch(sseOperationAwaiterProvider),
    isLiveUpdatesConnected: () => manager?.isConnected ?? false,
    timings: ref.watch(channelFinderTimingsProvider),
  );
});

/// Runs a Channel Finder scan on the controller's own radios (#1778).
///
/// Two firmware commands, one after the other, because every band shares one
/// wiphy, which runs one scan at a time (FWDEV#277):
/// 1. `Device.WiFi.NeighboringWiFiDiagnostic()` for the networks on each
///    channel. It is async; its results exist only as the output arguments of
///    its OperationComplete, so it runs through [SseOperationAwaiter] and needs
///    the live-updates stream.
/// 2. DataElements `Radio.{j}.ChannelScanRequest()` on each radio, for how busy
///    each channel is. It returns at once; the answer is a new `ScanResult`
///    under that radio, read with `DataElementsScanResults.fetch`.
///
/// A radio whose channel scan fails or times out keeps its neighbours and reads
/// no busyness; a neighbour scan that fails fails the whole scan.
class ChannelFinderService {
  static const neighborScanCommand = 'Device.WiFi.NeighboringWiFiDiagnostic()';

  /// The OperationComplete subscription's reference: the command itself.
  static const neighborScanReference = neighborScanCommand;

  /// Time on each channel; the value FW and the bench used (#1778).
  static const dwellTimeMs = 100;

  static const _bandOrder = ['2.4GHz', '5GHz', '6GHz'];

  final UspClient _usp;
  final SseOperationAwaiter? _awaiter;
  final bool Function() _isLiveUpdatesConnected;
  final ChannelFinderTimings _timings;

  ChannelFinderService(
    this._usp,
    this._awaiter, {
    required bool Function() isLiveUpdatesConnected,
    ChannelFinderTimings timings = const ChannelFinderTimings(),
  })  : _isLiveUpdatesConnected = isLiveUpdatesConnected,
        _timings = timings;

  /// Scans every enabled radio of the controller and returns what each channel
  /// looked like. [onStage] is told when each part starts.
  ///
  /// Throws [ServiceError]: [NetworkError] when the live-updates stream is
  /// down (the neighbour scan's result cannot arrive, so no scan is started),
  /// [TimeoutError] when the neighbour scan does not finish in time,
  /// [UspCompleteFailureError] when the router refuses it, and the mapped
  /// error of any failed read.
  Future<ChannelFinderResultUIModel> scan({
    void Function(ChannelFinderScanStage stage)? onStage,
  }) async {
    final awaiter = _awaiter;
    if (awaiter == null || !_isLiveUpdatesConnected()) {
      throw const NetworkError(
          detail: 'Live updates are not connected; the neighbour scan result '
              'could not arrive');
    }

    final radios = await _readRadios();
    if (radios.isEmpty) {
      throw const ResourceNotFoundError(detail: 'No enabled Wi-Fi radio');
    }

    onStage?.call(ChannelFinderScanStage.neighbors);
    final neighbors = await _runNeighborScan(awaiter);

    onStage?.call(ChannelFinderScanStage.channels);
    final busyness = <String, Map<int, int?>>{};
    DataElementsScanResults? earlier;
    try {
      earlier = await _readScanResults();
    } on ServiceError catch (e) {
      logger.w('[ChannelFinder] Reading earlier channel scans failed, so no '
          'channel is measured: $e');
    }
    if (earlier != null) {
      for (final radio in radios) {
        final dataElementsPath = radio.dataElementsPath;
        if (dataElementsPath == null) continue;
        busyness[radio.path] = await _runChannelScan(
          dataElementsPath,
          radio.channels,
          previous: _newestScan(earlier, dataElementsPath)?.timeStamp,
        );
      }
    }

    final bands = radios.map((radio) {
      final heard = neighbors[radio.path] ?? const {};
      final measured = busyness[radio.path] ?? const {};
      return ChannelBandScanUIModel(
        band: radio.band,
        channelInUse: radio.channelInUse,
        channels: [
          for (final channel in radio.channels)
            ChannelScanUIModel(
              channel: channel,
              utilization: measured[channel],
              isInUse: channel == radio.channelInUse,
              neighbors: heard[channel] ?? const [],
            ),
        ],
      );
    }).toList()
      ..sort((a, b) => _bandRank(a.band).compareTo(_bandRank(b.band)));

    return ChannelFinderResultUIModel(scannedAt: DateTime.now(), bands: bands);
  }

  // ─── Radios ─────────────────────────────────────────────────────────

  /// The enabled Wi-Fi radios, each with the controller's DataElements radio
  /// it is, found through a shared BSSID: on 2.0.4 the two tables are numbered
  /// in opposite orders, and the 2.4 GHz DataElements `Radio.ID` is not a BSSID
  /// the SSID table knows (#1295).
  Future<List<_ScanRadio>> _readRadios() async {
    final WiFiRadios wifiRadios;
    final WiFiSsids ssids;
    final DataElementsNetwork network;
    final DataElementsNetworkInfo info;
    try {
      wifiRadios = await WiFiRadios.fetch(_usp);
      ssids = await WiFiSsids.fetch(_usp);
      network = await DataElementsNetwork.fetch(_usp);
      info = await DataElementsNetworkInfo.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final controllerId = info.controllerId?.toUpperCase();
    final controller = network.items
        .where((node) => node.id.toUpperCase() == controllerId)
        .firstOrNull;

    return [
      for (final radio in wifiRadios.items.where((r) => r.enable))
        _ScanRadio(
          path: ensureTrailingDot(radio.instancePath),
          band: radio.operatingFrequencyBand,
          channelInUse: parseChannelInUse(radio.channelsInUse),
          channels: filterDfsChannels(
            parsePossibleChannels(radio.possibleChannels),
            band: radio.operatingFrequencyBand,
            dfsEnabled: radio.ieee80211hEnabled,
          ),
          dataElementsPath: _dataElementsRadioPath(
            controller,
            {
              for (final ssid in ssids.items)
                if (ensureTrailingDot(ssid.lowerLayers) ==
                        ensureTrailingDot(radio.instancePath) &&
                    ssid.bssid.isNotEmpty)
                  ssid.bssid.toUpperCase(),
            },
          ),
        ),
    ];
  }

  String? _dataElementsRadioPath(MeshNode? controller, Set<String> bssids) {
    if (controller == null || bssids.isEmpty) return null;
    for (final radio in controller.radios) {
      if (radio.bssList
          .any((bss) => bssids.contains(bss.bssid.toUpperCase()))) {
        return ensureTrailingDot(radio.instancePath);
      }
    }
    return null;
  }

  // ─── Neighbour scan ─────────────────────────────────────────────────

  /// Runs `NeighboringWiFiDiagnostic()` and groups its results by Wi-Fi radio
  /// path, then channel, strongest network first.
  Future<Map<String, Map<int, List<ChannelNeighborUIModel>>>> _runNeighborScan(
      SseOperationAwaiter awaiter) async {
    final OperateResult result;
    try {
      result = await awaiter.execute(
        operateCommand: neighborScanCommand,
        referencePath: neighborScanReference,
        timeout: _timings.neighborScanTimeout,
      );
    } on TimeoutException catch (e) {
      throw TimeoutError(detail: e.message);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    if (result.isFailure) {
      final code = int.tryParse(result.errorCode ?? '');
      throw UspCompleteFailureError(
        summary: 'The router refused the neighbour scan',
        failures: [
          UspErrorDetail(
            requestedPath: neighborScanCommand,
            errorCode: code ?? 0,
            errorMessage: result.errorMessage ?? '',
          ),
        ],
        code: code,
        detail: result.errorMessage,
      );
    }
    final status = result.outputArgs['Status'] ?? result.status;
    if (status != 'Complete') {
      throw UnexpectedError(detail: 'Neighbour scan ended with Status $status');
    }
    return groupNeighborScanResults(result.outputArgs);
  }

  /// Groups the `Result.{i}.*` output arguments of `NeighboringWiFiDiagnostic()`
  /// by `Radio` (a `Device.WiFi.Radio.{k}` path, given a trailing dot), then by
  /// channel, strongest network first. A result without a radio, a channel or
  /// a signal is left out.
  static Map<String, Map<int, List<ChannelNeighborUIModel>>>
      groupNeighborScanResults(Map<String, String> outputArgs) {
    final rows = <int, Map<String, String>>{};
    final key = RegExp(r'^Result\.(\d+)\.(\w+)$');
    for (final entry in outputArgs.entries) {
      final match = key.firstMatch(entry.key);
      if (match == null) continue;
      rows.putIfAbsent(int.parse(match.group(1)!), () => {})[match.group(2)!] =
          entry.value;
    }

    final grouped = <String, Map<int, List<ChannelNeighborUIModel>>>{};
    for (final row in rows.values) {
      final radio = row['Radio'] ?? '';
      final channel = int.tryParse(row['Channel'] ?? '');
      final signal = int.tryParse(row['SignalStrength'] ?? '');
      if (radio.isEmpty || channel == null || signal == null) continue;
      grouped
          .putIfAbsent(ensureTrailingDot(radio), () => {})
          .putIfAbsent(channel, () => [])
          .add(ChannelNeighborUIModel(
            ssid: row['SSID'] ?? '',
            bssid: row['BSSID'] ?? '',
            signalDbm: signal,
          ));
    }
    for (final channels in grouped.values) {
      for (final list in channels.values) {
        list.sort((a, b) => b.signalDbm.compareTo(a.signalDbm));
      }
    }
    return grouped;
  }

  // ─── Channel scan ───────────────────────────────────────────────────

  /// Runs `ChannelScanRequest()` on one DataElements radio and waits for a
  /// result newer than [previous]. Returns each scanned channel's utilization,
  /// or an empty map when the call fails or no new result arrives in time.
  Future<Map<int, int?>> _runChannelScan(
    String dataElementsPath,
    List<int> channels, {
    required DateTime? previous,
  }) async {
    final indices = _dataElementsIndices(dataElementsPath);
    if (indices == null || channels.isEmpty) return const {};
    try {
      await DataElementsNetworkOperations.channelScanRequest(
        _usp,
        indices.device,
        indices.radio,
        channelsList: channels.join(','),
        dwellTimeMs: dwellTimeMs,
      );
    } catch (e) {
      logger.w('[ChannelFinder] Channel scan on $dataElementsPath was not '
          'accepted: $e');
      return const {};
    }

    final giveUpAt = DateTime.now().add(_timings.channelScanTimeout);
    var wait = _timings.channelScanFirstRead;
    while (true) {
      await Future<void>.delayed(wait);
      wait = _timings.channelScanReadInterval;
      try {
        final scan = _newestScan(await _readScanResults(), dataElementsPath);
        final at = scan?.timeStamp;
        if (scan != null &&
            at != null &&
            (previous == null || at.isAfter(previous))) {
          return {
            for (final opClass in scan.opClassScans)
              for (final row in opClass.channelScans)
                if (row.channel != null) row.channel!: row.utilization,
          };
        }
      } on ServiceError catch (e) {
        logger.w('[ChannelFinder] Reading the channel scan of '
            '$dataElementsPath failed: $e');
      }
      if (!DateTime.now().isBefore(giveUpAt)) {
        logger.w('[ChannelFinder] No channel scan result for $dataElementsPath '
            'within ${_timings.channelScanTimeout.inSeconds} s');
        return const {};
      }
    }
  }

  Future<DataElementsScanResults> _readScanResults() async {
    try {
      return await DataElementsScanResults.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The newest `ScanResult` under [dataElementsPath], by its `TimeStamp`.
  static RadioScanResult? _newestScan(
      DataElementsScanResults results, String dataElementsPath) {
    RadioScanResult? newest;
    for (final node in results.items) {
      for (final radio in node.radios) {
        if (ensureTrailingDot(radio.instancePath) != dataElementsPath) continue;
        for (final scan in radio.scanResults) {
          final at = scan.timeStamp;
          if (at == null) continue;
          if (newest == null || at.isAfter(newest.timeStamp!)) newest = scan;
        }
      }
    }
    return newest;
  }

  static ({int device, int radio})? _dataElementsIndices(String path) {
    final match = RegExp(r'\.Device\.(\d+)\.Radio\.(\d+)\.$').firstMatch(path);
    if (match == null) return null;
    return (
      device: int.parse(match.group(1)!),
      radio: int.parse(match.group(2)!),
    );
  }

  static int _bandRank(String band) {
    final rank = _bandOrder.indexOf(band);
    return rank < 0 ? _bandOrder.length : rank;
  }
}

/// A Wi-Fi radio to scan, with what the scan needs to know about it.
class _ScanRadio {
  /// `Device.WiFi.Radio.{k}.`
  final String path;
  final String band;
  final int? channelInUse;

  /// The channels the radio may use: `PossibleChannels`, without DFS channels
  /// when DFS is off.
  final List<int> channels;

  /// The controller's `DataElements…Device.{i}.Radio.{j}.` for this radio, or
  /// null when none shares a BSSID with it.
  final String? dataElementsPath;

  const _ScanRadio({
    required this.path,
    required this.band,
    required this.channelInUse,
    required this.channels,
    required this.dataElementsPath,
  });
}
