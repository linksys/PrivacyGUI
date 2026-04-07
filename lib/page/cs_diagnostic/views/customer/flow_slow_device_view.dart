import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/browser_diagnostic_service.dart';

class FlowSlowDeviceView extends ConsumerStatefulWidget {
  const FlowSlowDeviceView({super.key});

  @override
  ConsumerState<FlowSlowDeviceView> createState() => _FlowSlowDeviceViewState();
}

class _FlowSlowDeviceViewState extends ConsumerState<FlowSlowDeviceView> {
  GatewayPingResult? _gatewayResult;
  RouterSpeedResult? _routerResult;
  SpeedTestResult? _internetResult;
  bool _running = false;
  String _currentStep = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _running = true;
      _gatewayResult = null;
      _routerResult = null;
      _internetResult = null;
      _currentStep = 'Checking router connection...';
      _progress = 0;
    });

    final service = ref.read(browserDiagnosticServiceProvider);

    // Step 1: Gateway ping
    setState(() { _currentStep = 'Checking router connection...'; _progress = 0.05; });
    final gateway = await service.pingGateway();

    // Step 2: Router-to-client WiFi speed test
    setState(() { _currentStep = 'Measuring WiFi speed to router...'; _progress = 0.1; });
    final routerSpeed = await service.runRouterSpeedTest(
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          switch (step) {
            case 'latency':
              _currentStep = 'Measuring WiFi latency to router...';
              _progress = 0.15;
            case 'throughput':
              _currentStep = 'Measuring WiFi throughput...';
              _progress = 0.3;
            case 'complete':
              _progress = 0.45;
          }
        });
      },
    );

    // Step 3: Internet speed (for comparison)
    final internetSpeed = await service.runInternetSpeedTest(
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          switch (step) {
            case 'latency':
              _currentStep = 'Measuring internet latency...';
              _progress = 0.5;
            case 'download':
              _currentStep = 'Testing internet download...';
              _progress = 0.65;
            case 'upload':
              _currentStep = 'Testing internet upload...';
              _progress = 0.85;
            case 'complete':
              _progress = 1.0;
          }
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _gatewayResult = gateway;
      _routerResult = routerSpeed;
      _internetResult = internetSpeed;
      _running = false;
    });
  }

  /// Determine where the bottleneck is
  _DeviceDiagnosis get _diagnosis {
    if (_gatewayResult?.reachable != true) return _DeviceDiagnosis.noRouter;
    final routerThroughput = _routerResult?.throughputMbps;
    final internetDown = _internetResult?.downloadMbps ?? 0;

    if (routerThroughput != null && routerThroughput < 25 && internetDown >= 25) {
      return _DeviceDiagnosis.wifiBottleneck;
    }
    if (internetDown < 25 && (routerThroughput == null || routerThroughput >= 25)) {
      return _DeviceDiagnosis.internetSlow;
    }
    if (routerThroughput != null && routerThroughput < 25 && internetDown < 25) {
      return _DeviceDiagnosis.bothSlow;
    }
    return _DeviceDiagnosis.healthy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Speed Check')),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Testing your WiFi connection to the router AND your internet speed. '
                  'This helps identify if the problem is WiFi or your internet plan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                if (_running) _buildRunning(context),
                if (!_running && _gatewayResult != null) ...[
                  _buildDiagnosisCard(context),
                  const SizedBox(height: 20),
                  _buildComparisonCards(context),
                  const SizedBox(height: 20),
                  _buildDetailedResults(context),
                  const SizedBox(height: 24),
                  _buildDeviceTips(context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Run Again'),
                      onPressed: _runDiagnostics,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunning(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            Text(_currentStep,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Testing WiFi and internet speed...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context) {
    final diag = _diagnosis;
    final isHealthy = diag == _DeviceDiagnosis.healthy;
    final color = isHealthy ? Colors.green : Colors.orange;
    final bgColor = isHealthy ? Colors.green.shade50 : Colors.orange.shade50;
    final textColor = isHealthy ? Colors.green.shade900 : Colors.orange.shade900;

    final message = switch (diag) {
      _DeviceDiagnosis.noRouter =>
        'Cannot reach your router. This device may not be connected to WiFi.',
      _DeviceDiagnosis.wifiBottleneck =>
        'Your internet is fast, but data transfer from the router is slow. '
        'The problem is between your device and the router — try moving closer.',
      _DeviceDiagnosis.internetSlow =>
        'Your router connection is fine, but internet speed is slow. '
        'This is likely an ISP issue, not a device problem.',
      _DeviceDiagnosis.bothSlow =>
        'Both your router connection and internet speed are slow. '
        'Start by moving closer to the router.',
      _DeviceDiagnosis.healthy =>
        'This device is performing well on both WiFi and internet.',
    };

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.warning_amber,
              color: color.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ))),
          ],
        ),
      ),
    );
  }

  /// Side-by-side comparison: Router throughput vs Internet speed
  Widget _buildComparisonCards(BuildContext context) {
    final routerMbps = _routerResult?.throughputMbps;
    final internetMbps = _internetResult?.downloadMbps ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard(
              context,
              icon: Icons.router,
              label: 'Router Throughput',
              value: routerMbps != null ? routerMbps.toStringAsFixed(0) : '—',
              unit: routerMbps != null ? 'Mbps' : '',
              isGood: routerMbps != null && routerMbps >= 25,
              sublabel: routerMbps == null ? 'Could not measure' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(
              context,
              icon: Icons.public,
              label: 'Internet Speed',
              value: internetMbps > 0 ? internetMbps.toStringAsFixed(0) : '—',
              unit: internetMbps > 0 ? 'Mbps' : '',
              isGood: internetMbps >= 25,
              sublabel: internetMbps == 0 ? 'Could not measure' : null,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Router throughput measures real data transfer over your WiFi connection. '
          'Actual WiFi link speed may be higher.',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required bool isGood,
    String? sublabel,
  }) {
    final color = value == '—' ? Colors.grey : (isGood ? Colors.green : Colors.orange);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            )),
            if (unit.isNotEmpty)
              Text(unit, style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (sublabel != null)
              Text(sublabel, style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedResults(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _resultRow(context, 'Router Reachable',
            _gatewayResult?.reachable == true,
            _gatewayResult?.reachable == true ? '${_gatewayResult!.latencyMs} ms' : 'No'),
        _resultRow(context, 'Latency to Router',
            _routerResult != null && _routerResult!.latencyMs <= 10,
            '${_routerResult?.latencyMs ?? "—"} ms'),
        if (_routerResult?.throughputMbps != null)
          _resultRow(context, 'Router Throughput (HTTP)',
              _routerResult!.throughputMbps! >= 25,
              '${_routerResult!.throughputMbps!.toStringAsFixed(1)} Mbps'),
        _resultRow(context, 'Internet Download',
            (_internetResult?.downloadMbps ?? 0) >= 25,
            '${_internetResult?.downloadMbps.toStringAsFixed(1) ?? "—"} Mbps'),
        _resultRow(context, 'Internet Upload',
            (_internetResult?.uploadMbps ?? 0) >= 5,
            '${_internetResult?.uploadMbps.toStringAsFixed(1) ?? "—"} Mbps'),
        _resultRow(context, 'Internet Latency',
            (_internetResult?.latencyMs ?? 999) <= 50,
            '${_internetResult?.latencyMs ?? "—"} ms'),
        _resultRow(context, 'Jitter',
            (_internetResult?.jitterMs ?? 999) <= 10,
            '${_internetResult?.jitterMs ?? "—"} ms'),
      ],
    );
  }

  Widget _resultRow(BuildContext context, String label, bool ok, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 20,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ok ? null : Colors.red.shade700,
          )),
        ],
      ),
    );
  }

  Widget _buildDeviceTips(BuildContext context) {
    final tips = <String>[];
    final diag = _diagnosis;

    switch (diag) {
      case _DeviceDiagnosis.noRouter:
        tips.add('Turn WiFi off and back on in your device settings.');
        tips.add('Make sure you are connected to your home network.');
      case _DeviceDiagnosis.wifiBottleneck:
        tips.add('Move closer to the router — WiFi speed drops with distance.');
        tips.add('Switch from 2.4 GHz to 5 GHz if available for faster speeds.');
        tips.add('Check for interference — microwaves, baby monitors, and Bluetooth can slow WiFi.');
        tips.add('If this device is far from the router, consider a mesh WiFi node for better coverage.');
      case _DeviceDiagnosis.internetSlow:
        tips.add('Your WiFi is fine — this is an ISP or internet issue.');
        tips.add('Restart your modem — unplug for 30 seconds, then plug back in.');
        tips.add('Check if other devices also have slow internet — if so, contact your ISP.');
      case _DeviceDiagnosis.bothSlow:
        tips.add('Move closer to the router and test again.');
        tips.add('Restart both your router and modem.');
        tips.add('Disconnect devices you are not using.');
      case _DeviceDiagnosis.healthy:
        tips.add('Your connection looks good. If a specific app feels slow, the issue may be on their end.');
    }

    tips.add('Restart your device — this clears the WiFi connection and gets a fresh one.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tips for this device',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip)),
                ],
              ),
            )),
      ],
    );
  }
}

enum _DeviceDiagnosis {
  noRouter,
  wifiBottleneck,
  internetSlow,
  bothSlow,
  healthy,
}
