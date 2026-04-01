import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlowCantConnectView extends ConsumerStatefulWidget {
  const FlowCantConnectView({super.key});

  @override
  ConsumerState<FlowCantConnectView> createState() => _FlowCantConnectViewState();
}

class _FlowCantConnectViewState extends ConsumerState<FlowCantConnectView> {
  final Map<int, bool> _checked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Can't Connect")),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work through each step. Most issues are fixed by the first three.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                ..._checklistItems.asMap().entries.map((entry) =>
                    _buildChecklistItem(context, entry.key, entry.value)),
                const SizedBox(height: 32),
                _buildStillStuck(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, int index, _ChecklistEntry item) {
    final isChecked = _checked[index] ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: (val) => setState(() => _checked[index] = val ?? false),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color: isChecked
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                : null,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(item.detail,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildStillStuck(BuildContext context) {
    final allChecked = _checklistItems.length == _checked.values.where((v) => v).length;

    return Card(
      color: allChecked
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.support_agent,
                  color: allChecked
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text("Still can't connect?",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const Text(
              'If you have tried all the steps above and your device still will not connect, '
              'contact Linksys Support. Have your router model and the device name ready.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('Contact Linksys Support'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support contact — coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistEntry {
  final String title;
  final String detail;
  const _ChecklistEntry(this.title, this.detail);
}

const _checklistItems = [
  _ChecklistEntry(
    'Is WiFi turned on?',
    'Open your device Settings and make sure WiFi is enabled. '
    'On iOS: Settings > WiFi. On Android: Settings > Network > WiFi. '
    'Some laptops have a physical WiFi switch or keyboard shortcut (Fn + WiFi key).',
  ),
  _ChecklistEntry(
    'Are you using the correct password?',
    'Your WiFi password is case-sensitive. Check for extra spaces. '
    'If you recently changed the password, older devices may still have the old one saved. '
    'You can find your current password in the Linksys app under WiFi Settings.',
  ),
  _ChecklistEntry(
    'Is the device in range?',
    'Move the device closer to the router and try again. '
    'Walls, floors, and large metal objects block WiFi signals. '
    'If you are more than 2-3 rooms away, the signal may be too weak.',
  ),
  _ChecklistEntry(
    'Restart the device',
    'Turn the device completely off, wait 10 seconds, then turn it back on. '
    'This clears the WiFi connection cache and forces a fresh connection attempt.',
  ),
  _ChecklistEntry(
    'Can you see the network name?',
    'On your device, look at available WiFi networks. Can you see yours? '
    'If not, restart your router — unplug it for 30 seconds, then plug back in.',
  ),
  _ChecklistEntry(
    'Try the 2.4 GHz network',
    'Some older devices and smart home gadgets only support 2.4 GHz WiFi. '
    'If your router has separate network names for 2.4 GHz and 5 GHz, '
    'try connecting to the 2.4 GHz network (often has "-2G" in the name).',
  ),
];
