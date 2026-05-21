import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Speed Test dashboard card — run speed test directly or view results.
///
/// Shares state with [SpeedTestView] via [speedTestProvider].
class UspSpeedTestCard extends ConsumerWidget {
  const UspSpeedTestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(speedTestProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: asyncState.when(
        loading: () => const Center(child: AppLoader()),
        error: (_, __) => _buildError(context, ref),
        data: (state) => _buildContent(context, ref, state, colorScheme),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 32, color: Theme.of(context).colorScheme.error),
          AppGap.sm(),
          AppText.bodySmall('Error loading speed test'),
          AppGap.md(),
          AppButton.text(
            label: 'Retry',
            onTap: () => ref.invalidate(speedTestProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SpeedTestState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            AppIcon.font(Icons.speed, size: 20, color: colorScheme.primary),
            AppGap.sm(),
            AppText.titleMedium('Speed Test'),
            const Spacer(),
            // Navigate to full page
            AppIconButton(
              icon: AppIcon.font(Icons.open_in_new,
                  size: 16, color: colorScheme.onSurfaceVariant),
              onTap: () => context.goNamed(RouteNamed.uspSpeedTest),
            ),
          ],
        ),
        AppGap.sm(),
        Expanded(
          child: _buildBody(context, ref, state, colorScheme),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    SpeedTestState state,
    ColorScheme colorScheme,
  ) {
    if (state.isRunning) {
      return _CardSpeedGauge(state: state, colorScheme: colorScheme);
    }

    if (state.hasResult) {
      return _buildResult(context, ref, state, colorScheme);
    }

    if (state.step == SpeedTestStep.error) {
      return _buildErrorState(context, ref, state, colorScheme);
    }

    return _buildIdle(context, ref, state, colorScheme);
  }

  Widget _buildIdle(
    BuildContext context,
    WidgetRef ref,
    SpeedTestState state,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Server selector button
          _ServerButton(
            server: state.selectedServer,
            colorScheme: colorScheme,
            onTap: () => _showServerDialog(context, ref, state.selectedServer),
          ),
          AppGap.lg(),
          // Start button
          SizedBox(
            width: 100,
            height: 100,
            child: Material(
              color: colorScheme.primaryContainer,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    ref.read(speedTestProvider.notifier).runSpeedTest(),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 36, color: colorScheme.primary),
                      AppText.labelSmall('START'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    SpeedTestState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon.font(Icons.error_outline, size: 32, color: colorScheme.error),
        AppGap.sm(),
        AppText.bodySmall(
          state.errorMessage ?? 'Test failed',
          textAlign: TextAlign.center,
          color: colorScheme.onSurfaceVariant,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        AppGap.md(),
        AppButton.text(
          label: 'Try Again',
          onTap: () => ref.read(speedTestProvider.notifier).runSpeedTest(),
        ),
      ],
    );
  }

  Widget _buildResult(
    BuildContext context,
    WidgetRef ref,
    SpeedTestState state,
    ColorScheme colorScheme,
  ) {
    final result = state.result!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpeedMetric(
                icon: Icons.download,
                label: 'Download',
                value: result.isDownloadComplete
                    ? result.downloadMbps.toStringAsFixed(1)
                    : '--',
                unit: 'Mbps',
                color: colorScheme.primary,
              ),
              _SpeedMetric(
                icon: Icons.upload,
                label: 'Upload',
                value: result.hasUpload && result.isUploadComplete
                    ? result.uploadMbps.toStringAsFixed(1)
                    : 'N/A',
                unit: result.hasUpload ? 'Mbps' : '',
                color: colorScheme.tertiary,
              ),
            ],
          ),
          AppGap.md(),
          // Latency
          if (result.hasLatency)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon.font(Icons.network_ping,
                    size: 14, color: colorScheme.onSurfaceVariant),
                AppGap.xs(),
                AppText.bodySmall(
                  '${result.latencyMs} ms',
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          AppGap.lg(),
          // Server selector + Test again
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ServerButton(
                server: state.selectedServer,
                colorScheme: colorScheme,
                compact: true,
                onTap: () =>
                    _showServerDialog(context, ref, state.selectedServer),
              ),
              AppGap.md(),
              AppButton(
                label: 'Test Again',
                onTap: () =>
                    ref.read(speedTestProvider.notifier).runSpeedTest(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Speed Gauge for Card (compact version with random animation)
// =============================================================================

class _CardSpeedGauge extends StatefulWidget {
  final SpeedTestState state;
  final ColorScheme colorScheme;

  const _CardSpeedGauge({
    required this.state,
    required this.colorScheme,
  });

  @override
  State<_CardSpeedGauge> createState() => _CardSpeedGaugeState();
}

class _CardSpeedGaugeState extends State<_CardSpeedGauge>
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

    if (_isSpeedTest) {
      _startRandomAnimation();
    }
  }

  bool get _isSpeedTest =>
      widget.state.step == SpeedTestStep.testingDownload ||
      widget.state.step == SpeedTestStep.testingUpload;

  void _startRandomAnimation() {
    _generateNewTarget();
    _controller.forward(from: 0);
  }

  void _generateNewTarget() {
    final base = 50 + _random.nextDouble() * 100;
    final noise = (_random.nextDouble() - 0.5) * 60;
    _targetValue = (base + noise).clamp(20, 250);
  }

  void _onTick() {
    if (!mounted) return;

    setState(() {
      _currentValue = _currentValue + (_targetValue - _currentValue) * 0.15;
    });

    if (_controller.isCompleted && _isSpeedTest) {
      _generateNewTarget();
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_CardSpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSpeedTest =
        oldWidget.state.step == SpeedTestStep.testingDownload ||
            oldWidget.state.step == SpeedTestStep.testingUpload;

    if (_isSpeedTest && !wasSpeedTest) {
      _startRandomAnimation();
    } else if (!_isSpeedTest && wasSpeedTest) {
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
    final stepLabel = switch (widget.state.step) {
      SpeedTestStep.testingLatency => 'Latency',
      SpeedTestStep.testingDownload => 'Download',
      SpeedTestStep.testingUpload => 'Upload',
      _ => 'Testing',
    };

    if (_isSpeedTest) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGauge(
              value: _currentValue,
              size: 200,
              markers: const [0, 50, 100, 200, 300, 500],
              centerBuilder: (context, value) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.headlineLarge(
                    _currentValue.toStringAsFixed(0),
                    color: widget.colorScheme.primary,
                  ),
                  AppText.bodyMedium('Mbps'),
                ],
              ),
            ),
            AppGap.md(),
            AppText.titleSmall(
              'Testing $stepLabel...',
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    // Latency test - show spinner
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: widget.colorScheme.primary,
            ),
          ),
          AppGap.lg(),
          AppText.titleMedium('Testing $stepLabel...'),
          if (widget.state.result?.latencyMs != null) ...[
            AppGap.sm(),
            AppText.bodyMedium(
              '${widget.state.result!.latencyMs} ms',
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Speed Metric Widget
// =============================================================================

class _SpeedMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SpeedMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        AppGap.xs(),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText.titleLarge(value, color: color),
            if (unit.isNotEmpty) ...[
              AppGap.xs(),
              AppText.bodySmall(unit),
            ],
          ],
        ),
        AppText.labelSmall(
          label,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

// =============================================================================
// Server Selection
// =============================================================================

class _ServerButton extends StatelessWidget {
  final SpeedTestServer server;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool compact;

  const _ServerButton({
    required this.server,
    required this.colorScheme,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dns, size: 16, color: colorScheme.onSurfaceVariant),
              AppGap.sm(),
              AppText.bodyMedium(server.name),
              AppGap.xs(),
              Icon(Icons.arrow_drop_down,
                  size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showServerDialog(
  BuildContext context,
  WidgetRef ref,
  SpeedTestServer currentServer,
) async {
  final selected = await showListSelectionDialog<SpeedTestServer>(
    context: context,
    title: 'Select Test Server',
    items: SpeedTestServer.all,
    itemLabel: (server) => server.name,
    currentValue: currentServer,
    itemIcon: Icons.dns,
  );
  if (selected != null) {
    ref.read(speedTestProvider.notifier).selectServer(selected);
  }
}
