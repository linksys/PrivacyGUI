import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Result of a single gateway ping attempt.
class GatewayPingResult extends Equatable {
  final bool reachable;
  final int? latencyMs;

  const GatewayPingResult({required this.reachable, this.latencyMs});

  @override
  List<Object?> get props => [reachable, latencyMs];
}

/// Result of a DNS resolution check.
class DnsCheckResult extends Equatable {
  final bool resolved;
  final int? latencyMs;

  const DnsCheckResult({required this.resolved, this.latencyMs});

  @override
  List<Object?> get props => [resolved, latencyMs];
}

/// Internet speed test result (device → Cloudflare CDN → device).
class SpeedTestResult extends Equatable {
  final double downloadMbps;
  final double uploadMbps;
  final int latencyMs;
  final int jitterMs;

  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latencyMs,
    required this.jitterMs,
  });

  @override
  List<Object?> get props => [downloadMbps, uploadMbps, latencyMs, jitterMs];
}

/// Router-to-client WiFi throughput test result.
class RouterSpeedResult extends Equatable {
  final int latencyMs;
  final double? throughputMbps;

  const RouterSpeedResult({required this.latencyMs, this.throughputMbps});

  @override
  List<Object?> get props => [latencyMs, throughputMbps];
}

/// Combined result of all browser-based diagnostics.
class BrowserDiagnosticResult extends Equatable {
  final GatewayPingResult? gatewayPing;
  final DnsCheckResult? dnsCheck;
  final SpeedTestResult? speedTest;
  final RouterSpeedResult? routerSpeed;
  final DateTime timestamp;

  BrowserDiagnosticResult({
    this.gatewayPing,
    this.dnsCheck,
    this.speedTest,
    this.routerSpeed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Plain-language summary of overall connectivity health.
  String get verdict {
    if (gatewayPing != null && !gatewayPing!.reachable) {
      return 'Cannot reach your router. Your device may not be connected to WiFi.';
    }
    if (dnsCheck != null && !dnsCheck!.resolved) {
      return 'Your router is reachable but DNS is not working. Internet may be down.';
    }
    if (speedTest != null) {
      if (speedTest!.downloadMbps < 5) {
        return 'Your internet connection is very slow (${speedTest!.downloadMbps.toStringAsFixed(1)} Mbps down). This could be an ISP issue or network congestion.';
      }
      if (speedTest!.downloadMbps < 25) {
        return 'Your internet speed is below average (${speedTest!.downloadMbps.toStringAsFixed(1)} Mbps down). Video calls and streaming may struggle.';
      }
      if (speedTest!.latencyMs > 100) {
        return 'Your speed is OK but latency is high (${speedTest!.latencyMs} ms). Online gaming and video calls may lag.';
      }
      return 'Your internet connection looks healthy (${speedTest!.downloadMbps.toStringAsFixed(1)} Mbps down, ${speedTest!.latencyMs} ms latency).';
    }
    return 'Diagnostics incomplete.';
  }

  @override
  List<Object?> get props => [gatewayPing, dnsCheck, speedTest, routerSpeed, timestamp];
}

/// Browser-based diagnostic service that runs tests from the customer device.
class BrowserDiagnosticService {
  // Use the actual host serving this page — handles non-default LAN subnets.
  // Falls back to 192.168.1.1 if not running in a web context.
  static String get _gatewayUrl {
    if (kIsWeb) return 'http://${Uri.base.host}';
    return 'http://192.168.1.1';
  }
  // CORS-safe connectivity endpoints (Access-Control-Allow-Origin: *)
  static const _connectivityUrl = 'https://speed.cloudflare.com/__down?bytes=1';
  static const _dohUrl =
      'https://cloudflare-dns.com/dns-query?name=connectivitycheck.gstatic.com&type=A';
  static const _timeout = Duration(seconds: 5);

  // Cloudflare speed test endpoints (support CORS from any origin)
  static const _cfDownUrl = 'https://speed.cloudflare.com/__down';
  static const _cfUpUrl = 'https://speed.cloudflare.com/__up';

  // Download payload sizes for progressive speed test
  static const _downloadBytes = 10000000; // 10 MB
  static const _uploadBytes = 5000000; // 5 MB

  /// HTTP HEAD to the gateway. Self-signed cert TLS errors that come back fast
  /// still indicate the gateway is reachable (TCP connected).
  Future<GatewayPingResult> pingGateway() async {
    final stopwatch = Stopwatch()..start();
    try {
      await http.head(Uri.parse(_gatewayUrl)).timeout(_timeout);
      stopwatch.stop();
      return GatewayPingResult(reachable: true, latencyMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < _timeout.inMilliseconds - 500) {
        return GatewayPingResult(reachable: true, latencyMs: elapsed);
      }
      return const GatewayPingResult(reachable: false);
    }
  }

  /// Test internet-layer connectivity via CORS-safe Cloudflare endpoints.
  Future<GatewayPingResult> pingPublicIp() async {
    for (final url in [_connectivityUrl, '$_cfDownUrl?bytes=1']) {
      final stopwatch = Stopwatch()..start();
      try {
        final response = await http.get(Uri.parse(url)).timeout(_timeout);
        stopwatch.stop();
        if (response.statusCode == 200) {
          return GatewayPingResult(reachable: true, latencyMs: stopwatch.elapsedMilliseconds);
        }
      } catch (_) {
        stopwatch.stop();
      }
    }
    return const GatewayPingResult(reachable: false);
  }

  /// Test DNS resolution via Cloudflare's DoH endpoint (CORS-safe).
  ///
  /// Bypasses the ISP DNS resolver entirely — used internally to distinguish
  /// "ISP DNS is down" from "internet is completely unreachable".
  Future<DnsCheckResult> checkPublicDns() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(
        Uri.parse(_dohUrl),
        headers: {'Accept': 'application/dns-json'},
      ).timeout(_timeout);
      stopwatch.stop();
      if (response.statusCode == 200) {
        final body = response.body;
        final ok = body.contains('"Status":0') ||
            body.contains('"Status": 0') ||
            body.contains('"Answer"');
        if (ok) {
          return DnsCheckResult(
              resolved: true, latencyMs: stopwatch.elapsedMilliseconds);
        }
      }
    } catch (_) {
      stopwatch.stop();
    }
    return const DnsCheckResult(resolved: false);
  }

