import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/base_components/progress_bars/indeterminate_progress_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

// TODO: Unused page

class NodeRestartView extends ConsumerStatefulWidget {
  const NodeRestartView({Key? key}) : super(key: key);

  @override
  ConsumerState<NodeRestartView> createState() => _NodeRestartViewState();
}

class _NodeRestartViewState extends ConsumerState<NodeRestartView> {
  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: (context, constraints) => Visibility(
        visible: true, //TODO: Refactor the build with AsyncValue
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
        const AppGap.large3(),
        const AppText.bodyLarge(
          'Restarting will temporarily disconnect devices',
        ),
        const AppGap.medium(),
        const AppText.bodyLarge(
          'They will reconnect when your network is ready.',
        ),
        const AppGap.large3(),
        AppFilledButton(
          'Restart',
          onTap: () {
            //TODO: Reboot request
          },
        ),
        const AppGap.medium(),
        AppTextButton(
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
        AppGap.large5(),
        AppText.displayLarge(
          'Restarting your network...',
        ),
        AppGap.large5(),
        IndeterminateProgressBar(),
      ],
    );
  }
}
