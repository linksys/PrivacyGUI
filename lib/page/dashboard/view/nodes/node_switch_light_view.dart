import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/devices/node_detail_provider.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeSwitchLightView extends ConsumerWidget {
  const NodeSwitchLightView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      title: 'Node light',
      child: Column(
        children: [
          AppPanelWithSwitch(
            value: ref.watch(nodeDetailProvider).isLightTurnedOn,
            title: 'Node light',
            onChangedEvent: (bool newValue) {
              ref.read(nodeDetailProvider.notifier).toggleNodeLight(newValue);
            },
          ),
        ],
      ),
    );
  }
}
