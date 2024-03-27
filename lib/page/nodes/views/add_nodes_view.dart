import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/nodes/providers/add_nodes_provider.dart';
import 'package:linksys_app/page/nodes/providers/add_nodes_state.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class AddNodesView extends ArgumentsConsumerStatefulView {
  const AddNodesView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<AddNodesView> createState() => _AddNodesViewState();
}

class _AddNodesViewState extends ConsumerState<AddNodesView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(addNodesProvider.notifier).getAutoOnboardingSettings();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addNodesProvider);
    return state.when(
        error: (error, stackTrace) {
          // error handling
          return _contentView();
        },
        data: (state) {
          if (state.nodesSnapshot != null) {
            return _resultView();
          } else {
            return _contentView();
          }
        },
        loading: () => AppFullScreenSpinner(
              title: 'Searching for Nodes...',
              text: 'Watch for node lights to change',
            ));
  }

  Widget _resultView() {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).addNodes,
      child: AppBasicLayout(
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 400,
          ),
          const AppGap.regular(),
          AppTextButton.noPadding(
            loc(context).try_again_button,
            onTap: () {},
          ),
          const AppGap.big(),
          AppFilledButton(
            loc(context).next,
            onTap: () {},
          )
        ],
      )),
    );
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).addNodes,
      child: AppBasicLayout(
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStyledText.bold(loc(context).addNodesDesc,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              tags: const ['b']),
          const AppGap.semiBig(),
          SvgPicture(CustomTheme.of(context).images.imgAddNodes),
          _createLightInfoTile(
              ledBlue,
              AppStyledText.bold(loc(context).addNodesSolidBlueDesc,
                  defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                  tags: const ['b'])),
          const AppGap.regular(),
          AppTextButton.noPadding(
            loc(context).addNodesLightDifferentColor,
            onTap: () {
              _showLightDifferentColorModal();
            },
          ),
          const AppGap.big(),
          AppFilledButton(
            loc(context).next,
            onTap: () {
              ref.read(addNodesProvider.notifier).startAutoOnboarding();
            },
          )
        ],
      )),
    );
  }

  _showLightDifferentColorModal() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            actions: [
              AppTextButton.noPadding(
                loc(context).close,
                onTap: () {
                  context.pop();
                },
              )
            ],
            title:
                AppText.headlineSmall(loc(context).addNodesLightDifferentColor),
            content: Container(
              constraints: BoxConstraints(maxWidth: 312),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.labelLarge(
                      loc(context).modalLightDifferentSeeRedLightDesc),
                  const AppGap.semiBig(),
                  _createLightInfoTile(
                    ledBlue,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(loc(context).solidBlue),
                        AppText.bodyMedium(loc(context).readyForSetup)
                      ],
                    ),
                  ),
                  const AppGap.semiBig(),
                  _createLightInfoTile(
                    ledPurple,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(loc(context).solidPurple),
                        AppText.bodyMedium(loc(context).readyForSetup)
                      ],
                    ),
                  ),
                  const AppGap.semiBig(),
                  _createLightInfoTile(
                    ledRed,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalLightDifferentSeeRedLight),
                        AppText.bodyMedium(
                            loc(context).modalLightDifferentSeeRedLightDesc)
                      ],
                    ),
                  ),
                  const AppGap.semiBig(),
                  AppText.labelLarge(
                      loc(context).modalLightDifferentToFactoryReset),
                  const AppGap.semiBig(),
                  AppBulletList(
                      style: AppBulletStyle.number,
                      itemSpacing: 24,
                      children: [
                        AppStyledText.bold(
                            loc(context).modalLightDifferentToFactoryResetStep1,
                            defaultTextStyle:
                                Theme.of(context).textTheme.bodyMedium!,
                            tags: const ['b']),
                        AppStyledText.bold(
                            loc(context).modalLightDifferentToFactoryResetStep2,
                            defaultTextStyle:
                                Theme.of(context).textTheme.bodyMedium!,
                            tags: const ['b']),
                      ]),
                ],
              ),
            ),
          );
        });
  }

  Widget _createLightInfoTile(Color color, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _createLightCircle(color),
        const AppGap.regular(),
        Flexible(
          child: content,
        )
      ],
    );
  }

  Widget _createLightCircle(Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              width: 3, color: Theme.of(context).colorScheme.outline)),
    );
  }
}
