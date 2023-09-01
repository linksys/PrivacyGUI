import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/base_components/progress_bars/indeterminate_progress_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeRestartView extends ConsumerStatefulWidget {
  const NodeRestartView({Key? key}) : super(key: key);

  @override
  ConsumerState<NodeRestartView> createState() => _NodeRestartViewState();
}

class _NodeRestartViewState extends ConsumerState<NodeRestartView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
        isCloseStyle: true,
        child: Visibility(
          visible: true,//TODO: Refactor the build with AsyncValue
          replacement: restartingIndicator(),
          child: restartConfirmation(),
        ),
      );
  }

  Widget restartConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/image_restart_disconnect.png',
        ),
        const AppGap.big(),
        const AppText.bodyLarge(
          'Restarting will temporarily disconnect devices',
        ),
        const AppGap.regular(),
        const AppText.bodyLarge(
          'They will reconnect when your network is ready.',
        ),
        const AppGap.big(),
        AppPrimaryButton(
          'Restart',
          onTap: () {
            //TODO: Reboot request
          },
        ),
        const AppGap.regular(),
        AppSecondaryButton(
          getAppLocalizations(context).cancel,
          onTap: () => context.pop(),
        ),
      ],
    );
  }

  Widget restartingIndicator() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGap.extraBig(),
        AppText.displayLarge(
          'Restarting your network...',
        ),
        AppGap.extraBig(),
        IndeterminateProgressBar(),
      ],
    );
  }
}
