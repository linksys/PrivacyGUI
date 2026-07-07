import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/speed_gauge.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SpeedTestView extends ConsumerWidget {
  const SpeedTestView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(speedTestProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).speedTest,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).unableToLoadSpeedTest,
            onRetry: () => ref.invalidate(speedTestProvider),
          ),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, SpeedTestState state) {
    return switch (state.step) {
      SpeedTestStep.idle => _buildIdle(context, ref),
      SpeedTestStep.completed => _buildResults(context, ref, state),
      SpeedTestStep.error => _buildError(context, ref, state),
      _ => _buildRunning(context, ref, state),
    };
  }

  // ---------------------------------------------------------------------------
  // Idle state — Start button
  // ---------------------------------------------------------------------------

  Widget _buildIdle(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(speedTestProvider).valueOrNull;
    final selectedServer = state?.selectedServer ?? SpeedTestServer.all.first;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.speed,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          AppGap.xxxl(),
          AppText.headlineSmall(loc(context).internetSpeedTest),
          AppGap.md(),
          AppText.bodyMedium(
            loc(context).testConnectionSpeedFromRouter,
            textAlign: TextAlign.center,
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.xl(),
          // Server selection button
          _ServerSelectionButton(
            selectedServer: selectedServer,
            onTap: () =>
                _showServerSelectionDialog(context, ref, selectedServer),
          ),
          AppGap.xxxl(),
          SizedBox(
            width: 200,
            child: AppButton.primary(
              label: loc(context).startTest,
              onTap: () => ref.read(speedTestProvider.notifier).runSpeedTest(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Running state — Progress with Gauge
  // ---------------------------------------------------------------------------

  Widget _buildRunning(
      BuildContext context, WidgetRef ref, SpeedTestState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final stepLabel = _getStepLabel(context, state.step);
    final isSpeedTest = state.step == SpeedTestStep.testingDownload ||
        state.step == SpeedTestStep.testingUpload;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show gauge during speed test, otherwise show progress circle
          if (isSpeedTest)
            SpeedGauge(
              value: 0,
              isAnimating: true,
              size: 220,
              centerBuilder: (ctx, displayValue) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.headlineLarge(
                    displayValue.toStringAsFixed(1),
                    color: colorScheme.primary,
                  ),
                  AppText.bodyMedium('Mbps'),
                  AppGap.sm(),
                  AppText.bodySmall(
                    loc(context).testing,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              bottomBuilder: (ctx, _) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppText.labelMedium(
                  state.step == SpeedTestStep.testingDownload
                      ? loc(context).download
                      : loc(context).upload,
                ),
              ),
            )
          else
            _buildProgressCircle(context, state),
          AppGap.xl(),
          AppText.titleMedium(stepLabel),
          AppGap.md(),
          if (state.progressMessage != null)
            AppText.bodyMedium(
              state.progressMessage!,
              color: colorScheme.onSurfaceVariant,
            ),
          AppGap.xl(),

          // Show partial results if available
          if (state.result != null) ...[
            _buildPartialResults(context, state.result!),
            AppGap.xl(),
          ],

          AppButton.text(
            label: loc(context).cancel,
            onTap: () => ref.read(speedTestProvider.notifier).reset(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(BuildContext context, SpeedTestState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _getProgress(state.step);

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: AppLoader(
              value: progress,
              strokeWidth: 8,
              color: colorScheme.primary,
            ),
          ),
          Icon(
            Icons.speed,
            size: 48,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPartialResults(BuildContext context, SpeedTestResult result) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (result.serverHost != null)
          _ResultRow(
            icon: Icons.dns,
            label: loc(context).server,
            value: result.serverHost!,
            colorScheme: colorScheme,
          ),
        if (result.hasLatency)
          _ResultRow(
            icon: Icons.network_ping,
            label: loc(context).latency,
            value: '${result.latencyMs} ms',
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  String _getStepLabel(BuildContext context, SpeedTestStep step) {
    return switch (step) {
      SpeedTestStep.testingLatency => loc(context).testingLatency,
      SpeedTestStep.testingDownload => loc(context).testingDownload,
      SpeedTestStep.testingUpload => loc(context).testingUpload,
      _ => loc(context).loading,
    };
  }

  double _getProgress(SpeedTestStep step) {
    return switch (step) {
      SpeedTestStep.testingLatency => 0.33,
      SpeedTestStep.testingDownload => 0.66,
      SpeedTestStep.testingUpload => 0.9,
      _ => 0.0,
    };
  }

  // ---------------------------------------------------------------------------
  // Completed state — Results
  // ---------------------------------------------------------------------------

  Widget _buildResults(
      BuildContext context, WidgetRef ref, SpeedTestState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Icon(
                result.isDownloadComplete ? Icons.check_circle : Icons.warning,
                size: 64,
                color: result.isDownloadComplete
                    ? colorScheme.primary
                    : colorScheme.tertiary,
              ),
              AppGap.md(),
              AppText.headlineSmall(loc(context).speedTestComplete),
              if (result.serverHost != null) ...[
                AppGap.xs(),
                AppText.bodySmall(
                  loc(context).serverLabel(result.serverHost!),
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        AppGap.xxxl(),

        // Latency
        if (result.hasLatency) ...[
          _LatencyCard(latencyMs: result.latencyMs!, colorScheme: colorScheme),
          AppGap.lg(),
        ],

        // Download & Upload
        Row(
          children: [
            Expanded(
              child: _SpeedCard(
                label: loc(context).download,
                icon: Icons.download,
                speedMbps: result.downloadMbps,
                status: result.downloadStatus ?? loc(context).unknownError,
                color: colorScheme.primary,
                colorScheme: colorScheme,
              ),
            ),
            AppGap.md(),
            Expanded(
              child: _SpeedCard(
                label: loc(context).upload,
                icon: Icons.upload,
                speedMbps: result.uploadMbps,
                status: result.uploadStatus ?? loc(context).notRun,
                color: colorScheme.tertiary,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        AppGap.xl(),

        // Details
        if (result.downloadDurationMs != null &&
            result.downloadDurationMs! > 0) ...[
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).details),
                AppGap.md(),
                _DetailRow(
                  label: loc(context).downloaded,
                  value: _formatBytes(result.downloadBytes ?? 0),
                ),
                AppGap.xs(),
                _DetailRow(
                  label: loc(context).duration,
                  value:
                      '${(result.downloadDurationMs! / 1000).toStringAsFixed(1)}s',
                ),
              ],
            ),
          ),
          AppGap.xl(),
        ],

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton(
              label: loc(context).testAgain,
              onTap: () => ref.read(speedTestProvider.notifier).runSpeedTest(),
            ),
            AppGap.lg(),
            AppButton.text(
              label: loc(context).done,
              onTap: () => context.goNamed(RouteNamed.uspMenu),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(
      BuildContext context, WidgetRef ref, SpeedTestState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium(loc(context).speedTestFailed),
          AppGap.md(),
          if (state.error != null)
            AppText.bodyMedium(
              localizeServiceError(context, state.error!),
              textAlign: TextAlign.center,
              color: colorScheme.onSurfaceVariant,
            ),
          AppGap.xxxl(),
          AppButton(
            label: loc(context).tryAgain,
            onTap: () => ref.read(speedTestProvider.notifier).runSpeedTest(),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ---------------------------------------------------------------------------
  // Server Selection Dialog
  // ---------------------------------------------------------------------------

  void _showServerSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    SpeedTestServer currentServer,
  ) async {
    final selected = await showListSelectionDialog<SpeedTestServer>(
      context: context,
      title: loc(context).selectTestServer,
      items: SpeedTestServer.all,
      itemLabel: (server) => server.name,
      currentValue: currentServer,
      itemIcon: Icons.dns,
    );
    if (selected != null) {
      ref.read(speedTestProvider.notifier).selectServer(selected);
    }
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          AppGap.sm(),
          AppText.bodySmall('$label: ', color: colorScheme.onSurfaceVariant),
          AppText.bodySmall(value),
        ],
      ),
    );
  }
}

class _LatencyCard extends StatelessWidget {
  final int latencyMs;
  final ColorScheme colorScheme;

  const _LatencyCard({
    required this.latencyMs,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final quality = latencyMs < 20
        ? loc(context).excellent
        : latencyMs < 50
            ? loc(context).good
            : latencyMs < 100
                ? loc(context).fair
                : loc(context).poor;
    final qualityColor = latencyMs < 50
        ? colorScheme.primary
        : latencyMs < 100
            ? colorScheme.tertiary
            : colorScheme.error;

    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.network_ping, color: qualityColor),
          ),
          AppGap.lg(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(loc(context).latency,
                  color: colorScheme.onSurfaceVariant),
              Row(
                children: [
                  AppText.headlineSmall('$latencyMs'),
                  AppGap.xs(),
                  AppText.bodyMedium('ms'),
                  AppGap.md(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: AppText.labelSmall(quality, color: qualityColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double speedMbps;
  final String status;
  final Color color;
  final ColorScheme colorScheme;

  const _SpeedCard({
    required this.label,
    required this.icon,
    required this.speedMbps,
    required this.status,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = status == 'Complete';
    final isNotSupported = status == 'NotSupported';

    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          AppGap.md(),
          if (isComplete) ...[
            AppText.headlineMedium(
              speedMbps.toStringAsFixed(1),
              color: color,
            ),
            AppText.bodySmall('Mbps'),
          ] else if (isNotSupported) ...[
            AppText.titleMedium('N/A', color: colorScheme.onSurfaceVariant),
            AppText.bodySmall(loc(context).notSupported,
                color: colorScheme.onSurfaceVariant),
          ] else ...[
            AppText.titleMedium('--', color: colorScheme.onSurfaceVariant),
            AppText.bodySmall(status, color: colorScheme.onSurfaceVariant),
          ],
          AppGap.sm(),
          AppText.labelMedium(label),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodySmall(label, color: colorScheme.onSurfaceVariant),
        AppText.bodySmall(value),
      ],
    );
  }
}

/// Button that shows selected server and opens selection dialog
class _ServerSelectionButton extends StatelessWidget {
  final SpeedTestServer selectedServer;
  final VoidCallback onTap;

  const _ServerSelectionButton({
    required this.selectedServer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.dns, size: 20, color: colorScheme.onSurfaceVariant),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelSmall(
                      loc(context).testServer,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    AppGap.xs(),
                    AppText.bodyMedium(selectedServer.name),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
