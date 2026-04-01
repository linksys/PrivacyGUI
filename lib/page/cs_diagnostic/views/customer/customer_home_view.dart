import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/agent_login_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/flow_slow_internet_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/flow_slow_device_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/flow_cant_connect_view.dart';

class CustomerHomeView extends ConsumerWidget {
  const CustomerHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.wifi_find, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Instant-Help',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("What's going on?", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _flowCard(context, Icons.speed, 'Internet is slow',
                  'Test your connection speed',
                  const FlowSlowInternetView()),
              _flowCard(context, Icons.devices, 'One device is slow',
                  'Check this device specifically',
                  const FlowSlowDeviceView()),
              _flowCard(context, Icons.wifi_off, "Can't connect a device",
                  'Step-by-step troubleshooting',
                  const FlowCantConnectView()),
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  icon: Icon(Icons.support_agent, size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  label: Text('Support Agent Login',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AgentLoginView(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flowCard(BuildContext context, IconData icon, String title, String subtitle, Widget destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}
