import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Enters recovery mode, shows a spinner dialog while probing the router,
/// and auto-dismisses when recovery completes or the user bails out.
///
/// Call this after a mutation that causes the router to restart (WiFi change,
/// reboot, factory reset, firmware upgrade, etc.).
Future<void> showRecoveryDialog(
  BuildContext context,
  WidgetRef ref, {
  required RecoveryTrigger trigger,
  Duration cooldown = const Duration(seconds: 20),
  bool healthOnly = false,
  bool skipEnterWaiting = false,
  String? title,
  String? message,
  String? successMessage,
}) async {
  logger
      .d('[Recovery] showRecoveryDialog: trigger=$trigger, cooldown=$cooldown, '
          'healthOnly=$healthOnly, skipEnterWaiting=$skipEnterWaiting');

  if (!skipEnterWaiting) {
    ref.read(appConnectionStateProvider.notifier).enterWaiting(
          context: RecoveryContext(
            trigger: trigger,
            cooldown: cooldown,
            healthOnly: healthOnly,
          ),
        );
  }

  final navigator = Navigator.of(context, rootNavigator: true);

  final sub = ref.listenManual(appConnectionStateProvider, (prev, next) {
    logger.d('[Recovery] appConnectionState changed: $prev -> $next');
    if (next == AppConnectionState.authenticated) {
      logger.d('[Recovery] Popping recovery dialog (recovered)');
      navigator.pop();
    }
    // loggedOut: don't pop — route redirect will replace the entire page stack
  });

  logger.d('[Recovery] Showing recovery dialog');
  await showAppSpinnerDialog(
    context,
    title: title ?? 'Router is applying changes',
    messages: [
      message ??
          'Your Wi-Fi network may restart. Please reconnect to your router\'s network if needed.',
    ],
    actions: [
      AppButton.text(
        label: 'Return to login page',
        onTap: () {
          logger.d('[Recovery] User tapped Return to login');
          ref.read(appConnectionStateProvider.notifier).exitToLogout();
        },
      ),
    ],
  );
  logger.d('[Recovery] Recovery dialog dismissed');

  sub.close();

  if (!context.mounted) return;

  if (ref.read(appConnectionStateProvider) ==
      AppConnectionState.authenticated) {
    logger.d('[Recovery] Recovery successful');
    if (successMessage != null) {
      showSuccessSnackBar(context, successMessage);
    }
  }
}
