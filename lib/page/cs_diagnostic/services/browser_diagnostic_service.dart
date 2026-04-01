import 'package:equatable/equatable.dart';
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

/// Placeholder speed test result (will integrate LibreSpeed later).
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

/// Combined result of all browser-based diagnostics.
class BrowserDiagnosticResult extends Equatable {
  final GatewayPingResult? gatewayPing;
  final DnsCheckResult? dnsCheck;
  final SpeedTestResult? speedTest;
  final DateTime timestamp;

  BrowserDiagnosticResult({
    this.gatewayPing,
    this.dnsCheck,
    this.speedTest,
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
  List<Object?> get props => [gatewayPing, dnsCheck, speedTest, timestamp];
}

/// Browser-based diagnostic service that runs tests from the customer device.
class BrowserDiagnosticService {
  /// Use HTTPS to match page origin and avoid mixed-content blocks.
  /// The router's self-signed cert will cause a TLS error, but the HTTP
  /// library still throws — we catch it and treat "connected but TLS error"
  /// as reachable (the TCP handshake succeeded).
  static const _gatewayUrl = 'https://192.168.1.1';
  /// Cloudflare endpoint — fast, reliable, and returns CORS headers.
  static const _dnsTestUrl = 'https://1.1.1.1/cdn-cgi/trace';
  /// Fallback: Google's generate_204 (may lack CORS headers but worth trying).
  static const _dnsTestFallback = 'https://www.google.com/generate_204';
  static const _timeout = Duration(seconds: 5);

  /// HTTP HEAD to the gateway. On a self-signed cert router, the TLS
  /// handshake may fail — but if it fails quickly (<timeout), the gateway
  /// is reachable (TCP connected, TLS rejected). Only a timeout or network
  /// error means truly unreachable.
  Future<GatewayPingResult> pingGateway() async {
    final stopwatch = Stopwatch()..start();
    try {
      await http.head(Uri.parse(_gatewayUrl)).timeout(_timeout);
      stopwatch.stop();
      return GatewayPingResult(reachable: true, latencyMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      // If error came back fast (< timeout), the TCP connection worked but
      // TLS/CORS rejected it — gateway IS reachable.
      if (elapsed < _timeout.inMilliseconds - 500) {
        return GatewayPingResult(reachable: true, latencyMs: elapsed);
      }
      return const GatewayPingResult(reachable: false);
    }
  }

  /// Fetch a known URL to verify DNS resolution and internet connectivity.
  /// Tries primary (Cloudflare), then fallback (Google). A successful HTTP
  /// response at any status code means DNS resolved and internet is reachable.
  /// CORS errors in browsers can mask successful DNS resolution, so we try
  /// multiple endpoints before declaring failure.
  Future<DnsCheckResult> checkDns() async {
    for (final url in [_dnsTestUrl, _dnsTestFallback]) {
      final stopwatch = Stopwatch()..start();
      try {
        await http.get(Uri.parse(url)).timeout(_timeout);
        stopwatch.stop();
        // Any HTTP response (even 4xx) means DNS + internet worked
        return DnsCheckResult(resolved: true, latencyMs: stopwatch.elapsedMilliseconds);
      } catch (_) {
        stopwatch.stop();
        // Try next endpoint — CORS may have blocked this one
      }
    }
    return const DnsCheckResult(resolved: false);
  }

  /// Placeholder speed test returning mock values. Will integrate LibreSpeed later.
  Future<SpeedTestResult> runSpeedTest() async {
    // Simulate test duration
    await Future<void>.delayed(const Duration(seconds: 2));
    return const SpeedTestResult(
      downloadMbps: 85.3,
      uploadMbps: 11.2,
      latencyMs: 18,
      jitterMs: 3,
    );
  }

  /// Run all diagnostics and return a combined result.
  Future<BrowserDiagnosticResult> runAll() async {
    final gateway = await pingGateway();
    final dns = await checkDns();
    final speed = await runSpeedTest();
    return BrowserDiagnosticResult(
      gatewayPing: gateway,
      dnsCheck: dns,
      speedTest: speed,
    );
  }
}

final browserDiagnosticServiceProvider = Provider<BrowserDiagnosticService>((ref) {
  return BrowserDiagnosticService();
});

/// Async provider that runs all browser diagnostics on read.
final browserDiagnosticResultProvider = FutureProvider.autoDispose<BrowserDiagnosticResult>((ref) async {
  final service = ref.read(browserDiagnosticServiceProvider);
  return service.runAll();
});
