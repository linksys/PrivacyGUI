import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';

final unifiedDiagnosticsServiceProvider =
    Provider<UnifiedDiagnosticsService?>((ref) {
  final usp = ref.watch(uspClientProvider);
  final awaiter = ref.watch(sseOperationAwaiterProvider);
  if (usp == null || awaiter == null) return null;
  return UnifiedDiagnosticsService(usp, awaiter);
});

/// Service encapsulating all USP operations for network diagnostics.
///
/// Uses:
/// - Codegen classes for GET operations (WanStatus, WiFiRadios, ConnectedDevices)
/// - SseOperationAwaiter for async Operate commands (Ping, Traceroute, SpeedTest)
class UnifiedDiagnosticsService {
  final UspClient _usp;
  final SseOperationAwaiter _awaiter;

  static const _defaultInternetHost =
      '1.1.1.1'; // Cloudflare — for internet check
  static const _defaultDnsHost = '8.8.8.8'; // Google DNS — for DNS check
  static const _defaultTracerouteHost = '8.8.8.8';

  UnifiedDiagnosticsService(this._usp, this._awaiter);

  // ─── WAN Status ──────────────────────────────────────────

  /// Check WAN interface status using codegen WanStatus.
  Future<WanStatusInfo> checkWanStatus() async {
    logger.d('[Diagnostics] Checking WAN status');
    final wan = await WanStatus.fetch(_usp);
    return WanStatusInfo(
      status: wan.status,
      ipAddress: wan.ipAddress,
      subnetMask: wan.subnetMask,
      addressingType: wan.addressingType,
    );
  }

  // ─── Ping Operations ─────────────────────────────────────

  // ─── Shared Session ──────────────────────────────────────

  /// Start a shared subscription session for batch diagnostics.
  /// Call [endSession] when diagnostics complete.
  Future<void> startSession() async {
    logger.d('[Diagnostics] Starting shared session');
    await _awaiter.startSharedSession(
      referencePath: 'Device.IP.Diagnostics.',
    );
  }

  /// End the shared subscription session.
  Future<void> endSession() async {
    logger.d('[Diagnostics] Ending shared session');
    await _awaiter.endSharedSession();
  }

  // ─── Ping Operations ─────────────────────────────────────

  /// Ping a host and return parsed result (uses shared session if active).
  Future<PingResult> ping(
    String host, {
    int repeatCount = 3,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    logger.d('[Diagnostics] Pinging $host (count=$repeatCount)');
    try {
      final result = await _awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {
          'Host': host,
          'NumberOfRepetitions': repeatCount.toString(),
        },
        timeout: timeout,
      );
      logger.d('[Diagnostics] Ping $host complete: ${result.status}');
      return PingResult.fromOperateResult(result, host);
    } catch (e) {
      logger.e('[Diagnostics] Ping $host failed: $e');
      rethrow;
    }
  }

  /// Ping the default gateway.
  Future<PingResult> pingGateway({int repeatCount = 3}) async {
    final wan = await checkWanStatus();
    if (wan.ipAddress.isEmpty) {
      throw Exception('No WAN IP address — cannot determine gateway');
    }
    final gateway = _deriveGateway(wan.ipAddress, wan.subnetMask);
    return ping(gateway, repeatCount: repeatCount);
  }

  /// Ping DNS server (Google 8.8.8.8).
  Future<PingResult> pingDns({
    String host = _defaultDnsHost,
    int repeatCount = 3,
  }) async {
    logger.d('[Diagnostics] Pinging DNS $host');
    return ping(host, repeatCount: repeatCount);
  }

  /// Ping an external host to verify internet connectivity (Cloudflare 1.1.1.1).
  Future<PingResult> pingInternet({
    String host = _defaultInternetHost,
    int repeatCount = 3,
  }) async {
    logger.d('[Diagnostics] Pinging Internet $host');
    return ping(host, repeatCount: repeatCount);
  }

  // ─── Traceroute ──────────────────────────────────────────

