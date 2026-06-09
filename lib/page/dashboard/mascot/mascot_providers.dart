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
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/ai_assistant/views/router_assistant_view.dart';

import 'dashboard_dialog_provider.dart';
import 'mascot_hero_widget.dart';

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
      onOpenAiAssistant: () => _openAiAssistant(context),
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

/// Navigate to AI Assistant page with mascot fly-in animation.
void _openAiAssistant(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;

  // Mascot's starting position (bottom-right, where the overlay typically is)
  const mascotSize = 80.0;
  final startPosition = Offset(
    screenSize.width - mascotSize - 24,
    screenSize.height - mascotSize * 1.375 - 100,
  );

  Navigator.of(context).push(
    PageRouteBuilder(
      settings: const RouteSettings(name: RouteNamed.uspAiAssistant),
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const RouterAssistantView();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in the page content
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        );

        // Mascot flies from its original position to center
        final mascotAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        final endPosition = Offset(
          screenSize.width / 2 - mascotSize / 2,
          screenSize.height / 3 - mascotSize / 2,
        );

        final currentPosition = Offset.lerp(
          startPosition,
          endPosition,
          mascotAnimation.value,
        )!;

        return Stack(
          children: [
            // Page content fades in
            FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
            // Mascot flies and fades out
            if (animation.value < 0.9)
              Positioned(
                left: currentPosition.dx,
                top: currentPosition.dy,
                child: Opacity(
                  opacity: (1.0 - animation.value).clamp(0.0, 1.0),
                  child: const MascotHeroWidget(
                    size: mascotSize,
                    animation: MascotAnimationKey.greet,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Get router's current local time for greeting.
DateTime? _getRouterTime(Ref ref) {
  final timeData = ref.read(timeDataProvider).valueOrNull;
  return timeData?.model.parsedLocalTime;
}

/// Coordinator for mascot behaviors.
///
/// Manages random speech timer based on app settings and dashboard state.
/// Watch this provider in the shell to activate mascot behaviors.
final mascotCoordinatorProvider =
    NotifierProvider.autoDispose<MascotCoordinatorNotifier, void>(
  MascotCoordinatorNotifier.new,
);

class MascotCoordinatorNotifier extends AutoDisposeNotifier<void> {
  Timer? _timer;
  final _random = Random();
  VoidCallback? _controllerListener;

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
    final showMascot =
        ref.watch(appSettingsProvider.select((s) => s.showMascot));
    final isDashboardReady = ref.watch(dashboardDomainReadyProvider).hasValue;
    final controller = ref.watch(mascotControllerProvider);

    ref.onDispose(() => _cleanup(controller));

    if (showMascot && isDashboardReady) {
      _startRandomSpeech(controller);
    }
  }

  void _startRandomSpeech(MascotController controller) {
    _controllerListener = () => _onControllerChanged(controller);
    controller.addListener(_controllerListener!);
    _scheduleNext(controller);
  }

  void _cleanup(MascotController controller) {
    _timer?.cancel();
    _timer = null;
    if (_controllerListener != null) {
      controller.removeListener(_controllerListener!);
      _controllerListener = null;
    }
  }

  void _onControllerChanged(MascotController controller) {
    if (controller.state == MascotState.interacting) {
      _timer?.cancel();
      _timer = null;
    } else if (controller.state == MascotState.idle && _timer == null) {
      _scheduleNext(controller);
    }
  }

  void _scheduleNext(MascotController controller) {
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
    if (!controller.isVisible) return;
    if (controller.isDialogVisible) return;
    if (controller.state == MascotState.interacting) return;

    final message = _randomMessages[_random.nextInt(_randomMessages.length)];

    controller.showDialog(MascotDialogNode(
      id: 'random_speech',
      text: message,
      autoHide: true,
      autoHideDuration: _autoHideDuration,
      showDismissButton: false,
    ));
  }
}
