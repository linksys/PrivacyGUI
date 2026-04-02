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
      _result = null;
      _currentStep = 'Checking router...';
      _progress = 0;
    });

    final service = ref.read(browserDiagnosticServiceProvider);

    setState(() { _currentStep = 'Checking router connection...'; _progress = 0.05; });
    final gateway = await service.pingGateway();

    setState(() { _currentStep = 'Checking DNS...'; _progress = 0.1; });
    final dns = await service.checkDns();

    // Real internet speed test with progress updates
    final speed = await service.runInternetSpeedTest(
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          switch (step) {
            case 'latency':
              _currentStep = 'Measuring latency...';
              _progress = 0.15;
            case 'download':
              _currentStep = 'Testing download speed...';
              _progress = 0.35;
            case 'upload':
              _currentStep = 'Testing upload speed...';
              _progress = 0.7;
            case 'complete':
              _progress = 1.0;
          }
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _result = BrowserDiagnosticResult(
        gatewayPing: gateway,
        dnsCheck: dns,
        speedTest: speed,
      );
      _running = false;
    });
  }

  _InternetStatus get _internetStatus {
    if (_result == null) return _InternetStatus.unknown;
    final gatewayOk = _result!.gatewayPing?.reachable == true;
    final dnsOk = _result!.dnsCheck?.resolved == true;
    if (!gatewayOk) return _InternetStatus.noRouter;
    if (!dnsOk) return _InternetStatus.noInternet;
    return _InternetStatus.working;
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
                  _buildInternetStatus(context),
                  if (_internetStatus == _InternetStatus.working &&
                      _result!.speedTest != null) ...[
                    const SizedBox(height: 20),
                    _buildSpeedResults(context),
                    const SizedBox(height: 12),
                    _buildLatencyRow(context),
                  ],
                  const SizedBox(height: 24),
                  _buildVerdict(context),
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
            Text('Testing your internet connection...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildInternetStatus(BuildContext context) {
    final status = _internetStatus;
    final isWorking = status == _InternetStatus.working;
    final color = isWorking ? Colors.green : Colors.red;
    final bgColor = isWorking ? Colors.green.shade50 : Colors.red.shade50;
    final textColor = isWorking ? Colors.green.shade900 : Colors.red.shade900;
    final label = isWorking ? 'Working' : 'Not Working';

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              isWorking ? Icons.check_circle : Icons.cancel,
              color: color.shade700,
              size: 32,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Internet', style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.7),
                )),
                Text(label, style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedResults(BuildContext context) {
    final speed = _result!.speedTest!;
    return Row(
      children: [
        Expanded(child: _speedCard(
          context,
          icon: Icons.download,
          label: 'Download',
          value: speed.downloadMbps,
          unit: 'Mbps',
          isGood: speed.downloadMbps >= 25,
        )),
        const SizedBox(width: 12),
        Expanded(child: _speedCard(
          context,
          icon: Icons.upload,
          label: 'Upload',
          value: speed.uploadMbps,
          unit: 'Mbps',
          isGood: speed.uploadMbps >= 5,
        )),
      ],
    );
  }

  Widget _buildLatencyRow(BuildContext context) {
    final speed = _result!.speedTest!;
    return Row(
      children: [
        Expanded(child: _speedCard(
          context,
          icon: Icons.timer,
          label: 'Latency',
          value: speed.latencyMs.toDouble(),
          unit: 'ms',
          isGood: speed.latencyMs <= 50,
        )),
        const SizedBox(width: 12),
        Expanded(child: _speedCard(
          context,
          icon: Icons.graphic_eq,
          label: 'Jitter',
          value: speed.jitterMs.toDouble(),
          unit: 'ms',
          isGood: speed.jitterMs <= 10,
        )),
      ],
    );
  }

  Widget _speedCard(BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required String unit,
    required bool isGood,
  }) {
    final color = isGood ? Colors.green : Colors.orange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value < 100 ? value.toStringAsFixed(1) : value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            Text(unit, style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            )),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdict(BuildContext context) {
    final status = _internetStatus;
    final speed = _result?.speedTest;

    String verdict;
    switch (status) {
      case _InternetStatus.noRouter:
        verdict = 'Your device is not connected to the router. Check that WiFi is turned on.';
      case _InternetStatus.noInternet:
        verdict = 'Your router is working but the internet connection is down. This is usually an ISP issue.';
      case _InternetStatus.working:
        if (speed != null && speed.downloadMbps < 5) {
          verdict = 'Your internet is very slow. This could be network congestion or an ISP issue.';
        } else if (speed != null && speed.downloadMbps < 25) {
          verdict = 'Your internet is slower than expected. Video calls and streaming may not work well.';
        } else {
          verdict = 'Your internet connection looks healthy.';
        }
      case _InternetStatus.unknown:
        verdict = 'Test incomplete.';
    }

    return Text(verdict,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTips(BuildContext context) {
    final status = _internetStatus;
    final speed = _result?.speedTest;
    final tips = <String>[];

    switch (status) {
      case _InternetStatus.noRouter:
        tips.add('Make sure you are connected to your WiFi network.');
        tips.add('Try turning WiFi off and on again on this device.');
        tips.add('Check if your router power light is on.');
      case _InternetStatus.noInternet:
        tips.add('Restart your modem — unplug it for 30 seconds, then plug it back in.');
        tips.add('If that does not help, contact your internet provider.');
      case _InternetStatus.working:
        if (speed != null && speed.downloadMbps < 25) {
          tips.add('Move closer to the router if possible.');
          tips.add('Disconnect devices you are not using.');
          tips.add('Restart your router — unplug it for 30 seconds.');
          tips.add('If speeds stay low, contact your internet provider about your plan.');
        } else {
          tips.add('Everything looks good. If a specific app or website is slow, the problem may be on their end.');
        }
      case _InternetStatus.unknown:
        break;
    }

    if (tips.isEmpty) return const SizedBox.shrink();

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

enum _InternetStatus { working, noRouter, noInternet, unknown }
