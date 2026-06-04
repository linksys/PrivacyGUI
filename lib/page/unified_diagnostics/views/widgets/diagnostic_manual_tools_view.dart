import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/manual_tools_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Embeddable manual ping / traceroute tools — rendered inside the unified
/// diagnostics page when the user picks the "Manual Tools" entry.
class DiagnosticManualToolsView extends ConsumerStatefulWidget {
  const DiagnosticManualToolsView({super.key});

  @override
  ConsumerState<DiagnosticManualToolsView> createState() =>
      _DiagnosticManualToolsViewState();
}

class _DiagnosticManualToolsViewState
    extends ConsumerState<DiagnosticManualToolsView> {
  final _hostController = TextEditingController();
  final _dnsServerController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    _dnsServerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync controllers when remote state changes (e.g. tab switch resets host).
    ref.listen<AsyncValue<NetworkDiagnosticsState>>(manualToolsProvider,
        (previous, next) {
      final state = next.valueOrNull;
      if (state == null) return;
      if (_hostController.text != state.host) {
        _hostController.text = state.host;
      }
      if (_dnsServerController.text != state.dnsServer) {
        _dnsServerController.text = state.dnsServer;
      }
    });

    final asyncState = ref.watch(manualToolsProvider);

    return asyncState.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => _buildPageError(context, error),
      data: (state) => _buildContent(context, state),
    );
  }

  Widget _buildPageError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load diagnostics'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(manualToolsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NetworkDiagnosticsState state) {
    final notifier = ref.read(manualToolsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          'Run network diagnostics from your router to test connectivity',
          color: colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),

        // Tab selector
        _buildTabSelector(context, state, notifier),
        AppGap.lg(),

        // Host input
        _buildHostInput(context, state, notifier),
        AppGap.md(),

        // Config options (ping count / max hops / dns server)
        switch (state.activeTab) {
          DiagnosticType.ping => _buildPingConfig(context, state, notifier),
          DiagnosticType.traceroute =>
            _buildTracerouteConfig(context, state, notifier),
          DiagnosticType.nsLookup =>
            _buildNsLookupConfig(context, state, notifier),
        },
        AppGap.lg(),

        // Run button
        SizedBox(
          width: double.infinity,
          child: AppButton.primary(
            label: _getRunButtonLabel(state),
            onTap:
                _canRun(state) ? () => _runDiagnostic(state, notifier) : null,
          ),
        ),
        AppGap.lg(),

        // Running indicator
        if (state.isRunning) ...[
          const Center(child: AppLoader()),
          AppGap.sm(),
          Center(
            child: AppText.bodySmall(
              _getRunningLabel(state),
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.lg(),
        ],

        // Error display
        if (state.error != null) ...[
          AppCard(
            child: Row(
              children: [
                AppIcon.font(Icons.error_outline,
                    size: 20, color: colorScheme.error),
                AppGap.md(),
                Expanded(
                  child: AppText.bodyMedium(
                    _translateError(context, state.error!),
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          AppGap.lg(),
        ],

        // Results
        if (state.pingResult != null && state.activeTab == DiagnosticType.ping)
          _buildPingResult(context, state.pingResult!),
        if (state.tracerouteResult != null &&
            state.activeTab == DiagnosticType.traceroute)
          _buildTracerouteResult(context, state.tracerouteResult!),
        if (state.nsLookupResult != null &&
            state.activeTab == DiagnosticType.nsLookup)
          _buildNsLookupResult(context, state.nsLookupResult!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab selector
  // ---------------------------------------------------------------------------

  Widget _buildTabSelector(
    BuildContext context,
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Ping',
            isSelected: state.activeTab == DiagnosticType.ping,
            onTap: state.isRunning
                ? null
                : () => notifier.switchTab(DiagnosticType.ping),
            colorScheme: colorScheme,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _TabButton(
            label: 'Traceroute',
            isSelected: state.activeTab == DiagnosticType.traceroute,
            onTap: state.isRunning
                ? null
                : () => notifier.switchTab(DiagnosticType.traceroute),
            colorScheme: colorScheme,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _TabButton(
            label: 'NS Lookup',
            isSelected: state.activeTab == DiagnosticType.nsLookup,
            onTap: state.isRunning
                ? null
                : () => notifier.switchTab(DiagnosticType.nsLookup),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Host input
  // ---------------------------------------------------------------------------

  Widget _buildHostInput(
    BuildContext context,
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    final (label, hint) = switch (state.activeTab) {
      DiagnosticType.ping || DiagnosticType.traceroute => (
          'Target Host',
          'e.g. 8.8.8.8 or google.com'
        ),
      DiagnosticType.nsLookup => ('Host Name', 'e.g. google.com'),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(label),
          AppGap.lg(),
          AppTextField(
            controller: _hostController,
            hintText: hint,
            enabled: !state.isRunning,
            onChanged: (value) => notifier.updateHost(value),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ping config
  // ---------------------------------------------------------------------------

  Widget _buildPingConfig(
    BuildContext context,
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    return AppCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall('Packet Count'),
            AppGap.lg(),
            AppChipGroup(
              chips: [
                for (final count in const [3, 5, 10])
                  ChipItem(label: '$count', enabled: !state.isRunning),
              ],
              selectedIndices: {
                [3, 5, 10].indexOf(state.pingCount).clamp(0, 2),
              },
              selectionMode: ChipSelectionMode.single,
              onSelectionChanged: state.isRunning
                  ? null
                  : (indices) {
                      if (indices.isEmpty) return;
                      notifier.updatePingCount([3, 5, 10][indices.first]);
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper methods for run button and labels
  // ---------------------------------------------------------------------------

  String _getRunButtonLabel(NetworkDiagnosticsState state) {
    return switch (state.activeTab) {
      DiagnosticType.ping => 'Run Ping',
      DiagnosticType.traceroute => 'Run Traceroute',
      DiagnosticType.nsLookup => 'Run NS Lookup',
    };
  }

  bool _canRun(NetworkDiagnosticsState state) {
    if (state.isRunning) return false;
    return state.host.isNotEmpty;
  }

  void _runDiagnostic(
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    switch (state.activeTab) {
      case DiagnosticType.ping:
        notifier.runPing();
      case DiagnosticType.traceroute:
        notifier.runTraceroute();
      case DiagnosticType.nsLookup:
        notifier.runNsLookup();
    }
  }

  String _getRunningLabel(NetworkDiagnosticsState state) {
    return switch (state.activeTab) {
      DiagnosticType.ping => 'Pinging ${state.host}...',
      DiagnosticType.traceroute => 'Tracing route to ${state.host}...',
      DiagnosticType.nsLookup => 'Resolving ${state.host}...',
    };
  }

  String _translateError(BuildContext context, ServiceError error) {
    return switch (error) {
      DiagnosticTimeoutError(:final operation, :final host) =>
        loc(context).diagnosticTimeout(operation, host ?? ''),
      ConnectivityError() => loc(context).diagnosticsUnavailable,
      NetworkError() => loc(context).routerLostConnection,
      InvalidInputError(:final field) =>
        loc(context).diagnosticInvalidHost(field ?? ''),
      _ => loc(context).diagnosticUnexpectedError,
    };
  }

  // ---------------------------------------------------------------------------
  // Traceroute config
  // ---------------------------------------------------------------------------

  Widget _buildTracerouteConfig(
    BuildContext context,
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    return AppCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall('Max Hops'),
            AppGap.lg(),
            AppChipGroup(
              chips: [
                for (final hops in const [15, 30])
                  ChipItem(label: '$hops', enabled: !state.isRunning),
              ],
              selectedIndices: {
                [15, 30].indexOf(state.maxHops).clamp(0, 1),
              },
              selectionMode: ChipSelectionMode.single,
              onSelectionChanged: state.isRunning
                  ? null
                  : (indices) {
                      if (indices.isEmpty) return;
                      notifier.updateMaxHops([15, 30][indices.first]);
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ping result
  // ---------------------------------------------------------------------------

  Widget _buildPingResult(BuildContext context, PingResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final successColor =
        result.successRate >= 100 ? colorScheme.primary : colorScheme.tertiary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(
                result.isComplete ? Icons.check_circle : Icons.error,
                size: 20,
                color:
                    result.isComplete ? colorScheme.primary : colorScheme.error,
              ),
              AppGap.sm(),
              AppText.titleSmall(
                'Ping ${result.host}',
              ),
            ],
          ),
          AppGap.lg(),

          // Summary stats
          Row(
            children: [
              _StatBox(
                label: 'Avg',
                value: '${result.avgResponseTime}ms',
                colorScheme: colorScheme,
              ),
              AppGap.md(),
              _StatBox(
                label: 'Min',
                value: '${result.minResponseTime}ms',
                colorScheme: colorScheme,
              ),
              AppGap.md(),
              _StatBox(
                label: 'Max',
                value: '${result.maxResponseTime}ms',
                colorScheme: colorScheme,
              ),
            ],
          ),
          AppGap.lg(),

          // Success rate
          Row(
            children: [
              AppText.bodyMedium('Success: '),
              AppText.bodyMedium(
                '${result.successCount}/${result.totalCount}',
                color: successColor,
              ),
              AppGap.sm(),
              AppText.bodySmall(
                '(${result.successRate.toStringAsFixed(0)}%)',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppGap.sm(),
          AppLoader(
            variant: LoaderVariant.linear,
            value: result.successRate / 100,
            color: successColor,
            strokeWidth: 6,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Traceroute result
  // ---------------------------------------------------------------------------

  Widget _buildTracerouteResult(BuildContext context, TracerouteResult result) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(
                result.isComplete ? Icons.check_circle : Icons.error,
                size: 20,
                color:
                    result.isComplete ? colorScheme.primary : colorScheme.error,
              ),
              AppGap.sm(),
              AppText.titleSmall(
                'Traceroute to ${result.host}',
              ),
              const Spacer(),
              AppText.bodySmall(
                '${result.hops.length} hops',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppGap.lg(),

          // Header row
          Row(
            children: [
              SizedBox(
                width: 32,
                child: AppText.labelSmall('#',
                    color: colorScheme.onSurfaceVariant),
              ),
              Expanded(
                flex: 3,
                child: AppText.labelSmall('Host',
                    color: colorScheme.onSurfaceVariant),
              ),
              Expanded(
                flex: 2,
                child: AppText.labelSmall('IP',
                    color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(
                width: 64,
                child: AppText.labelSmall('Avg RTT',
                    color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 16),

          // Hop rows
          ...result.hops.map((hop) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: AppText.bodySmall('${hop.hopNumber}'),
                    ),
                    Expanded(
                      flex: 3,
                      child: AppText.bodySmall(
                        hop.host.isNotEmpty ? hop.host : '*',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText.bodySmall(
                        hop.hostAddress.isNotEmpty ? hop.hostAddress : '*',
                        overflow: TextOverflow.ellipsis,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: AppText.bodySmall(
                        hop.rtTimes.isNotEmpty ? '${hop.avgRoundTrip}ms' : '*',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NS Lookup config
  // ---------------------------------------------------------------------------

  Widget _buildNsLookupConfig(
    BuildContext context,
    NetworkDiagnosticsState state,
    ManualToolsNotifier notifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('DNS Server (optional)'),
          AppGap.lg(),
          AppTextField(
            controller: _dnsServerController,
            hintText: 'e.g. 8.8.8.8 — leave blank to use the system resolver',
            enabled: !state.isRunning,
            onChanged: (value) => notifier.updateDnsServer(value),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NS Lookup result
  // ---------------------------------------------------------------------------

  Widget _buildNsLookupResult(BuildContext context, NsLookupResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOk = result.isComplete && result.hasAnswers;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(
                isOk ? Icons.check_circle : Icons.error,
                size: 20,
                color: isOk ? colorScheme.primary : colorScheme.error,
              ),
              AppGap.sm(),
              AppText.titleSmall('NS Lookup ${result.hostName}'),
              const Spacer(),
              AppText.bodySmall(
                result.status,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppGap.lg(),
          if (result.answers.isEmpty)
            AppText.bodyMedium(
              'No answers returned.',
              color: colorScheme.onSurfaceVariant,
            )
          else ...[
            // Header row
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: AppText.labelSmall(
                    '#',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: AppText.labelSmall(
                    'IPs',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: AppText.labelSmall(
                    'DNS Server',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: AppText.labelSmall(
                    'RT',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...result.answers.map(
              (answer) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: AppText.bodySmall('${answer.index}'),
                    ),
                    Expanded(
                      flex: 3,
                      child: AppText.bodySmall(
                        answer.ipAddresses.isEmpty
                            ? '*'
                            : answer.ipAddresses.join(', '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AppText.bodySmall(
                        answer.dnsServerIp.isEmpty ? '*' : answer.dnsServerIp,
                        overflow: TextOverflow.ellipsis,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: AppText.bodySmall(
                        '${answer.responseTimeMs}ms',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: AppText.labelLarge(
              label,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatBox({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
            AppGap.xs(),
            AppText.titleMedium(value),
          ],
        ),
      ),
    );
  }
}
