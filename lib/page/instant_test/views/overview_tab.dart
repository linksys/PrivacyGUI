import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantTestProvider);
    final verdict = state.verdict;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isRestarting)
            const Center(child: CircularProgressIndicator()),
          if (state.phase == InstantTestLoadPhase.loading && !state.isRestarting)
            const Center(child: CircularProgressIndicator()),
          if (verdict == null && state.phase != InstantTestLoadPhase.loading)
            ElevatedButton(
              onPressed: () =>
                  ref.read(instantTestProvider.notifier).fetch(),
              child: Text(loc(context).instantTestRunButton),
            ),
          if (verdict != null) ...[
            if (state.verdictIsPreliminary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(label: Text(loc(context).instantTestPreliminaryBadge)),
              ),
            if (verdict.isAllClear)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(loc(context).instantTestAllChecksPassed),
              ),
            for (final finding in verdict.findings)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: _priorityIcon(finding.priority),
                      title: Text(finding.headline),
                      subtitle: Text(finding.explanation),
                    ),
                    if (finding.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: ElevatedButton(
                          onPressed: () => _handleAction(
                              context, ref, finding.actionKey ?? ''),
                          child: Text(finding.actionLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loc(context).instantTestChecksRun(verdict.checksRun),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String actionKey) async {
    if (actionKey == VerdictEngine.actionRestartRouter) {
      try {
        await ref.read(instantTestProvider.notifier).restartRouter();
        if (!context.mounted) return;
        // D-R1: wrap restart with Connection Recovery dialog
        await showRecoveryDialog(
          context,
          ref,
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: const Duration(seconds: 60),
          title: 'Router is rebooting',
          message:
              'All connected devices will be temporarily disconnected. Please wait.',
          successMessage: 'Router reboot complete',
        );
        if (context.mounted) {
          ref.read(instantTestProvider.notifier).fetch(forceSpeedTest: true);
        }
      } catch (_) {
        // restartRouter() already sets errorMessage on the state
      }
    }
  }

  Widget _priorityIcon(VerdictPriority priority) {
    switch (priority) {
      case VerdictPriority.critical:
        return const Icon(Icons.error, color: Colors.red);
      case VerdictPriority.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case VerdictPriority.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case VerdictPriority.allClear:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
