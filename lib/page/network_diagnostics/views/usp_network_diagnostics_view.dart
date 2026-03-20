import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/network_diagnostics/models/network_diagnostics_ui_model.dart';
import 'package:privacy_gui/page/network_diagnostics/providers/usp_network_diagnostics_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspNetworkDiagnosticsView extends ConsumerStatefulWidget {
  const UspNetworkDiagnosticsView({super.key});

  @override
  ConsumerState<UspNetworkDiagnosticsView> createState() =>
      _UspNetworkDiagnosticsViewState();
}

class _UspNetworkDiagnosticsViewState
    extends ConsumerState<UspNetworkDiagnosticsView> {
  final _hostController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(uspNetworkDiagnosticsProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Network Diagnostics',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => _buildPageError(context),
          data: (state) => _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildPageError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load diagnostics'),
          AppGap.md(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspNetworkDiagnosticsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NetworkDiagnosticsState state) {
    final notifier = ref.read(uspNetworkDiagnosticsProvider.notifier);
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

        // Config options (ping count / max hops)
        if (state.activeTab == DiagnosticType.ping)
          _buildPingConfig(context, state, notifier)
        else
          _buildTracerouteConfig(context, state, notifier),
        AppGap.lg(),

        // Run button
        SizedBox(
          width: double.infinity,
          child: AppButton.primary(
            label: state.activeTab == DiagnosticType.ping
                ? 'Run Ping'
                : 'Run Traceroute',
            onTap: state.isRunning || state.host.isEmpty
                ? null
                : () {
                    if (state.activeTab == DiagnosticType.ping) {
                      notifier.runPing();
                    } else {
                      notifier.runTraceroute();
                    }
                  },
          ),
        ),
        AppGap.lg(),

        // Running indicator
        if (state.isRunning) ...[
          const Center(child: AppLoader()),
          AppGap.sm(),
          Center(
            child: AppText.bodySmall(
              state.activeTab == DiagnosticType.ping
                  ? 'Pinging ${state.host}...'
                  : 'Tracing route to ${state.host}...',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.lg(),
        ],

        // Error display
        if (state.errorMessage != null) ...[
          AppCard(
            child: Row(
              children: [
                AppIcon.font(Icons.error_outline,
                    size: 20, color: colorScheme.error),
                AppGap.md(),
                Expanded(
                  child: AppText.bodyMedium(
                    state.errorMessage!,
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab selector
  // ---------------------------------------------------------------------------

  Widget _buildTabSelector(
    BuildContext context,
    NetworkDiagnosticsState state,
    UspNetworkDiagnosticsNotifier notifier,
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Host input
  // ---------------------------------------------------------------------------

  Widget _buildHostInput(
    BuildContext context,
    NetworkDiagnosticsState state,
    UspNetworkDiagnosticsNotifier notifier,
  ) {
    // Sync controller with state on first build
    if (_hostController.text != state.host) {
      _hostController.text = state.host;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Target Host'),
          AppGap.lg(),
          AppTextField(
            controller: _hostController,
            hintText: 'e.g. 8.8.8.8 or google.com',
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
    UspNetworkDiagnosticsNotifier notifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Packet Count'),
          AppGap.lg(),
          Row(
            children: [3, 5, 10].map((count) {
              final selected = state.pingCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  onSelected: state.isRunning
                      ? null
                      : (_) => notifier.updatePingCount(count),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Traceroute config
  // ---------------------------------------------------------------------------

  Widget _buildTracerouteConfig(
    BuildContext context,
    NetworkDiagnosticsState state,
    UspNetworkDiagnosticsNotifier notifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Max Hops'),
          AppGap.lg(),
          Row(
            children: [15, 30].map((hops) {
              final selected = state.maxHops == hops;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text('$hops'),
                  selected: selected,
                  onSelected: state.isRunning
                      ? null
                      : (_) => notifier.updateMaxHops(hops),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ping result
  // ---------------------------------------------------------------------------

  Widget _buildPingResult(BuildContext context, PingResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final successColor =
        result.successRate >= 100 ? Colors.green : Colors.orange;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(
                result.isComplete ? Icons.check_circle : Icons.error,
                size: 20,
                color: result.isComplete ? Colors.green : colorScheme.error,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.successRate / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: successColor,
              minHeight: 6,
            ),
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
                color: result.isComplete ? Colors.green : colorScheme.error,
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
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
