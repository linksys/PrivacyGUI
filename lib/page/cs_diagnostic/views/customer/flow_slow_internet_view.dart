import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/browser_diagnostic_service.dart';

class FlowSlowInternetView extends ConsumerStatefulWidget {
  const FlowSlowInternetView({super.key});

  @override
  ConsumerState<FlowSlowInternetView> createState() => _FlowSlowInternetViewState();
}

class _FlowSlowInternetViewState extends ConsumerState<FlowSlowInternetView> {
  BrowserDiagnosticResult? _result;
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
      _result = null;
    });

    final service = ref.read(browserDiagnosticServiceProvider);

    setState(() => _currentStep = 'Checking gateway...');
    final gateway = await service.pingGateway();

    setState(() => _currentStep = 'Checking DNS...');
    final dns = await service.checkDns();

    setState(() => _currentStep = 'Running speed test...');
    final speed = await service.runSpeedTest();

    setState(() {
      _result = BrowserDiagnosticResult(
        gatewayPing: gateway,
        dnsCheck: dns,
        speedTest: speed,
      );
      _running = false;
      _currentStep = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Internet Speed Check')),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_running) _buildRunning(context),
                if (_result != null) ...[
                  _buildVerdict(context),
                  const SizedBox(height: 24),
                  _buildResultCards(context),
                  const SizedBox(height: 24),
                  _buildTips(context),
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
            const SizedBox(height: 8),
            Text('This takes about 10 seconds.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdict(BuildContext context) {
    final result = _result!;
    final gatewayOk = result.gatewayPing?.reachable == true;
    final dnsOk = result.dnsCheck?.resolved == true;
    final speedOk = (result.speedTest?.downloadMbps ?? 0) >= 25;
    final isHealthy = gatewayOk && dnsOk && speedOk;

    return Card(
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
            Expanded(
              child: Text(result.verdict,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isHealthy ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCards(BuildContext context) {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _resultRow(context, 'Gateway', result.gatewayPing?.reachable == true,
          result.gatewayPing?.reachable == true
              ? '${result.gatewayPing!.latencyMs} ms'
              : 'Unreachable',
        ),
        _resultRow(context, 'DNS / Internet', result.dnsCheck?.resolved == true,
          result.dnsCheck?.resolved == true
              ? '${result.dnsCheck!.latencyMs} ms'
              : 'Failed',
        ),
        if (result.speedTest != null) ...[
          _resultRow(context, 'Download',
              result.speedTest!.downloadMbps >= 25,
              '${result.speedTest!.downloadMbps.toStringAsFixed(1)} Mbps'),
          _resultRow(context, 'Upload',
              result.speedTest!.uploadMbps >= 5,
              '${result.speedTest!.uploadMbps.toStringAsFixed(1)} Mbps'),
          _resultRow(context, 'Latency',
              result.speedTest!.latencyMs <= 50,
              '${result.speedTest!.latencyMs} ms'),
        ],
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

  Widget _buildTips(BuildContext context) {
    final result = _result!;
    final tips = <String>[];

    if (result.gatewayPing?.reachable != true) {
      tips.add('Make sure you are connected to your WiFi network.');
      tips.add('Try turning WiFi off and on again on this device.');
      tips.add('Check if your router power light is on.');
    } else if (result.dnsCheck?.resolved != true) {
      tips.add('Your router is reachable but internet is not working.');
      tips.add('Restart your modem (unplug for 30 seconds, then plug back in).');
      tips.add('If the issue continues, contact your ISP.');
    } else {
      if ((result.speedTest?.downloadMbps ?? 0) < 25) {
        tips.add('Move closer to the router if possible.');
        tips.add('Disconnect devices you are not using.');
        tips.add('Restart your router (unplug for 30 seconds).');
        tips.add('If speeds are consistently low, contact your ISP about your plan.');
      }
      if ((result.speedTest?.latencyMs ?? 0) > 50) {
        tips.add('High latency can be caused by network congestion.');
        tips.add('Try using a wired Ethernet connection for time-sensitive tasks.');
      }
      if (tips.isEmpty) {
        tips.add('Your connection looks good. If it still feels slow, the issue may be with the website or service you are using.');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What to try',
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
