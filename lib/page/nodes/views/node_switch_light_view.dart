import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeSwitchLightView extends ArgumentsConsumerStatefulView {
  const NodeSwitchLightView({super.key, super.args});

  @override
  ConsumerState<NodeSwitchLightView> createState() =>
      _NodeSwitchLightViewState();
}

class _NodeSwitchLightViewState extends ConsumerState<NodeSwitchLightView> {
  NodeLightStatus? _nodeLightStatus = NodeLightStatus.off;
  bool _isSupportLed4 = false;
  bool _isSupportLed3 = false;

  @override
  void initState() {
    super.initState();
    _isSupportLed4 = isServiceSupport(JNAPService.routerLEDs4);
    _isSupportLed3 = isServiceSupport(JNAPService.routerLEDs3);
    _nodeLightStatus = NodeLightStatus.getStatus(
        ref.read(nodeDetailProvider).nodeLightSettings);
  }

  @override
  Widget build(BuildContext context) {
    final nodeLightSettings = ref.watch(nodeDetailProvider).nodeLightSettings;
    return StyledAppPageView(
      title: 'Node light',
      actions: _isSupportLed4
          ? [
              AppTextButton.noPadding(
                'Save',
                onTap: () {
                  NodeLightSettings settings;
                  if (_nodeLightStatus == NodeLightStatus.on) {
                    settings =
                        const NodeLightSettings(isNightModeEnable: false);
                  } else if (_nodeLightStatus == NodeLightStatus.off) {
                    settings = const NodeLightSettings(
                        isNightModeEnable: true, startHour: 0, endHour: 24);
                  } else {
                    settings = const NodeLightSettings(
                        isNightModeEnable: true, startHour: 20, endHour: 8);
                  }
                  ref.read(nodeDetailProvider.notifier).setLEDLight(settings);
                },
              )
            ]
          : [],
      child: Column(
        children: _buildNodeLightSettings(ref, nodeLightSettings),
      ),
    );
  }

  List<Widget> _buildNodeLightSettings(
      WidgetRef ref, NodeLightSettings? nodeLightSettings) {
    if (_isSupportLed4) {
      return [
        RadioListTile<NodeLightStatus>(
          title: const Text('Off'),
          value: NodeLightStatus.off,
          groupValue: _nodeLightStatus,
          onChanged: (NodeLightStatus? value) {
            setState(() {
              _nodeLightStatus = value;
            });
          },
        ),
        RadioListTile<NodeLightStatus>(
          title: const Text('Night mode (8PM - 8AM)'),
          value: NodeLightStatus.night,
          groupValue: _nodeLightStatus,
          onChanged: (NodeLightStatus? value) {
            setState(() {
              _nodeLightStatus = value;
            });
          },
        ),
        RadioListTile<NodeLightStatus>(
          title: const Text('On'),
          value: NodeLightStatus.on,
          groupValue: _nodeLightStatus,
          onChanged: (NodeLightStatus? value) {
            setState(() {
              _nodeLightStatus = value;
            });
          },
        ),
      ];
    } else {
      return [
        AppPanelWithSwitch(
          value: NodeLightStatus.getStatus(nodeLightSettings) ==
              NodeLightStatus.night,
          title: 'Night mode',
          onChangedEvent: (bool newValue) {
            ref
                .read(nodeDetailProvider.notifier)
                .setLEDLight(NodeLightSettings(isNightModeEnable: newValue));
          },
        ),
      ];
    }
  }
}
