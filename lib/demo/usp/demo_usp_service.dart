/// Demo-mode [UspTransport] implementation.
///
/// P3 moved demo mode from a `UspClient` subclass down to the low-level
/// [UspTransport] seam: instead of re-implementing UspClient's high-level API,
/// [DemoUspTransport] plugs into the real [UspClient] via
/// `UspClient.withTransport(...)`. Demo data now flows through the exact same
/// production code path (value coercion, wildcard back-fill, single/batch
/// dispatch, auth-retry, SSE-or-polling subscribe) — the demo just swaps the
/// router for an in-memory [DemoUspDataLoader].
///
/// Consequences of the move:
/// - `get` returns the RAW `Map<String, String>` (no coercion here) — the real
///   [UspClient] coerces. The old demo `_coerce` duplicated UspClient's logic
///   and is gone.
/// - `set`/`add`/`delete`/`operate` return the WASM v0.11.0 **unified** result
///   shape `{success, result: {data, error?}}` — byte-identical to the real
///   WASM client — so [UspResultParser] and the service layer treat demo
///   results exactly like production. (The old demo `{overallSuccess, results}`
///   shape did not match the parser's `map['success']` read.)
/// - No `subscribe` here — [UspClient] owns subscriptions and falls back to
///   polling (`get()` every N seconds) when no SSE delegate is set, which keeps
///   the statistics charts animated via [_DynamicSimulator].
///
/// A [_DynamicSimulator] still injects time-varying values (traffic counters,
/// CPU, memory, uptime) on each `get`, so polled charts move.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';

class DemoUspTransport implements UspTransport {
  final DemoUspDataLoader _loader;
  final _DynamicSimulator _sim = _DynamicSimulator();

  DemoUspTransport(this._loader);

  // ---------------------------------------------------------------------------
  // Auth — demo is always authenticated; auth calls are no-ops.
  // ---------------------------------------------------------------------------

  @override
  bool get isAuthenticated => true;

  @override
  String? get sessionToken => 'demo-session-token';

  @override
  Future<void> login(String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshToken({String? token}) async {}

  // ---------------------------------------------------------------------------
  // GET — raw wildcard/prefix resolution + dynamic simulation.
  //
  // Returns the RAW string map exactly like the WASM client. The real
  // UspClient applies coercion and non-wildcard back-fill on top; demo must not
  // duplicate that (doing so previously double-implemented UspClient._coerce).
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, String>> get(List<String> paths) async {
    await Future.delayed(const Duration(milliseconds: 40));

    final raw = _loader.resolve(paths);

    // Inject dynamic values for statistics charts (mutates `raw` in place).
    _sim.apply(raw);

    return raw;
  }

  // ---------------------------------------------------------------------------
  // SET — update the in-memory store, return the unified result shape.
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> set(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 20));

    for (final entry in parameters.entries) {
      _loader.setValue(entry.key, entry.value);
    }

    return _unifiedSuccess(
        {for (final e in parameters.entries) e.key: e.value});
  }

  @override
  Future<Map<String, dynamic>> setOrdered(
      List<List<Map<String, String>>> parameterGroups,
      {bool allowPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 20));

    final applied = <String, String>{};
    for (final group in parameterGroups) {
      for (final entry in group) {
        final path = entry['path'];
        final value = entry['value'];
        if (path == null) continue;
        _loader.setValue(path, value ?? '');
        applied[path] = value ?? '';
      }
    }

    return _unifiedSuccess(applied);
  }

  // ---------------------------------------------------------------------------
  // ADD — create a new instance, return unified {data: {instances: [...]}}.
  //
  // UspResultParser.parseAddResult reads `result.data.instances` as a list of
  // created instance-path strings, so the demo must return the created path(s)
  // under that key.
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
      {bool allowPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 20));

    final createdPaths = <String>[];
    for (final item in items) {
      final objectPath = item['path'] as String? ?? '';
      final parameters =
          (item['params'] as Map?)?.cast<String, dynamic>() ?? {};
      final normalized = objectPath.endsWith('.') ? objectPath : '$objectPath.';
      final nextId = _loader.nextInstanceId(normalized);
      final instancePath = '$normalized$nextId.';

      for (final entry in parameters.entries) {
        _loader.setValue('$instancePath${entry.key}', entry.value.toString());
      }

      debugPrint('[DemoUsp] ADD $instancePath');
      createdPaths.add(instancePath);
    }

    return {
      'success': true,
      'result': {
        'data': {'instances': createdPaths},
      },
    };
  }

  // ---------------------------------------------------------------------------
  // DELETE — remove by prefix, return unified success.
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> delete(List<String> paths,
      {bool allowPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 20));

    for (final path in paths) {
      _loader.removeByPrefix(path);
    }

    return {
      'success': true,
      'result': {
        'data': {for (final p in paths) p: 'deleted'},
      },
    };
  }

  // ---------------------------------------------------------------------------
  // OPERATE — mock Ping / Traceroute / DHCP Renew, unified {data:{commandKey,
  // outputArgs}} shape so UspClient._extractOperateResult flattens it.
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final ts = DateTime.now().millisecondsSinceEpoch;

    Map<String, String> outputArgs;
    String commandKey;
    if (command.contains('IPPing')) {
      commandKey = 'demo-ping-$ts';
      outputArgs = {
        'Status': 'Complete',
        'SuccessCount': args['NumberOfRepetitions'] ?? '4',
        'FailureCount': '0',
        'AverageResponseTime': '${8 + Random().nextInt(20)}',
        'MinimumResponseTime': '${5 + Random().nextInt(5)}',
        'MaximumResponseTime': '${20 + Random().nextInt(30)}',
      };
    } else if (command.contains('TraceRoute')) {
      commandKey = 'demo-trace-$ts';
      outputArgs = {
        'Status': 'Complete',
        'ResponseTime': '${10 + Random().nextInt(15)}',
        'NumberOfRouteHops': '${2 + Random().nextInt(4)}',
      };
    } else if (command.contains('Renew') || command.contains('Reboot')) {
      commandKey = 'demo-op-$ts';
      outputArgs = {};
    } else {
      debugPrint('[DemoUsp] OPERATE $command (unhandled)');
      commandKey = 'demo-op-$ts';
      outputArgs = {};
    }

    return {
      'success': true,
      'result': {
        'data': {'commandKey': commandKey, 'outputArgs': outputArgs},
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Subscriptions — demo has none. UspClient handles subscribe() via polling.
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> listSubscriptions() async => [];

  @override
  void dispose() {}

  // ---------------------------------------------------------------------------
  // Helper — WASM v0.11.0 unified all-success result.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _unifiedSuccess(Map<String, dynamic> data) => {
        'success': true,
        'result': {'data': data},
      };
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
        _counters.putIfAbsent(key, () => int.tryParse(data[key] ?? '0') ?? 0);
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
        _counters.putIfAbsent(key, () => int.tryParse(data[key] ?? '0') ?? 0);
        // ~5% chance to increment by 1 each poll
        if (_rng.nextDouble() < 0.05) {
          _counters[key] = _counters[key]! + 1;
        }
        data[key] = _counters[key].toString();
        continue;
      }

      // --- CPU usage: sine wave + noise (15–45%) ---
      if (key == 'Device.DeviceInfo.ProcessStatus.CPUUsage') {
        const base = 30.0;
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
