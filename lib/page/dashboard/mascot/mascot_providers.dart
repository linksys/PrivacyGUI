import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/page/_shared/services/usp_pdf_service.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/pdf_report_data_provider.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_dialog_provider.dart';

/// Provider for the mascot controller.
final mascotControllerProvider = Provider.autoDispose<MascotController>((ref) {
  final controller = MascotController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Provider for the mascot dialog provider.
///
/// Depends on localization context, so must be accessed within a widget tree.
final mascotDialogProvider =
    Provider.autoDispose.family<DashboardDialogProvider, BuildContext>(
  (ref, context) {
    final locale = ref.watch(appSettingsProvider.select((s) => s.locale));
    final controller = ref.watch(mascotControllerProvider);

    return DashboardDialogProvider(
      controller: controller,
      onRunFullDiagnostics: () => _runFullDiagnostics(ref),
      onRunFlowDiagnostics: (flow) => _runFlowDiagnostics(ref, flow),
      onPrintReport: () => _printReport(ref),
      onOpenThemeStudio: () => _openThemeStudio(ref),
      getLocale: () => locale,
      getFaqCategoryTitle: (category) => category.displayString(context),
      getFaqItemTitle: (item) => item.displayString(context),
      isThemeStudioEnabled: BuildConfig.enableThemeStudio,
      getRouterTime: () => _getRouterTime(ref),
    );
  },
);

/// Run full diagnostic using the unified diagnostics system.
Future<DiagnosticsResult> _runFullDiagnostics(Ref ref) async {
  final notifier = ref.read(unifiedDiagnosticsProvider.notifier);

  await notifier.runFullDiagnostic();

  return _buildResultFromState(ref);
}

/// Run a specific diagnostic flow.
Future<DiagnosticsResult> _runFlowDiagnostics(
  Ref ref,
  DiagnosticFlow flow,
) async {
  final notifier = ref.read(unifiedDiagnosticsProvider.notifier);

  await notifier.selectFlow(flow);

  return _buildResultFromState(ref);
}

/// Build a simplified result from the diagnostics state.
DiagnosticsResult _buildResultFromState(Ref ref) {
  final state = ref.read(unifiedDiagnosticsProvider);

  final hasErrors = state.results.any((r) => r.isError);
  final hasWarnings = state.results.any((r) => r.isWarning);
  final recommendations = state.recommendations;

  String message;
  bool hasIssues;

  if (hasErrors) {
    hasIssues = true;
    final errorCount = state.results.where((r) => r.isError).length;
    message = 'Found $errorCount issue${errorCount > 1 ? 's' : ''}.';
    if (recommendations.isNotEmpty) {
      message += '\n\nTop recommendation:\n${recommendations.first.titleKey}';
    }
  } else if (hasWarnings) {
    hasIssues = true;
    final warningCount = state.results.where((r) => r.isWarning).length;
    message = 'Found $warningCount warning${warningCount > 1 ? 's' : ''}.';
    if (recommendations.isNotEmpty) {
      message += '\n\nSuggestion:\n${recommendations.first.titleKey}';
    }
  } else {
    hasIssues = false;
    message = 'All checks passed!';

    // Add speed test results if available
    final speedTest = state.speedTest;
    if (speedTest != null) {
      message +=
          '\n\nDownload: ${speedTest.downloadMbps.toStringAsFixed(1)} Mbps';
      if (speedTest.hasUpload) {
        message += '\nUpload: ${speedTest.uploadMbps.toStringAsFixed(1)} Mbps';
      }
    }
  }

  // Reset diagnostics state for next run
  ref.read(unifiedDiagnosticsProvider.notifier).cancel();

  return DiagnosticsResult(
    message: message,
    hasIssues: hasIssues,
  );
}

/// Generate and open PDF report.
Future<void> _printReport(Ref ref) async {
  final reportData = ref.read(pdfReportDataProvider);
  if (reportData == null) return;
  await UspPdfService.generatePdf(reportData);
}

/// Toggle the Theme Studio panel.
void _openThemeStudio(Ref ref) {
  ref.read(demoUIProvider.notifier).toggleThemePanel();
}

/// Get router's current local time for greeting.
DateTime? _getRouterTime(Ref ref) {
  final timeData = ref.read(timeDataProvider).valueOrNull;
  return timeData?.model.parsedLocalTime;
}

/// Provider for random mascot speech timer.
///
/// Periodically shows random messages when mascot is idle.
final mascotRandomSpeechProvider =
    NotifierProvider.autoDispose<MascotRandomSpeechNotifier, void>(
  MascotRandomSpeechNotifier.new,
);

class MascotRandomSpeechNotifier extends AutoDisposeNotifier<void> {
  Timer? _timer;
  final _random = Random();
  MascotController? _controller;
  VoidCallback? _listener;
  bool _isRunning = false;

  static const _minInterval = Duration(seconds: 10);
  static const _maxInterval = Duration(seconds: 30);
  static const _autoHideDuration = Duration(seconds: 5);

  static const _randomMessages = [
    'Everything looks good!',
    'Your network is running smoothly.',
    'All devices connected!',
    'WiFi signal is strong.',
    'No issues detected.',
    'Tap me if you need help!',
    'Need to run diagnostics?',
    'I\'m here if you need me!',
    'Network health: excellent!',
    'All systems operational.',
  ];

  @override
  void build() {
    ref.onDispose(_cleanup);
  }

  void start(MascotController controller) {
    if (_isRunning && _controller == controller) return;

    _cleanup();
    _controller = controller;
    _isRunning = true;

    _listener = () => _onControllerChanged(controller);
    controller.addListener(_listener!);

    _scheduleNext(controller);
  }

  void stop() {
    _cleanup();
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    if (_controller != null && _listener != null) {
      _controller!.removeListener(_listener!);
    }
    _controller = null;
    _listener = null;
  }

  void _onControllerChanged(MascotController controller) {
    if (controller.state == MascotState.interacting) {
      _timer?.cancel();
      _timer = null;
    } else if (controller.state == MascotState.idle &&
        _timer == null &&
        _isRunning) {
      _scheduleNext(controller);
    }
  }

  void _scheduleNext(MascotController controller) {
    if (!_isRunning) return;
    _timer?.cancel();
    final intervalRange =
        _maxInterval.inMilliseconds - _minInterval.inMilliseconds;
    final nextInterval =
        _minInterval.inMilliseconds + _random.nextInt(intervalRange);

    _timer = Timer(Duration(milliseconds: nextInterval), () {
      _showRandomMessage(controller);
      _scheduleNext(controller);
    });
  }

  void _showRandomMessage(MascotController controller) {
    if (!_isRunning) return;
    if (!controller.isVisible) return;
    if (controller.isDialogVisible) return;
    if (controller.state == MascotState.interacting) return;

    final message = _randomMessages[_random.nextInt(_randomMessages.length)];

    controller.showDialog(MascotDialogNode(
      id: 'random_speech',
      text: message,
      autoHide: true,
      autoHideDuration: _autoHideDuration,
    ));
  }
}
