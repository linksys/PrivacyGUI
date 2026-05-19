import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';
import 'package:privacy_gui/page/speed_test/providers/speed_test_notifier.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/diagnostic_result.dart';
import '../models/diagnostic_state.dart';
import '../providers/unified_diagnostics_notifier.dart';

class UnifiedDiagnosticsView extends ConsumerWidget {
  const UnifiedDiagnosticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedDiagnosticsProvider);

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: 'Network Diagnostics',
      scrollable: true,
      onBackTap: () => _handleBack(context, ref, state),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _buildContent(context, ref, state),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    return switch (state.step) {
      DiagnosticStep.idle => _buildStart(context, ref),
      DiagnosticStep.selectProblem => _buildProblemSelector(context, ref),
      DiagnosticStep.showingResults => _buildResults(context, ref, state),
      DiagnosticStep.completed => _buildCompleted(context, ref),
      _ => _buildRunning(context, ref, state),
    };
  }

  Widget _buildStart(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.network_check,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.xl(),
          AppText.headlineSmall(
            'Network Diagnostics',
            textAlign: TextAlign.center,
          ),
          AppGap.md(),
          AppText.bodyMedium(
            'Run diagnostics to identify and fix network issues.',
            textAlign: TextAlign.center,
          ),
          AppGap.xxxl(),
          AppButton(
            label: 'Start Diagnostics',
            onTap: () => ref.read(unifiedDiagnosticsProvider.notifier).start(),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSelector(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.headlineSmall('What issue are you experiencing?'),
        AppGap.xl(),

        // Option 1: No Internet
        _ProblemCard(
          icon: Icons.wifi_off,
          title: 'No Internet Connection',
          description:
              'Unable to connect to the internet. Pages won\'t load and apps can\'t connect.',
          color: colorScheme.error,
          onTap: () => notifier.selectProblem(ProblemType.noInternet),
        ),
        AppGap.lg(),

        // Option 2: Slow Network
        _ProblemCard(
          icon: Icons.speed,
          title: 'Slow Network',
          description:
              'Internet is connected but experiencing slow speeds or poor performance.',
          color: colorScheme.tertiary,
          onTap: () => notifier.selectProblem(ProblemType.slowNetwork),
        ),
        AppGap.xxxl(),

        Center(
          child: AppButton.text(
            label: 'Cancel',
            onTap: () => notifier.cancel(),
          ),
        ),
      ],
    );
  }

  Widget _buildRunning(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final stepLabel = _getStepLabel(state.step);
    final completedSteps = state.results.length;
    final totalSteps = state.isNoInternetFlow ? 5 : 4;

    // Get speed test progress message if running speed test
    String? progressDetail;
    if (state.step == DiagnosticStep.runningSpeedTest) {
      final speedState = ref.watch(speedTestProvider).valueOrNull;
      progressDetail = speedState?.progressMessage;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress header
        Row(
          children: [
            Icon(
              state.isNoInternetFlow ? Icons.wifi_off : Icons.speed,
              color: colorScheme.primary,
            ),
            AppGap.md(),
            Expanded(
              child: AppText.titleMedium(
                state.isNoInternetFlow
                    ? 'No Internet Diagnostics'
                    : 'Slow Network Diagnostics',
              ),
            ),
          ],
        ),
        AppGap.lg(),

        // Progress indicator
        LinearProgressIndicator(
          value: completedSteps / totalSteps,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
        AppGap.sm(),
        AppText.bodySmall(
          'Step ${completedSteps + 1} of $totalSteps',
          color: colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),

        // Current step
        Center(
          child: Column(
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: AppLoader(),
              ),
              AppGap.lg(),
              AppText.titleSmall(stepLabel),
              AppGap.sm(),
              AppText.bodySmall(
                progressDetail ?? 'Please wait...',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        AppGap.xxxl(),

        // Completed steps
        if (state.results.isNotEmpty) ...[
          AppText.labelLarge('Completed Steps'),
          AppGap.md(),
          ...state.results.map((r) => _StepResultTile(result: r)),
        ],

        AppGap.xxxl(),
        Center(
          child: AppButton.text(
            label: 'Cancel',
            onTap: () => ref.read(unifiedDiagnosticsProvider.notifier).cancel(),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasErrors =
        state.results.any((r) => r.severity == DiagnosticSeverity.error);
    final hasWarnings =
        state.results.any((r) => r.severity == DiagnosticSeverity.warning);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary header
        Center(
          child: Column(
            children: [
              Icon(
                hasErrors
                    ? Icons.error
                    : hasWarnings
                        ? Icons.warning
                        : Icons.check_circle,
                size: 64,
                color: hasErrors
                    ? colorScheme.error
                    : hasWarnings
                        ? colorScheme.tertiary
                        : colorScheme.primary,
              ),
              AppGap.md(),
              AppText.headlineSmall(
                hasErrors
                    ? 'Issues Found'
                    : hasWarnings
                        ? 'Potential Issues Found'
                        : 'No Issues Found',
              ),
            ],
          ),
        ),
        AppGap.xl(),

        // Speed test results (if available)
        if (state.speedTest != null) ...[
          _SpeedTestResultCard(speedTest: state.speedTest!),
          AppGap.lg(),
        ],

        // Diagnostic results
        AppText.labelLarge('Diagnostic Results'),
        AppGap.md(),
        ...state.results.map((r) => _StepResultTile(result: r)),

        // Traceroute details (if available)
        ...state.results
            .whereType<TracerouteCheckResult>()
            .map((r) => _TracerouteDetailCard(result: r)),
        AppGap.xl(),

        // Recommendations
        if (state.recommendations.isNotEmpty) ...[
          AppText.labelLarge('Recommendations'),
          AppGap.md(),
          ...state.recommendations.map((r) => _RecommendationCard(rec: r)),
          AppGap.xl(),
        ],

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton(
              label: 'Run Again',
              onTap: () =>
                  ref.read(unifiedDiagnosticsProvider.notifier).restart(),
            ),
            AppGap.lg(),
            AppButton.text(
              label: 'Done',
              onTap: () => _returnToDashboard(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.xl(),
          AppText.headlineSmall('Diagnostics Complete'),
          AppGap.xxxl(),
          AppButton(
            label: 'Return to Dashboard',
            onTap: () => _returnToDashboard(context, ref),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => 'Checking WAN Status...',
      DiagnosticStep.checkingDhcp => 'Checking DHCP...',
      DiagnosticStep.pingGateway => 'Pinging Gateway...',
      DiagnosticStep.pingDns => 'Pinging DNS Servers...',
      DiagnosticStep.pingInternet => 'Checking Internet Connectivity...',
      DiagnosticStep.runningSpeedTest => 'Running Speed Test...',
      DiagnosticStep.checkingWifiSignal => 'Checking WiFi Signal...',
      DiagnosticStep.checkingConnectedDevices =>
        'Checking Connected Devices...',
      DiagnosticStep.runningTraceroute => 'Running Traceroute...',
      DiagnosticStep.analyzing => 'Analyzing Results...',
      _ => 'Running...',
    };
  }

  void _handleBack(
    BuildContext context,
    WidgetRef ref,
    UnifiedDiagnosticsState state,
  ) {
    if (state.isRunning) {
      ref.read(unifiedDiagnosticsProvider.notifier).cancel();
    }
    _returnToDashboard(context, ref);
  }

  void _returnToDashboard(BuildContext context, WidgetRef ref) {
    ref.read(unifiedDiagnosticsProvider.notifier).cancel();
    context.goNamed(RouteNamed.uspDashboard);
  }
}

class _ProblemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ProblemCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              AppGap.lg(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(title),
                    AppGap.xs(),
                    AppText.bodySmall(description),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepResultTile extends StatelessWidget {
  final DiagnosticStepResult result;

  const _StepResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (result.severity) {
      DiagnosticSeverity.ok => (Icons.check_circle, colorScheme.primary),
      DiagnosticSeverity.warning => (Icons.warning, colorScheme.tertiary),
      DiagnosticSeverity.error => (Icons.error, colorScheme.error),
      DiagnosticSeverity.skipped => (
          Icons.skip_next,
          colorScheme.onSurfaceVariant
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          AppGap.md(),
          Expanded(
            child: AppText.bodyMedium(
              _getStepTitle(result.step),
            ),
          ),
          AppText.bodySmall(
            _getDetailText(result),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _getStepTitle(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => 'WAN Status',
      DiagnosticStep.checkingDhcp => 'DHCP',
      DiagnosticStep.pingGateway => 'Gateway Ping',
      DiagnosticStep.pingDns => 'DNS Ping',
      DiagnosticStep.pingInternet => 'Internet Connectivity',
      DiagnosticStep.runningSpeedTest => 'Speed Test',
      DiagnosticStep.checkingWifiSignal => 'WiFi Signal',
      DiagnosticStep.checkingConnectedDevices => 'Connected Devices',
      DiagnosticStep.runningTraceroute => 'Traceroute',
      _ => step.name,
    };
  }

  String _getDetailText(DiagnosticStepResult result) {
    final data = result.rawData;

    return switch (result) {
      WanStatusCheckResult r => r.isUp
          ? r.ipAddress.isNotEmpty
              ? r.ipAddress
              : 'Up (no IP)'
          : 'Down',
      PingCheckResult r => r.allFailed
          ? 'Failed'
          : '${r.avgResponseTime}ms (${r.successCount}/${r.totalCount})',
      WifiSignalCheckResult r => 'Ch ${r.channel} (${r.band})',
      ConnectedDevicesCheckResult r =>
        '${r.activeDevices}/${r.totalDevices} active',
      _ when result.step == DiagnosticStep.runningSpeedTest =>
        data.containsKey('downloadMbps')
            ? '${(data['downloadMbps'] as double).toStringAsFixed(1)} Mbps'
            : '',
      _ when result.step == DiagnosticStep.runningTraceroute =>
        data.containsKey('hopCount') ? '${data['hopCount']} hops' : '',
      _ when result.step == DiagnosticStep.checkingDhcp => result.isOk
          ? 'OK'
          : result.isSkipped
              ? 'Static IP'
              : 'Failed',
      _ => '',
    };
  }
}

class _SpeedTestResultCard extends StatelessWidget {
  final SpeedTestResult speedTest;

  const _SpeedTestResultCard({required this.speedTest});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloadMbps = speedTest.downloadMbps;
    final uploadMbps = speedTest.uploadMbps;
    final uploadSupported = speedTest.hasUpload;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppText.labelLarge('Speed Test Results'),
                const Spacer(),
                if (speedTest.hasLatency)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.network_ping,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      AppText.bodySmall(
                        '${speedTest.latencyMs} ms',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
              ],
            ),
            AppGap.lg(),
            Row(
              children: [
                Expanded(
                  child: _SpeedGauge(
                    label: 'Download',
                    value: downloadMbps,
                    icon: Icons.download,
                    color: colorScheme.primary,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: uploadSupported
                      ? _SpeedGauge(
                          label: 'Upload',
                          value: uploadMbps,
                          icon: Icons.upload,
                          color: colorScheme.tertiary,
                        )
                      : Column(
                          children: [
                            Icon(
                              Icons.upload,
                              color: colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            AppGap.sm(),
                            AppText.bodySmall(
                              'N/A',
                              color: colorScheme.onSurfaceVariant,
                            ),
                            AppGap.xs(),
                            AppText.labelSmall('Upload'),
                          ],
                        ),
                ),
              ],
            ),
            if (!uploadSupported) ...[
              AppGap.md(),
              AppText.bodySmall(
                'Upload test not supported on this firmware.',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeedGauge extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SpeedGauge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        AppGap.sm(),
        AppText.headlineSmall(
          value.toStringAsFixed(1),
          color: color,
        ),
        AppText.bodySmall('Mbps'),
        AppGap.xs(),
        AppText.labelSmall(label),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;

  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colorScheme.tertiary,
                size: 24,
              ),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(_getRecTitle(rec.titleKey)),
                    AppGap.xs(),
                    AppText.bodySmall(_getRecDescription(rec.descriptionKey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecTitle(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_title' => 'WAN Connection Down',
      'diagnostics_rec_no_ip_title' => 'No IP Address',
      'diagnostics_rec_dhcp_fail_title' => 'DHCP Failed',
      'diagnostics_rec_gateway_title' => 'Gateway Unreachable',
      'diagnostics_rec_dns_fail_title' => 'DNS Not Responding',
      'diagnostics_rec_internet_title' => 'Internet Unreachable',
      'diagnostics_rec_slow_download_title' => 'Slow Download Speed',
      'diagnostics_rec_slow_upload_title' => 'Slow Upload Speed',
      'diagnostics_rec_weak_wifi_title' => 'Weak WiFi Signal',
      'diagnostics_rec_many_devices_title' => 'Too Many Devices',
      'diagnostics_rec_bandwidth_hog_title' => 'High Bandwidth Devices',
      'diagnostics_rec_bottleneck_title' => 'Network Bottleneck Detected',
      _ => key,
    };
  }

  String _getRecDescription(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_desc' =>
        'Check your modem connection and restart if needed.',
      'diagnostics_rec_no_ip_desc' =>
        'Try renewing DHCP lease or configure static IP.',
      'diagnostics_rec_dhcp_fail_desc' =>
        'Renew DHCP lease or check ISP settings.',
      'diagnostics_rec_gateway_desc' =>
        'Check cable connections between router and modem.',
      'diagnostics_rec_dns_fail_desc' =>
        'Try using alternate DNS servers like 8.8.8.8.',
      'diagnostics_rec_internet_desc' =>
        'Contact your ISP — the issue may be on their end.',
      'diagnostics_rec_slow_download_desc' =>
        'Contact your ISP about download speed issues.',
      'diagnostics_rec_slow_upload_desc' =>
        'Check for devices uploading large files.',
      'diagnostics_rec_weak_wifi_desc' =>
        'Move closer to router or add a mesh node.',
      'diagnostics_rec_many_devices_desc' =>
        'Consider enabling QoS or disconnecting unused devices.',
      'diagnostics_rec_bandwidth_hog_desc' =>
        'Some devices are using a lot of bandwidth.',
      'diagnostics_rec_bottleneck_desc' =>
        'Network latency detected at a specific hop.',
      _ => key,
    };
  }
}

class _TracerouteDetailCard extends StatelessWidget {
  final TracerouteCheckResult result;

  const _TracerouteDetailCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hops = result.hops;

    if (hops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, size: 20, color: colorScheme.primary),
                  AppGap.sm(),
                  AppText.labelLarge('Traceroute to ${result.targetHost}'),
                ],
              ),
              AppGap.md(),
              // Header row
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: AppText.labelSmall('#',
                        color: colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    flex: 2,
                    child: AppText.labelSmall('Host',
                        color: colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(
                    width: 80,
                    child: AppText.labelSmall('RTT',
                        color: colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Hop rows
              ...hops.map((hop) => _buildHopRow(context, hop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHopRow(BuildContext context, TracerouteHopInfo hop) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSlow = hop.isSlow;
    final isUnreachable = hop.isUnreachable;

    final textColor = isSlow
        ? colorScheme.error
        : isUnreachable
            ? colorScheme.onSurfaceVariant
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: AppText.bodySmall(
              '${hop.hopNumber}',
              color: textColor,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  hop.host.isNotEmpty
                      ? hop.host
                      : (hop.hostAddress.isNotEmpty ? hop.hostAddress : '*'),
                  color: textColor,
                ),
                if (hop.host.isNotEmpty && hop.hostAddress.isNotEmpty)
                  AppText.labelSmall(
                    hop.hostAddress,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSlow)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.warning, size: 14, color: colorScheme.error),
                  ),
                AppText.bodySmall(
                  isUnreachable ? '*' : '${hop.avgRoundTrip} ms',
                  color: textColor,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