  /// Run traceroute to identify network path and bottlenecks.
  Future<TracerouteResult> traceroute({
    String host = _defaultTracerouteHost,
    int maxHops = 30,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    logger.d('[Diagnostics] Running traceroute to $host');
    final result = await _awaiter.execute(
      operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
      referencePath: 'Device.IP.Diagnostics.TraceRoute.',
      args: {
        'Host': host,
        'MaxHopCount': maxHops.toString(),
      },
      timeout: timeout,
    );
    return TracerouteResult.fromOperateResult(result, host);
  }

  // ─── WiFi & Devices ──────────────────────────────────────

  /// Fetch WiFi radio status (channels, signal info).
  Future<List<WiFiRadioInfo>> checkWifiRadios() async {
    logger.d('[Diagnostics] Checking WiFi radios');
    final radios = await WiFiRadios.fetch(_usp);
    return radios.items
        .map((r) => WiFiRadioInfo(
              instancePath: r.instancePath,
              band: r.operatingFrequencyBand,
              channel: r.channel,
              channelBandwidth: r.operatingChannelBandwidth,
              transmitPower: r.transmitPower,
              status: r.status,
              autoChannel: r.autoChannelEnable,
            ))
        .toList();
  }

  /// Fetch connected devices for bandwidth analysis.
  Future<ConnectedDevicesInfo> checkConnectedDevices() async {
    logger.d('[Diagnostics] Checking connected devices');
    final devices = await ConnectedDevices.fetch(_usp);

    final activeDevices = devices.items.where((d) => d.isActive).toList();

    // Identify high-bandwidth devices (simplified heuristic)
    final highBandwidth = activeDevices
        .where((d) =>
            (d.lastDataDownlinkRate ?? 0) > 50000000 ||
            (d.lastDataUplinkRate ?? 0) > 10000000)
        .map((d) => d.hostName.isNotEmpty ? d.hostName : d.macAddress)
        .toList();

    return ConnectedDevicesInfo(
      totalDevices: devices.items.length,
      activeDevices: activeDevices.length,
      highBandwidthDevices: highBandwidth,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  /// Derive default gateway from IP and subnet mask.
  /// Simple heuristic: assume gateway is .1 in the subnet.
  String _deriveGateway(String ipAddress, String subnetMask) {
    final ipParts = ipAddress.split('.').map(int.parse).toList();
    final maskParts = subnetMask.split('.').map(int.parse).toList();

    if (ipParts.length != 4 || maskParts.length != 4) {
      return '192.168.1.1'; // fallback
    }

    // Network address + .1
    final gateway = <int>[];
    for (int i = 0; i < 4; i++) {
      gateway.add(ipParts[i] & maskParts[i]);
    }
    gateway[3] = 1;

    return gateway.join('.');
  }
}

/// WAN status information.
class WanStatusInfo {
  final String status;
  final String ipAddress;
  final String subnetMask;
  final String addressingType;

  const WanStatusInfo({
    required this.status,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
  });

  bool get isUp => status == 'Up';
  bool get hasIp => ipAddress.isNotEmpty;
}

/// WiFi radio information.
class WiFiRadioInfo {
  final String instancePath;
  final String band;
  final int channel;
  final String channelBandwidth;
  final int transmitPower;
  final String status;
  final bool autoChannel;

  const WiFiRadioInfo({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.channelBandwidth,
    required this.transmitPower,
    required this.status,
    required this.autoChannel,
  });

  bool get is2_4GHz => band.contains('2.4');
  bool get is5GHz => band.contains('5');
  bool get is6GHz => band.contains('6');
}

/// Connected devices summary.
class ConnectedDevicesInfo {
  final int totalDevices;
  final int activeDevices;
  final List<String> highBandwidthDevices;

  const ConnectedDevicesInfo({
    required this.totalDevices,
    required this.activeDevices,
    required this.highBandwidthDevices,
  });

  bool get hasManyDevices => totalDevices > 20;
  bool get hasHighBandwidthDevices => highBandwidthDevices.isNotEmpty;
}
