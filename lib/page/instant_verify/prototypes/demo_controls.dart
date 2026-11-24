import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'mock_pivot_notifier.dart';

const demoOverviewLabels = [
  'No internet connection',
  "Websites aren't loading",
  'Slow internet + weak WiFi',
  'Router overloaded + mesh issues',
  'Configuration blocks',
];

const demoProbeLabels = {
  PreviewProbeScenario.restartRejected: 'Restart request fails',
  PreviewProbeScenario.reconnectRejected: 'Reconnect request fails',
  PreviewProbeScenario.healthy: 'Healthy connection',
  PreviewProbeScenario.gatewayDown: 'Device cannot reach router',
  PreviewProbeScenario.internetDown: 'Router cannot reach internet',
  PreviewProbeScenario.dnsFailure: 'Websites fail to load',
  PreviewProbeScenario.probeError: 'Connection check fails',
  PreviewProbeScenario.speedError: 'Speed check fails',
  PreviewProbeScenario.slowSpeed: 'Slow download',
  PreviewProbeScenario.laggySpeed: 'High latency',
  PreviewProbeScenario.monitorDrops: 'Connection drops during monitoring',
  PreviewProbeScenario.speedAfterRestartError: 'Speed check fails after restart',
};

/// Reviewer controls exist only within the isolated, simulated preview.
class DemoControls extends StatelessWidget {
  const DemoControls({super.key, required this.overview, required this.probe});
  final int overview;
  final PreviewProbeScenario probe;

  @override
  Widget build(BuildContext context) => AppTextButton('Demo controls', onTap: () async {
    var selectedOverview = overview;
    var selectedProbe = probe;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: const Text('Demo controls'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulated data and router actions. Applying a scenario starts a fresh walkthrough.'),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: selectedOverview,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Overview findings'),
              items: [for (var i = 0; i < demoOverviewLabels.length; i++)
                DropdownMenuItem(value: i, child: Text(demoOverviewLabels[i]))],
              onChanged: (value) => setState(() => selectedOverview = value!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<PreviewProbeScenario>(
              value: selectedProbe,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Workflow test results'),
              items: [for (final item in demoProbeLabels.entries)
                DropdownMenuItem(value: item.key, child: Text(item.value))],
              onChanged: (value) => setState(() => selectedProbe = value!),
            ),
          ],
        ))),
        actions: [
          AppTextButton('Cancel', onTap: () => Navigator.pop(dialogContext, false)),
          AppFilledButton('Apply scenario', onTap: () => Navigator.pop(dialogContext, true)),
        ],
      )),
    );
    if (apply == true && context.mounted) {
      // Include a new run key so applying the same scenario resets its history.
      context.go(Uri(path: '/instant-prototype', queryParameters: {
        'overview': '$selectedOverview',
        'probe': selectedProbe.name,
        'run': '${DateTime.now().microsecondsSinceEpoch}',
      }).toString());
    }
  });
}
