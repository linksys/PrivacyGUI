import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/pdf_report_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/ai_assistant/views/router_assistant_view.dart';

import 'health_dialog_provider.dart';
import 'mascot_config.dart';
import 'mascot_hero_widget.dart';
import 'mascot_message_provider.dart';
import 'triggers/mascot_trigger.dart';
import 'triggers/mascot_trigger_provider.dart';

/// Provider for the mascot controller.
final mascotControllerProvider = Provider.autoDispose<MascotController>((ref) {
  final controller = MascotController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Arguments for creating [HealthDialogProvider].
///
/// Contains callbacks that require [BuildContext], allowing the widget layer
/// to handle navigation and localization while keeping the provider context-free.
class HealthDialogProviderArgs {
  final WidgetRef widgetRef;
  final void Function(String routeName) onNavigate;
  final VoidCallback onOpenAiAssistant;
  final String Function(FaqCategory category) getFaqCategoryTitle;
  final String Function(FaqItem item) getFaqItemTitle;

  const HealthDialogProviderArgs({
    required this.widgetRef,
    required this.onNavigate,
    required this.onOpenAiAssistant,
    required this.getFaqCategoryTitle,
    required this.getFaqItemTitle,
  });
}

/// Provider for the health-based mascot dialog UI.
///
/// Uses word cloud + toolbar layout instead of fixed options.
/// Widget layer provides context-dependent callbacks via [HealthDialogProviderArgs].
final mascotHealthDialogProvider =
    Provider.autoDispose.family<HealthDialogProvider, HealthDialogProviderArgs>(
  (ref, args) {
    final locale = ref.watch(activeLocaleProvider);
    final controller = ref.watch(mascotControllerProvider);

    return HealthDialogProvider(
      ref: args.widgetRef,
      controller: controller,
      onPrintReport: () => _printReport(ref),
      onOpenThemeStudio: () => _openThemeStudio(ref),
      onNavigate: args.onNavigate,
      onOpenAiAssistant: args.onOpenAiAssistant,
      getLocale: () => locale,
      getFaqCategoryTitle: args.getFaqCategoryTitle,
      getFaqItemTitle: args.getFaqItemTitle,
      isThemeStudioEnabled: BuildConfig.enableThemeStudio,
      getRouterTime: () => _getRouterTime(ref),
    );
  },
);

/// Generate and open PDF report.
Future<void> _printReport(Ref ref) async {
  await ref.read(pdfReportProvider).open();
}

/// Toggle the Theme Studio panel.
void _openThemeStudio(Ref ref) {
  ref.read(demoUIProvider.notifier).toggleThemePanel();
}

/// Navigate to AI Assistant page with mascot fly-in animation.
///
/// NOTE: Uses Navigator.push instead of go_router intentionally.
/// The custom PageRouteBuilder enables the mascot fly-in transition
/// which requires dynamic position calculation from MediaQuery.
/// go_router's CustomTransitionPage doesn't easily support this pattern.
void openAiAssistantWithTransition(BuildContext context) {
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

  static const _minInterval = kRandomSpeechMinInterval;
  static const _maxInterval = kRandomSpeechMaxInterval;
  static const _autoHideDuration = kRandomSpeechAutoHide;

  @override
  void build() {
    final showMascot =
        ref.watch(appSettingsProvider.select((s) => s.showMascot));
    final isDashboardReady = ref.watch(dashboardDomainReadyProvider).hasValue;
    final controller = ref.watch(mascotControllerProvider);

    ref.onDispose(() => _cleanup(controller));

    if (showMascot && isDashboardReady) {
      _startRandomSpeech(controller);
      _startTriggerListener(controller);
    }
  }

  void _startTriggerListener(MascotController controller) {
    final triggerNotifier = ref.read(mascotTriggerProvider.notifier);
    triggerNotifier.onTrigger =
        (trigger) => _handleTrigger(controller, trigger);
  }

  void _handleTrigger(MascotController controller, MascotTrigger trigger) {
    if (!controller.isVisible) return;

    // For critical triggers, interrupt current dialog
    if (trigger.interruptCurrent && controller.isDialogVisible) {
      controller.dismissDialog();
    }

    // Don't interrupt user interaction for non-critical triggers
    if (!trigger.interruptCurrent &&
        controller.state == MascotState.interacting) {
      return;
    }

    controller.showDialog(trigger.toDialogNode());
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

    final messageProvider = ref.read(mascotMessageProvider);
    final message = messageProvider.getRandomMessage();

    controller.showDialog(MascotDialogNode(
      id: 'random_speech',
      text: message.text,
      autoHide: true,
      autoHideDuration: _autoHideDuration,
      showDismissButton: false,
      suggestedAnimation: message.suggestedAnimation,
    ));
  }
}