  /// Verify DNS resolution and internet connectivity via CORS-safe endpoints.
  Future<DnsCheckResult> checkDns() async {
    // Primary: Cloudflare speed endpoint (no DNS needed, proves raw connectivity)
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse(_connectivityUrl)).timeout(_timeout);
      stopwatch.stop();
      if (response.statusCode == 200) {
        return DnsCheckResult(resolved: true, latencyMs: stopwatch.elapsedMilliseconds);
      }
    } catch (_) {
      stopwatch.stop();
    }
    // Fallback: Cloudflare DoH (proves DNS + connectivity)
    final sw2 = Stopwatch()..start();
    try {
      final response = await http.get(
        Uri.parse(_dohUrl),
        headers: {'Accept': 'application/dns-json'},
      ).timeout(_timeout);
      sw2.stop();
      if (response.statusCode == 200) {
        return DnsCheckResult(resolved: true, latencyMs: sw2.elapsedMilliseconds);
      }
    } catch (_) {
      sw2.stop();
    }
    return const DnsCheckResult(resolved: false);
  }

  // ── Internet Speed Test (Cloudflare) ─────────────────────────────────

  /// Real internet speed test using Cloudflare CDN endpoints.
  /// [onStep] callback receives step name: 'latency', 'download', 'upload', 'complete'.
  Future<SpeedTestResult> runInternetSpeedTest({
    void Function(String step)? onStep,
  }) async {
    // 1. Latency — multiple pings to Cloudflare, take median
    onStep?.call('latency');
    final latencies = await _measureLatencies(_connectivityUrl, samples: 5);
    final latencyMs = latencies.isNotEmpty ? _median(latencies) : 0;
    final jitterMs = latencies.length >= 2 ? _computeJitter(latencies) : 0;

    // 2. Download — fetch 10MB payload from Cloudflare
    onStep?.call('download');
    double downloadMbps = 0;
    try {
      final sw = Stopwatch()..start();
      final response = await http.get(
        Uri.parse('$_cfDownUrl?bytes=$_downloadBytes'),
      ).timeout(const Duration(seconds: 30));
      sw.stop();
      final bytes = response.bodyBytes.length;
      if (bytes > 0 && sw.elapsedMilliseconds > 0) {
        downloadMbps = (bytes * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
      }
    } catch (_) {
      // Cloudflare download failed — try fallback with smaller payload
      try {
        downloadMbps = await _fallbackDownloadTest();
      } catch (_) {}
    }

    // 3. Upload — POST data to Cloudflare
    // Note: Custom Content-Type triggers CORS preflight which may fail.
    // Use default content type (application/x-www-form-urlencoded) to avoid preflight.
    onStep?.call('upload');
    double uploadMbps = 0;
    try {
      // Generate a string payload — avoids needing octet-stream Content-Type
      final payload = String.fromCharCodes(
        List.generate(_uploadBytes, (i) => 65 + (i % 26)), // ASCII A-Z repeated
      );
      final sw = Stopwatch()..start();
      await http.post(
        Uri.parse('$_cfUpUrl?measId=${DateTime.now().millisecondsSinceEpoch}'),
        body: payload,
      ).timeout(const Duration(seconds: 30));
      sw.stop();
      if (sw.elapsedMilliseconds > 0) {
        uploadMbps = (_uploadBytes * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
      }
    } catch (_) {
      // Upload test failed — try smaller payload as fallback
      try {
        final smallPayload = 'x' * 1000000; // 1MB
        final sw = Stopwatch()..start();
        await http.post(
          Uri.parse('$_cfUpUrl?measId=${DateTime.now().millisecondsSinceEpoch}_fb'),
          body: smallPayload,
        ).timeout(const Duration(seconds: 15));
        sw.stop();
        if (sw.elapsedMilliseconds > 0) {
          uploadMbps = (1000000 * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
        }
      } catch (_) {}
    }

    onStep?.call('complete');
    return SpeedTestResult(
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      latencyMs: latencyMs,
      jitterMs: jitterMs,
    );
  }

  /// Fallback download test using smaller Cloudflare payload.
  Future<double> _fallbackDownloadTest() async {
    final sw = Stopwatch()..start();
    final response = await http.get(
      Uri.parse('$_cfDownUrl?bytes=1000000'),
    ).timeout(const Duration(seconds: 15));
    sw.stop();
    final bytes = response.bodyBytes.length;
    if (bytes == 0 || sw.elapsedMilliseconds == 0) return 0;
    return (bytes * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
  }

  // ── Router-to-Client Speed Test ──────────────────────────────────────

  /// Measures WiFi throughput from router to this device by downloading a
  /// known-size asset served by the router's web server.
  /// [onStep] receives: 'latency', 'throughput', 'complete'.
  Future<RouterSpeedResult> runRouterSpeedTest({
    void Function(String step)? onStep,
  }) async {
    // Determine router URL — same origin as the page we're running on
    final baseUrl = kIsWeb ? Uri.base.origin : _gatewayUrl;

    // 1. Latency to router
    onStep?.call('latency');
    final latencies = await _measureLatencies('$baseUrl/', samples: 5);
    final latencyMs = latencies.isNotEmpty ? _median(latencies) : 0;

    // 2. Throughput — discover a servable file, then do parallel downloads
    //    In production: main.dart.js (2-5 MB). In debug: flutter.js or bootstrap.
    //    Fall back to parallel small fetches of the root page.
    onStep?.call('throughput');
    double? throughputMbps;
    final bust = DateTime.now().millisecondsSinceEpoch;

    // Find a usable file
    String? throughputUrl;
    for (final file in ['main.dart.js', 'flutter.js', 'flutter_bootstrap.js', 'index.html']) {
      try {
        final probe = await http.get(
          Uri.parse('$baseUrl/$file?_=$bust'),
        ).timeout(const Duration(seconds: 5));
        if (probe.statusCode == 200 && probe.bodyBytes.length > 1000) {
          throughputUrl = '$baseUrl/$file';
          break;
        }
      } catch (_) {}
    }

    // Measure throughput with multiple waves of parallel downloads.
    // We run several waves to give the connection time to ramp up and
    // saturate the link, then take the best wave as the result.
    if (throughputUrl != null) {
      try {
        double bestWaveMbps = 0;
        // Wave 1: 10 parallel downloads (warm-up + measurement)
        for (var wave = 0; wave < 3; wave++) {
          final waveOffset = wave * 10;
          final sw = Stopwatch()..start();
          final futures = List.generate(10, (i) =>
            http.get(
              Uri.parse('$throughputUrl?_=${bust + waveOffset + i}'),
            ).timeout(const Duration(seconds: 20)),
          );
          final responses = await Future.wait(futures);
          sw.stop();
          final totalBytes = responses.fold<int>(0, (sum, r) => sum + r.bodyBytes.length);
          if (totalBytes > 0 && sw.elapsedMilliseconds > 0) {
            final waveMbps = (totalBytes * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
            if (waveMbps > bestWaveMbps) bestWaveMbps = waveMbps;
          }
        }
        if (bestWaveMbps > 0) throughputMbps = bestWaveMbps;
      } catch (_) {}
    } else {
      // No single file found — do parallel fetches of root page
      try {
        final sw = Stopwatch()..start();
        final futures = List.generate(30, (i) =>
          http.get(Uri.parse('$baseUrl/?_=${bust + i}')).timeout(const Duration(seconds: 10)),
        );
        final responses = await Future.wait(futures);
        sw.stop();
        final totalBytes = responses.fold<int>(0, (sum, r) => sum + r.bodyBytes.length);
        if (totalBytes > 0 && sw.elapsedMilliseconds > 0) {
          throughputMbps = (totalBytes * 8) / (sw.elapsedMilliseconds / 1000) / 1000000;
        }
      } catch (_) {}
    }

    onStep?.call('complete');
    return RouterSpeedResult(
      latencyMs: latencyMs,
      throughputMbps: throughputMbps,
    );
  }

  // ── Legacy: run all diagnostics ──────────────────────────────────────

  /// Run all diagnostics: gateway ping, DNS check, and internet speed test.
  Future<BrowserDiagnosticResult> runAll({
    void Function(String step)? onStep,
  }) async {
    onStep?.call('gateway');
    final gateway = await pingGateway();

    onStep?.call('dns');
    final dns = await checkDns();

    final speed = await runInternetSpeedTest(onStep: onStep);

    return BrowserDiagnosticResult(
      gatewayPing: gateway,
      dnsCheck: dns,
      speedTest: speed,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Measure round-trip latency to a URL, N times.
  Future<List<int>> _measureLatencies(String url, {int samples = 5}) async {
    final results = <int>[];
    for (var i = 0; i < samples; i++) {
      final sw = Stopwatch()..start();
      try {
        await http.get(Uri.parse(url)).timeout(_timeout);
        sw.stop();
        results.add(sw.elapsedMilliseconds);
      } catch (e) {
        sw.stop();
        // If error came fast, TCP connected but TLS/CORS failed — still valid latency
        if (sw.elapsedMilliseconds < _timeout.inMilliseconds - 500) {
          results.add(sw.elapsedMilliseconds);
        }
      }
    }
    return results;
  }

  /// Median of a list of integers.
  int _median(List<int> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) ~/ 2;
  }

  /// Jitter = average absolute deviation from the median.
  int _computeJitter(List<int> latencies) {
    final med = _median(latencies);
    final deviations = latencies.map((l) => (l - med).abs());
    return (deviations.reduce((a, b) => a + b) / latencies.length).round();
  }
}

final browserDiagnosticServiceProvider = Provider<BrowserDiagnosticService>((ref) {
  return BrowserDiagnosticService();
});
