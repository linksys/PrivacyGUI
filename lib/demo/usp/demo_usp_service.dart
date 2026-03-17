/// Mock UspService for Demo mode.
///
/// Extends [UspService] and overrides all public methods to return data
/// from [DemoUspDataLoader] instead of making real WASM/HTTP calls.
///
/// Includes a [_DynamicSimulator] that injects time-varying values for
/// traffic counters, CPU usage, and memory — making statistics charts
/// display realistic, animated data.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

class DemoUspService extends UspService {
  final DemoUspDataLoader _loader;
  final _DynamicSimulator _sim = _DynamicSimulator();

  DemoUspService(this._loader) : super('https://localhost');

  @override
  bool get isAuthenticated => true;

  @override
  String? get sessionToken => 'demo-session-token';

  // ---------------------------------------------------------------------------
  // Auth (no-op)
  // ---------------------------------------------------------------------------

  @override
  Future<void> login(String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshToken() async {}

  @override
  Future<void> reauth() async {}

  // ---------------------------------------------------------------------------
  // GET — wildcard expansion + dynamic simulation + value coercion
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> get(List<String> paths) async {
    await Future.delayed(const Duration(milliseconds: 40));

    final raw = _loader.resolve(paths);

    // Inject dynamic values for statistics charts
    _sim.apply(raw);

    // Coerce string values to proper Dart types
    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      result[entry.key] = _coerce(entry.key, entry.value);
    }

    // Ensure non-wildcard paths have an entry (null for missing)
    for (final path in paths) {
      if (path.contains('*') || path.endsWith('.')) continue;
      result.putIfAbsent(path, () => null);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // SET — update in-memory data
  // ---------------------------------------------------------------------------

  @override
  Future<void> set(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 20));
    for (final entry in parameters.entries) {
      _loader.setValue(entry.key, entry.value.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ADD — create new instance
  // ---------------------------------------------------------------------------

  @override
  Future<String> add(String objectPath,
      Map<String, dynamic> parameters) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final nextId = _loader.nextInstanceId(objectPath);
    final normalized =
        objectPath.endsWith('.') ? objectPath : '$objectPath.';
    final instancePath = '$normalized$nextId.';
    for (final entry in parameters.entries) {
      _loader.setValue('$instancePath${entry.key}', entry.value.toString());
    }
    debugPrint('[DemoUsp] ADD $instancePath');
    return instancePath;
  }

  @override
  Future<List<String>> addMultiple(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    final results = <String>[];
    for (final obj in objects) {
      final path = obj['path'] as String? ?? '';
      final params = obj['parameters'] as Map<String, String>? ?? {};
      results.add(await add(path, params));
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // DELETE — remove from in-memory data
  // ---------------------------------------------------------------------------

  @override
  Future<void> delete(String path) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _loader.removeByPrefix(path);
  }

  @override
  Future<void> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    for (final path in paths) {
      await delete(path);
    }
  }

  // ---------------------------------------------------------------------------
  // OPERATE — mock results for Ping / Traceroute / DHCP Renew
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final ts = DateTime.now().millisecondsSinceEpoch;

    if (command.contains('IPPing')) {
      return {
        'commandKey': 'demo-ping-$ts',
        'Status': 'Complete',
        'SuccessCount': args['NumberOfRepetitions'] ?? '4',
        'FailureCount': '0',
        'AverageResponseTime': '${8 + Random().nextInt(20)}',
        'MinimumResponseTime': '${5 + Random().nextInt(5)}',
        'MaximumResponseTime': '${20 + Random().nextInt(30)}',
      };
    }
    if (command.contains('TraceRoute')) {
      return {
        'commandKey': 'demo-trace-$ts',
        'Status': 'Complete',
        'ResponseTime': '${10 + Random().nextInt(15)}',
        'NumberOfRouteHops': '${2 + Random().nextInt(4)}',
      };
    }
    if (command.contains('Renew') || command.contains('Reboot')) {
      return {'commandKey': 'demo-op-$ts'};
    }

    debugPrint('[DemoUsp] OPERATE $command (unhandled)');
    return {};
  }

  // ---------------------------------------------------------------------------
  // Subscription — no-op (no SSE in demo)
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, String>> createNotifySubscription({
    required String notifType,
    required String referenceList,
  }) async => {'instancePath': 'Device.LocalAgent.Subscription.demo.'};

  @override
  Future<void> deleteNotifySubscription(String instancePath) async {}

  @override
  Future<List<Map<String, dynamic>>> listSubscriptions() async => [];

  @override
  Future<int> purgeAllSubscriptions() async => 0;

  @override
  Future<Subscription<T>> subscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
    Duration interval = const Duration(seconds: 5),
  }) async {
    final controller = StreamController<T>();
    return Subscription<T>(
      id: id,
      notifType: notifType,
      stream: controller.stream,
      cancel: () async => controller.close(),
    );
  }

  // ---------------------------------------------------------------------------
  // Dispose — skip WASM free()
  // ---------------------------------------------------------------------------

  @override
  void dispose() {}

  // ---------------------------------------------------------------------------
  // Value coercion (matches UspService._coerceValue)
  // ---------------------------------------------------------------------------

  dynamic _coerce(String path, String? raw) {
    if (raw == null) return null;
    if (raw.isEmpty) return '';
    final lower = raw.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    final isBoolPath = path.endsWith('Enable') ||
        path.endsWith('Active') ||
        path.endsWith('Upstream');
    if (isBoolPath) {
      if (raw == '1') return true;
      if (raw == '0') return false;
    }
    return raw;
  }
}

