import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_dialog.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Guards the dashboard for client-side Remote Assistance sessions.
///
/// After page refresh, if an ACTIVE RA session exists, this widget will
/// display a blocking dialog that prevents the user from interacting with
/// the dashboard until they end the session.
///
/// For PENDING sessions, only the [RemoteAssistanceBanner] is shown (non-blocking).
class RemoteAssistanceSessionGuard extends ConsumerStatefulWidget {
  final Widget child;

  const RemoteAssistanceSessionGuard({super.key, required this.child});

  @override
  ConsumerState<RemoteAssistanceSessionGuard> createState() =>
      _RemoteAssistanceSessionGuardState();
}

class _RemoteAssistanceSessionGuardState
    extends ConsumerState<RemoteAssistanceSessionGuard> {
  bool _checkDone = false;
  bool _dialogShowing = false;

  @override
  Widget build(BuildContext context) {
    // Skip in Remote Assistance mode (CA side)
    if (GlobalConfig.remote.isActive) {
      return widget.child;
    }

    // Listen to dashboard ready to trigger session check
    ref.listen(dashboardDomainReadyProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue && !_checkDone) {
        _checkDone = true;
        _checkAndRestoreSession();
      }
    });

    // Watch RA state to show blocking dialog for ACTIVE status
    final raState = ref.watch(remoteClientProvider);
    final raStatus = raState.sessionInfo?.status;

    // Show blocking dialog for ACTIVE status (after restore check completes)
    if (raStatus == GRASessionStatus.active && _checkDone && !_dialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showActiveSessionDialog();
      });
    }

    return widget.child;
  }

  Future<void> _checkAndRestoreSession() async {
    // Skip for Remote Assistance mode (CA side) - double check
    if (ref.read(authProvider).value?.isRemoteAssistance ?? false) return;

    // Get device credentials from unified provider
    final credentials = ref.read(deviceCredentialsProvider);
    if (credentials == null) return;

    // Set credentials and check for existing session
    final notifier = ref.read(remoteClientProvider.notifier);
    notifier.setCredentials(credentials);
    await notifier.checkAndRestoreSession();
  }

  void _showActiveSessionDialog() {
    if (_dialogShowing) return;

    final raState = ref.read(remoteClientProvider);
    if (raState.sessionInfo?.status != GRASessionStatus.active) return;

    _dialogShowing = true;

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RemoteAssistanceActiveDialog(),
    ).then((_) {
      _dialogShowing = false;
    });
  }
}
