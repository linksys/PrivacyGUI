import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/browser_diagnostic_service.dart';

class FlowSlowDeviceView extends ConsumerStatefulWidget {
  const FlowSlowDeviceView({super.key});

  @override
  ConsumerState<FlowSlowDeviceView> createState() => _FlowSlowDeviceViewState();
}

class _FlowSlowDeviceViewState extends ConsumerState<FlowSlowDeviceView> {
  SpeedTestResult? _speedResult;
  GatewayPingResult? _gatewayResult;
  bool _running = false;
  String? _currentStep;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _running = true;
      _speedResult = null;
      _gatewayResult = null;
    });

    final service = ref.read(browserDiagnosticServiceProvider);

    setState(() => _currentStep = 'Checking gateway...');
    final gateway = await service.pingGateway();

    setState(() => _currentStep = 'Running speed test...');
    final speed = await service.runSpeedTest();

    setState(() {
      _gatewayResult = gateway;
      _speedResult = speed;
      _running = false;
      _currentStep = null;
    });
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
                  'Testing speed from this device. If other devices work fine, the issue is likely with this device or its WiFi connection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                if (_running) _buildRunning(context),
                if (_speedResult != null) ...[
                  _buildDeviceResults(context),
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
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_currentStep ?? 'Running diagnostics...',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceResults(BuildContext context) {
    final speed = _speedResult!;
    final gateway = _gatewayResult;

    final downloadOk = speed.downloadMbps >= 25;
    final latencyOk = speed.latencyMs <= 50;
    final gatewayOk = gateway?.reachable == true;
    final isHealthy = downloadOk && latencyOk && gatewayOk;

    String summary;
    if (!gatewayOk) {
      summary = 'Cannot reach your router. This device may have a weak WiFi signal or be disconnected.';
    } else if (!downloadOk) {
      summary = 'This device is getting ${speed.downloadMbps.toStringAsFixed(1)} Mbps — below expected. The issue is likely between this device and the router.';
    } else if (!latencyOk) {
      summary = 'Speed is OK but latency is high (${speed.latencyMs} ms). WiFi interference or distance from the router may be the cause.';
    } else {
      summary = 'This device is performing well (${speed.downloadMbps.toStringAsFixed(1)} Mbps, ${speed.latencyMs} ms). If it still feels slow, the issue may be app-specific.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_amber,
                  color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isHealthy ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Device Test Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _resultRow(context, 'Router Reachable', gatewayOk,
            gatewayOk ? '${gateway!.latencyMs} ms' : 'No'),
        _resultRow(context, 'Download', downloadOk,
            '${speed.downloadMbps.toStringAsFixed(1)} Mbps'),
        _resultRow(context, 'Upload', speed.uploadMbps >= 5,
            '${speed.uploadMbps.toStringAsFixed(1)} Mbps'),
        _resultRow(context, 'Latency', latencyOk,
            '${speed.latencyMs} ms'),
        _resultRow(context, 'Jitter', speed.jitterMs <= 10,
            '${speed.jitterMs} ms'),
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
    final speed = _speedResult!;
    final gateway = _gatewayResult;

    if (gateway?.reachable != true) {
      tips.add('Turn WiFi off and back on in your device settings.');
      tips.add('Make sure you are connected to your home network, not a neighbor\'s.');
    }

    if (speed.downloadMbps < 25) {
      tips.add('Move closer to the router and test again.');
      tips.add('If you are on 2.4 GHz, try switching to 5 GHz for faster speed.');
      tips.add('Close background apps that may be using bandwidth.');
    }

    if (speed.latencyMs > 50) {
      tips.add('WiFi interference from microwaves, baby monitors, or Bluetooth can cause high latency.');
      tips.add('Try a wired Ethernet connection if available.');
    }

    if (speed.jitterMs > 10) {
      tips.add('High jitter can cause video calls to stutter. Try moving to a less crowded area.');
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