// =============================================================================
// Dynamic Simulator — injects time-varying values for statistics charts
// =============================================================================

/// Modifies traffic counters, CPU usage, and memory on each [apply] call
/// so that the statistics charts display realistic animated data.
class _DynamicSimulator {
  final _rng = Random();
  final _startTime = DateTime.now();

  // Cumulative traffic counters (bytes / packets) — only increase.
  final Map<String, int> _counters = {};

  /// Apply dynamic overrides to the resolved path map **in place**.
  void apply(Map<String, String> data) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;

    for (final key in data.keys.toList()) {
      // --- Traffic byte/packet counters ---
      if (_isTrafficCounter(key)) {
        _counters.putIfAbsent(
            key, () => int.tryParse(data[key] ?? '0') ?? 0);
        // Bytes: 50-500 KB/s per 5-second poll ≈ 250-2500 KB increment
        // Packets: 100-1000 per poll
        final isByte = key.contains('Bytes');
        final increment = isByte
            ? 250000 + _rng.nextInt(2250000) // 250KB–2.5MB
            : 100 + _rng.nextInt(900); // 100–1000 packets
        _counters[key] = _counters[key]! + increment;
        data[key] = _counters[key].toString();
        continue;
      }

      // --- Error/Discard counters (low frequency) ---
      if (_isErrorCounter(key)) {
        _counters.putIfAbsent(
            key, () => int.tryParse(data[key] ?? '0') ?? 0);
        // ~5% chance to increment by 1 each poll
        if (_rng.nextDouble() < 0.05) {
          _counters[key] = _counters[key]! + 1;
        }
        data[key] = _counters[key].toString();
        continue;
      }

      // --- CPU usage: sine wave + noise (15–45%) ---
      if (key == 'Device.DeviceInfo.ProcessStatus.CPUUsage') {
        final base = 30.0;
        final wave = 15.0 * sin(elapsed * 2 * pi / 60); // 60s period
        final noise = (_rng.nextDouble() - 0.5) * 6; // ±3
        final cpu = (base + wave + noise).clamp(5, 85).round();
        data[key] = cpu.toString();
        continue;
      }

      // --- Memory free: ±5% around baseline ---
      if (key == 'Device.DeviceInfo.MemoryStatus.Free') {
        const baseline = 262144; // 256 MB
        final jitter =
            (((_rng.nextDouble() - 0.5) * 2) * baseline * 0.05).round();
        data[key] = (baseline + jitter).toString();
        continue;
      }

      // --- UpTime: initial + real elapsed seconds ---
      if (key == 'Device.DeviceInfo.UpTime') {
        final initial = int.tryParse(data[key] ?? '86400') ?? 86400;
        data[key] = (initial + elapsed).toString();
        continue;
      }
    }
  }

  bool _isTrafficCounter(String key) {
    if (!key.startsWith('Device.IP.Interface.')) return false;
    return key.endsWith('.BytesSent') ||
        key.endsWith('.BytesReceived') ||
        key.endsWith('.PacketsSent') ||
        key.endsWith('.PacketsReceived');
  }

  bool _isErrorCounter(String key) {
    if (!key.startsWith('Device.IP.Interface.')) return false;
    return key.endsWith('.ErrorsSent') ||
        key.endsWith('.ErrorsReceived') ||
        key.endsWith('.DiscardPacketsSent') ||
        key.endsWith('.DiscardPacketsReceived');
  }
}
