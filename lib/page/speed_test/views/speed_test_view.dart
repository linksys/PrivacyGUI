import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';
import 'package:privacy_gui/page/speed_test/providers/speed_test_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SpeedTestView extends ConsumerWidget {
  const SpeedTestView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(speedTestProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Speed Test',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => _buildPageError(context, ref, error),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  Widget _buildPageError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load speed test'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(speedTestProvider),
          ),
        ],
      ),
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
          AppText.headlineSmall('Internet Speed Test'),
          AppGap.md(),
          AppText.bodyMedium(
            'Test your connection speed from the router',
            textAlign: TextAlign.center,
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.xl(),
          // Server selection button
          _ServerSelectionButton(
            selectedServer: selectedServer,
            onTap: () => _showServerSelectionDialog(context, ref, selectedServer),
          ),
          AppGap.xxxl(),
          SizedBox(
            width: 200,
            child: AppButton.primary(
              label: 'Start Test',
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
    final stepLabel = _getStepLabel(state.step);
    final isSpeedTest = state.step == SpeedTestStep.testingDownload ||
        state.step == SpeedTestStep.testingUpload;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show gauge during speed test, otherwise show progress circle
          if (isSpeedTest)
            _SpeedTestGauge(
              value: 0,
              isAnimating: true,
              label: state.step == SpeedTestStep.testingDownload
                  ? 'Download'
                  : 'Upload',
              colorScheme: colorScheme,
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
            label: 'Cancel',
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
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
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
            label: 'Server',
            value: result.serverHost!,
            colorScheme: colorScheme,
          ),
        if (result.hasLatency)
          _ResultRow(
            icon: Icons.network_ping,
            label: 'Latency',
            value: '${result.latencyMs} ms',
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  String _getStepLabel(SpeedTestStep step) {
    return switch (step) {
      SpeedTestStep.testingLatency => 'Testing Latency',
      SpeedTestStep.testingDownload => 'Testing Download',
      SpeedTestStep.testingUpload => 'Testing Upload',
      _ => 'Running...',
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
                    ? Colors.green
                    : colorScheme.tertiary,
              ),
              AppGap.md(),
              AppText.headlineSmall('Speed Test Complete'),
              if (result.serverHost != null) ...[
                AppGap.xs(),
                AppText.bodySmall(
                  'Server: ${result.serverHost}',
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
                label: 'Download',
                icon: Icons.download,
                speedMbps: result.downloadMbps,
                status: result.downloadStatus ?? 'Unknown',
                color: colorScheme.primary,
                colorScheme: colorScheme,
              ),
            ),
            AppGap.md(),
            Expanded(
              child: _SpeedCard(
                label: 'Upload',
                icon: Icons.upload,
                speedMbps: result.uploadMbps,
                status: result.uploadStatus ?? 'Not run',
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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge('Details'),
                AppGap.md(),
                _DetailRow(
                  label: 'Downloaded',
                  value: _formatBytes(result.downloadBytes ?? 0),
                ),
                AppGap.xs(),
                _DetailRow(
                  label: 'Duration',
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
              label: 'Test Again',
              onTap: () => ref.read(speedTestProvider.notifier).runSpeedTest(),
            ),
            AppGap.lg(),
            AppButton.text(
              label: 'Done',
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
          AppText.titleMedium('Speed Test Failed'),
          AppGap.md(),
          if (state.errorMessage != null)
            AppText.bodyMedium(
              state.errorMessage!,
              textAlign: TextAlign.center,
              color: colorScheme.onSurfaceVariant,
            ),
          AppGap.xxxl(),
          AppButton(
            label: 'Try Again',
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
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ServerSelectionDialog(
        currentServer: currentServer,
        onSelected: (server) {
          ref.read(speedTestProvider.notifier).selectServer(server);
          Navigator.of(dialogContext).pop();
        },
      ),
    );
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
        ? 'Excellent'
        : latencyMs < 50
            ? 'Good'
            : latencyMs < 100
                ? 'Fair'
                : 'Poor';
    final qualityColor = latencyMs < 20
        ? Colors.green
        : latencyMs < 50
            ? colorScheme.primary
            : latencyMs < 100
                ? Colors.orange
                : colorScheme.error;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.network_ping, color: qualityColor),
          ),
          AppGap.lg(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall('Latency',
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
                      borderRadius: BorderRadius.circular(4),
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

    return AppCard(
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
            AppText.bodySmall('Not supported',
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      'Test Server',
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

/// Dialog for selecting speed test server
class _ServerSelectionDialog extends StatelessWidget {
  final SpeedTestServer currentServer;
  final ValueChanged<SpeedTestServer> onSelected;

  const _ServerSelectionDialog({
    required this.currentServer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Select Test Server'),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: SpeedTestServer.all.length,
          itemBuilder: (context, index) {
            final server = SpeedTestServer.all[index];
            final isSelected = server.host == currentServer.host;

            return ListTile(
              leading: Icon(
                Icons.dns,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                server.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () => onSelected(server),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Animated gauge for speed test display with random fluctuation
class _SpeedTestGauge extends StatefulWidget {
  final double value;
  final bool isAnimating;
  final String label;
  final ColorScheme colorScheme;

  const _SpeedTestGauge({
    required this.value,
    required this.isAnimating,
    required this.label,
    required this.colorScheme,
  });

  @override
  State<_SpeedTestGauge> createState() => _SpeedTestGaugeState();
}

class _SpeedTestGaugeState extends State<_SpeedTestGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  double _currentValue = 0;
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addListener(_onTick);

    if (widget.isAnimating) {
      _startRandomAnimation();
    }
  }

  void _startRandomAnimation() {
    _generateNewTarget();
    _controller.forward(from: 0);
  }

  void _generateNewTarget() {
    // Random value between 20-200 Mbps with some clustering around 50-150
    final base = 50 + _random.nextDouble() * 100;
    final noise = (_random.nextDouble() - 0.5) * 60;
    _targetValue = (base + noise).clamp(20, 250);
  }

  void _onTick() {
    if (!mounted) return;

    setState(() {
      // Smooth interpolation towards target
      _currentValue = _currentValue + (_targetValue - _currentValue) * 0.15;
    });

    // When animation completes, generate new target and restart
    if (_controller.isCompleted && widget.isAnimating) {
      _generateNewTarget();
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_SpeedTestGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startRandomAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.isAnimating ? _currentValue : widget.value;

    return AppGauge(
      value: displayValue,
      size: 220,
      markers: const [0, 50, 100, 200, 300, 500],
      centerBuilder: (context, value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.headlineLarge(
            displayValue.toStringAsFixed(1),
            color: widget.colorScheme.primary,
          ),
          AppText.bodyMedium('Mbps'),
          if (widget.isAnimating) ...[
            AppGap.sm(),
            AppText.bodySmall(
              'Testing...',
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
      bottomBuilder: (context, value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppText.labelMedium(widget.label),
      ),
    );
  }
}
