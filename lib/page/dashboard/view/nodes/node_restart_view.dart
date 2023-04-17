import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class NodeRestartView extends ConsumerStatefulWidget {
  const NodeRestartView({Key? key}) : super(key: key);

  @override
  ConsumerState<NodeRestartView> createState() =>
      _NodeRestartViewState();
}

class _NodeRestartViewState extends ConsumerState<NodeRestartView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return BasePageView.withCloseButton(
        context, ref,
        child: Visibility(
          visible: !state.isSystemRestarting,
          child: restartConfirmation(),
          replacement: restartingIndicator(),
        ),
      );
    });
  }

  Widget restartConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/image_restart_disconnect.png',
        ),
        box36(),
        Text(
          'Restarting will temporarily disconnect devices',
          style: Theme.of(context).textTheme.headline2?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        box16(),
        Text(
          'They will reconnect when your network is ready.',
          style: Theme.of(context).textTheme.headline3,
        ),
        box36(),
        PrimaryButton(
          text: 'Restart',
          onPress: () {
            context.read<NodeCubit>().rebootMeshSystem();
          },
        ),
        box16(),
        SecondaryButton(
          text: getAppLocalizations(context).cancel,
          onPress: () => ref.read(navigationsProvider.notifier).pop(),
        ),
      ],
    );
  }

  Widget restartingIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box48(),
        Text(
          'Restarting your network...',
          style: Theme.of(context).textTheme.headline1?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        box48(),
        const IndeterminateProgressBar(),
      ],
    );
  }
}
