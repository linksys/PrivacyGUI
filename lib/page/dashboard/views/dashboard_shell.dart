// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/remote_assistance/remote_assistance_dialog.dart';

import 'package:privacy_gui/page/components/views/arguments_view.dart';

import 'package:privacy_gui/page/components/pwa/install_prompt_banner.dart';

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
  bool _isRemoteSessionDialogShown = false;

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
    ref.listen(
      remoteClientProvider.select((state) => state.sessionInfo?.status),
      (prevStatus, nextStatus) {
        logger.i(
            '[DashboardShell]: session status changed: $prevStatus -> $nextStatus');
        final loginType = ref.read(authProvider).value?.loginType;
        if (loginType != LoginType.local) return;
        if (prevStatus != GRASessionStatus.active &&
            nextStatus == GRASessionStatus.active &&
            !_isRemoteSessionDialogShown) {
          logger.i('[DashboardShell]: showing remote assistance dialog');
          _isRemoteSessionDialogShown = true;
          showRemoteAssistanceDialog(context, ref, isPassive: true).then((_) {
            _isRemoteSessionDialogShown = false;
          });
        }
      },
    );
    return _contentView();
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
        Expanded(child: widget.child),
        const InstallPromptBanner(),
      ],
    );
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
