import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';

// Flow 3 copy uses USP whitelist semantics per D-R3:
//  "allow this device on the network" instead of "unblock this device".
class HelpMeFixItTab extends ConsumerWidget {
  const HelpMeFixItTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verdict = ref.watch(instantTestProvider).verdict;
    final findings = verdict?.findings ?? [];
    final actionFindings = findings.where((f) => f.hasAutoFix).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc(context).instantTestTabHelpFix,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (actionFindings.isEmpty)
            Text(loc(context).instantTestNoIssues),
          for (final finding in actionFindings)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(finding.headline,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(finding.explanation),
                    if (finding.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () => _handleAction(
                              context, ref, finding.actionKey ?? ''),
                          child: Text(finding.actionLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // ── Flow 3: Instant Privacy (whitelist semantics, D-R3) ────────────
          const Divider(height: 32),
          Text(loc(context).instantTestDeviceAccessSection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Instant Privacy only allows pre-approved devices to connect. '
            'If a device you own cannot connect, add it to the allowed list.',
          ),
          const SizedBox(height: 8),
          _InstantPrivacyFlow3Section(),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String actionKey) async {
    if (actionKey == 'restart_router') {
      // Delegated to overview_tab's restart flow — handled there.
    }
  }
}

/// Flow 3 — whitelist semantics. Shows Instant Privacy state and lets the
/// customer allow devices onto the network (not "unblock").
class _InstantPrivacyFlow3Section extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAsync = ref.watch(uspInstantPrivacyProvider);

    return privacyAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Could not load privacy settings.'),
      data: (state) {
        if (!state.isEnabled) {
          return Text(loc(context).instantTestPrivacyOff);
        }
        final allowed = state.allowedDevices;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc(context).instantTestPrivacyOn(allowed.length)),
            const SizedBox(height: 8),
            const Text(
              'To allow a device on the network, tap "Allow All Devices" '
              'to disable Instant Privacy, or add a specific device by MAC address.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                try {
                  await ref.read(uspInstantPrivacyProvider.notifier).disable();
                } catch (_) {}
              },
              child: Text(loc(context).instantTestAllowAllDevices),
            ),
          ],
        );
      },
    );
  }
}
