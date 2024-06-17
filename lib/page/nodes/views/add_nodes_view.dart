// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/card/node_list_card.dart';
import 'package:privacygui_widgets/widgets/dialogs/multiple_page_alert_dialog.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/views/light_different_color_modal.dart';
import 'package:privacy_gui/page/nodes/views/light_info_tile.dart';

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
    if (state.error != null) {
      // error handling
      logger.e(state.error);
      return _resultView(state);
    } else if (state.isLoading) {
      final message = _getLoadingMessages(state.loadingMessage ?? '');
      return AppFullScreenSpinner(
        title: message.$1,
        text: message.$2,
      );
    } else {
      if (state.onboardingProceed != null) {
        return _resultView(state);
      } else {
        return _contentView();
      }
    }
    // return state.err(error: (error, stackTrace) {
    //   // error handling
    //   logger.e(error, stackTrace: stackTrace);
    //   return _resultView(state.value);
    // }, data: (state) {
    //   if (state.onboardingProceed != null) {
    //     return _resultView(state);
    //   } else {
    //     return _contentView();
    //   }
    // }, loading: () {
    //   return AppFullScreenSpinner(
    //     title: loc(context).addNodesSearchingNodes,
    //     text: loc(context).addNodesSearchingNodesDesc,
    //   );
    // });
  }

  Widget _resultView(AddNodesState? state) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).addNodes,
      child: AppBasicLayout(
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state?.addedNodes?.isEmpty == true)
            AppStyledText.link(
              loc(context).addNodesNoNodesFound,
              key: const ValueKey('troubleshoot'),
              defaultTextStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Theme.of(context).colorScheme.error),
              color: Theme.of(context).colorScheme.primary,
              tags: const ['l'],
              callbackTags: {
                'l': (String? text, Map<String?, String?> attrs) {
                  _showTroubleshootNoNodesFoundModal();
                }
              },
            ),
          Column(
            children: [
              ...state?.childNodes
                      ?.map((e) => AppNodeListCard(
                          leading: CustomTheme.of(context)
                              .images
                              .devices
                              .getByName(routerIconTest(e.toMap())),
                          title: e.getDeviceLocation(),
                          trailing: null))
                      .toList() ??
                  []
            ],
          ),
          const AppGap.medium(),
          AppTextButton.noPadding(
            loc(context).tryAgain,
            onTap: () {
              ref.read(addNodesProvider.notifier).startAutoOnboarding();
            },
          ),
          const AppGap.large2(),
          AppFilledButton(
            loc(context).next,
            onTap: () {
              final callback = widget.args['callback'] as VoidCallback?;
              if (callback != null) {
                callback.call();
                context.pop(state?.addedNodes?.isNotEmpty ?? false);
              } else {
                context.pop(state?.addedNodes?.isNotEmpty ?? false);
              }
            },
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
          const AppGap.large1(),
          SvgPicture(CustomTheme.of(context).images.imgAddNodes),
          LightInfoTile(
              color: ledBlue,
              content: AppStyledText.bold(loc(context).addNodesSolidBlueDesc,
                  defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                  tags: const ['b'])),
          const AppGap.medium(),
          AppTextButton.noPadding(
            loc(context).addNodesLightDifferentColor,
            onTap: () {
              _showLightDifferentColorModal();
            },
          ),
          const AppGap.large2(),
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

  _showTroubleshootNoNodesFoundModal() {
    showDialog(
        context: context,
        builder: (context) {
          return MultiplePagesAlertDialog(
            onClose: () {
              context.pop();
            },
            pages: [
              MultipleAlertDialogPage(
                  title: loc(context).modalTroubleshootNoNodesFound,
                  buttonText: loc(context).close,
                  contentBuilder: (context, controller, index) {
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 312),
                      child: AppBulletList(
                          style: AppBulletStyle.number,
                          itemSpacing: 24,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText.bodyMedium(loc(context)
                                    .modalTroubleshootNoNodesFoundDesc1),
                                const AppGap.medium(),
                                AppTextButton.noPadding(
                                  loc(context).addNodesLightDifferentColor,
                                  onTap: () {
                                    controller.goTo(index + 1);
                                  },
                                )
                              ],
                            ),
                            AppText.bodyMedium(loc(context)
                                .modalTroubleshootNoNodesFoundDesc2),
                          ]),
                    );
                  }),
              MultipleAlertDialogPage(
                  title: loc(context).addNodesLightDifferentColor,
                  buttonText: loc(context).back,
                  contentBuilder: (BuildContext context,
                          MultiplePagesAlertDialogController controller,
                          int current) =>
                      const LightDifferentColorModal()),
            ],
          );
        });
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
              constraints: const BoxConstraints(maxWidth: 312),
              child: const LightDifferentColorModal(),
            ),
          );
        });
  }

  (String, String) _getLoadingMessages(String key) {
    return switch (key) {
      'searching' => (
          loc(context).addNodesSearchingNodes,
          loc(context).addNodesSearchingNodesDesc
        ),
      'onboarding' => ('Onboarding nodes', 'Bringing your nodes online'),
      _ => (
          loc(context).addNodesSearchingNodes,
          loc(context).addNodesSearchingNodesDesc
        )
    };
  }
}
