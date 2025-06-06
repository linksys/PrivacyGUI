import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

// TODO: Unused page

class NodeLightGuideView extends ConsumerWidget {
  const NodeLightGuideView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.read(nodeDetailProvider);
    final isCognitive = isCognitiveMeshRouter(
      modelNumber: node.modelNumber,
      hardwareVersion: node.hardwareVersion,
    );
    final isMixedNetwork =
        ref.read(deviceManagerProvider).nodeDevices.length > 1 &&
            ref.read(deviceManagerProvider).nodeDevices.any((node) =>
                isCognitive !=
                isCognitiveMeshRouter(
                    modelNumber: node.model.modelNumber ?? '',
                    hardwareVersion: node.model.hardwareVersion ?? ''));
    return StyledAppPageView(
      title: 'Light guide',
      appBarStyle: AppBarStyle.close,
      scrollable: true,
      child: (context, constraints) =>
          _buildContent(context, isCognitive, isMixedNetwork),
    );
  }

  Widget _buildContent(
      BuildContext context, bool isCognitive, bool isMixedNetwork) {
    if (isMixedNetwork) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('Cognitive Mesh'),
          _buildCognitiveMeshLightGuide(context),
          AppText.labelMedium('Intelligent Mesh'),
          _buildNodeMeshLightGuide(
            context,
          )
        ],
      );
    } else if (isCognitive) {
      return _buildCognitiveMeshLightGuide(context);
    } else {
      return _buildNodeMeshLightGuide(context);
    }
  }

  Widget _buildCognitiveMeshLightGuide(BuildContext context) {
    return Column(
      children: [
        _buildInfoCard(
          context,
          child: Column(
            children: [
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledWhiteSolid,
                title: 'White',
                desc: 'Online, everything is good',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledRedSolid,
                title: 'Red',
                desc: 'No internet',
              ),
            ],
          ),
        ),
        const AppGap.medium(),
        _buildInfoCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
                child: AppText.bodyLarge('During setup'),
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledBlueBlink,
                title: 'Blue (blinking)',
                desc: 'Powering on',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledBlueSolid,
                title: 'Blue',
                desc: 'Ready for setup',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledWhiteBlink,
                title: 'White (blinking)',
                desc: 'Setup in progress',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNodeMeshLightGuide(BuildContext context) {
    return Column(
      children: [
        _buildInfoCard(
          context,
          child: Column(
            children: [
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledBlueSolid,
                title: 'Blue',
                desc: 'Online, everything is good',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledYellowSolid,
                title: 'Yellow',
                desc: 'Weak signal',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledRedSolid,
                title: 'Red',
                desc: 'No internet',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledRedBlink,
                title: 'Red',
                desc:
                    'Out of range. Move closer to another node. If it\'s your parent node, make sure it\'s connected to your modem.',
              ),
            ],
          ),
        ),
        const AppGap.medium(),
        _buildInfoCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
                child: AppText.bodyLarge('During setup'),
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledBlueBlink,
                title: 'Blue (blinking)',
                desc: 'Powering on',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledPurpleSolid,
                title: 'Purple',
                desc: 'Ready for setup',
              ),
              _buildLightInfo(
                led: CustomTheme.of(context).images.ledPurpleBlink,
                title: 'Purple (blinking)',
                desc: 'Setup in progress',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required Widget child,
  }) {
    return Card(
      child:
          Padding(padding: const EdgeInsets.all(Spacing.medium), child: child),
    );
  }

  Widget _buildLightInfo({
    required SvgLoader led,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture(led),
          const AppGap.small2(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(title),
                const AppGap.small3(),
                AppText.bodyMedium(
                  desc,
                  maxLines: 5,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
