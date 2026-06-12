import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/pwa/install_prompt_banner.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/components/views/arguments_view.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_banner.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_dialog.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class DashboardShell extends ArgumentsConsumerStatefulView {
  const DashboardShell({
    Key? key,
    required this.child,
    super.args,
  }) : super(key: key);

  final Widget child;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  bool _raCheckDone = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to orchestrator completion for RA session restore
    ref.listen(dashboardOrchestratorProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue && !_raCheckDone) {
        _raCheckDone = true;
        _checkRemoteAssistanceSession();
      }
    });

    // Watch RA state to show blocking dialog for ACTIVE status
    final raState = ref.watch(remoteClientProvider);
    final raStatus = raState.sessionInfo?.status;

    // Show blocking dialog for ACTIVE status (after restore)
    if (raStatus == GRASessionStatus.active && _raCheckDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showActiveSessionDialog();
      });
    }

    return _contentView();
  }

  Future<void> _checkRemoteAssistanceSession() async {
    // Skip for Remote Assistance mode (CA side)
    final loginType = ref.read(authProvider).value?.loginType;
    if (loginType == LoginType.remote) return;

    // Get device credentials from unified provider
    final credentials = ref.read(deviceCredentialsProvider);
    if (credentials == null) return;

    // Set credentials and check for session
    final notifier = ref.read(remoteClientProvider.notifier);
    notifier.setCredentials(credentials);
    await notifier.checkAndRestoreSession();
  }

  void _showActiveSessionDialog() {
    final raState = ref.read(remoteClientProvider);
    if (raState.sessionInfo?.status != GRASessionStatus.active) return;

    // Check if dialog is already showing
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ActiveSessionRestoredDialog(),
    );
  }

  Widget _contentView() {
    return Scaffold(
      body: _buildLayout(),
      bottomNavigationBar: MenuHolder(type: MenuDisplay.bottom),
    );
  }

  Widget _buildLayout() {
    return Column(
      children: [
        // Remote Assistance Banner (for PENDING status after refresh)
        const RemoteAssistanceBanner(),
        Expanded(child: widget.child),
        const InstallPromptBanner(),
      ],
    );
  }
}

/// Dialog shown when an ACTIVE RA session is restored after page refresh.
class _ActiveSessionRestoredDialog extends ConsumerWidget {
  const _ActiveSessionRestoredDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RemoteAssistanceActiveDialog();
  }
}

class DashboardNaviItem {
  const DashboardNaviItem({
    required this.icon,
    required this.type,
    required this.rootPath,
  });

  final IconData icon;
  final NaviType type;
  final String rootPath;
}
