// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/card/node_list_card.dart';
import 'package:privacygui_widgets/widgets/dialogs/multiple_page_alert_dialog.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/views/light_different_color_modal.dart';

class AddWiredNodesView extends ArgumentsConsumerStatefulView {
  const AddWiredNodesView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<AddWiredNodesView> createState() => _AddWiredNodesViewState();
}

class _AddWiredNodesViewState extends ConsumerState<AddWiredNodesView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addWiredNodesProvider);
    if (state.isLoading) {
      final message = _getLoadingMessages(state.loadingMessage ?? '');
      return Stack(
        children: [
          AppFullScreenSpinner(
            title: message.$1,
            text: message.$2,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: AppFilledButton(
              loc(context).ok,
              onTap: () {
                ref.read(addWiredNodesProvider.notifier).stopCheckingBackhaul();
              },
            ),
          )
        ],
      );
    } else {
      if (state.onboardingProceed != null) {
        return _resultView(state);
      } else {
        return _contentView();
      }
    }
  }

  Widget _resultView(AddWiredNodesState? state) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).addNodes,
      child: AppBasicLayout(
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText.bodyMedium(loc(context).pnpYourNetworkDesc),
              const AppGap.small1(),
              AppTextButton.noPadding(
                loc(context).refresh,
                onTap: () {
                  logger
                      .d('[AddWiredNode]: Start to refresh the children list');
                  ref.read(addWiredNodesProvider.notifier).startRefresh();
                },
              ),
            ],
          ),
          const AppGap.medium(),
          if (state?.nodes?.isEmpty == true)
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
          const AppGap.medium(),
          Column(
            children: [
              ...state?.nodes?.map((e) {
                    final node = LinksysDevice.fromMap(e.toMap());
                    return AppNodeListCard(
                        leading: CustomTheme.of(context)
                            .images
                            .devices
                            .getByName(routerIconTest(e.toMap())),
                        title: e.getDeviceLocation(),
                        trailing: SharedWidgets.resolveSignalStrengthIcon(
                          context,
                          node.signalDecibels ?? 0,
                          isOnline: node.isOnline(),
                          isWired: node.getConnectionType() ==
                              DeviceConnectionType.wired,
                        ));
                  }).expandIndexed((index, element) sync* {
                    yield element;
                    yield const AppGap.medium();
                  }).toList() ??
                  []
            ],
          ),
          const AppGap.large3(),
          AppFilledButton(
            loc(context).next,
            onTap: () {
              final callback = widget.args['callback'] as VoidCallback?;
              if (callback != null) {
                callback.call();
                context.pop(state?.nodes?.isNotEmpty ?? false);
              } else {
                context.pop(state?.nodes?.isNotEmpty ?? false);
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
          AppBulletList(
            style: AppBulletStyle.number,
            children: [
              AppText.bodyLarge(loc(context).addWiredDevicesDesc1),
              AppText.bodyLarge(loc(context).addWiredDevicesDesc2),
              AppText.bodyLarge(loc(context).addWiredDevicesDesc3),
              AppText.bodyLarge(loc(context).addWiredDevicesDesc4),
            ],
          ),
          const AppGap.large2(),
          SvgPicture(
            CustomTheme.of(context).images.imgPlaceWiredNodes,
            semanticsLabel: 'add nodes image',
          ),
          const AppGap.large3(),
          AppFilledButton(
            loc(context).next,
            onTap: () {
              logger.d('[AddNodes]: Start to search for more nodes');
              ref.read(addWiredNodesProvider.notifier).startAutoOnboarding();
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
