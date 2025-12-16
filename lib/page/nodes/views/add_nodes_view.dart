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
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/views/light_different_color_modal.dart';
import 'package:privacy_gui/page/nodes/views/light_info_tile.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/card/node_list_card.dart';
import 'package:privacygui_widgets/widgets/dialogs/multiple_page_alert_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    if (state.isLoading) {
      final message = _getLoadingMessages(state.loadingMessage ?? '');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoader(),
              AppGap.lg(),
              AppText.titleMedium(message.$1),
              AppGap.sm(),
              AppText.bodyMedium(message.$2),
            ],
          ),
        ),
      );
    } else {
      if (state.onboardingProceed != null) {
        return _resultView(state);
      } else {
        return _contentView();
      }
    }
  }

  Widget _resultView(AddNodesState state) {
    return UiKitPageView.withSliver(
      title: loc(context).addNodes,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              AppText.bodyMedium(loc(context).pnpYourNetworkDesc),
              AppButton.text(
                label: loc(context).refresh,
                onTap: () {
                  logger.d('[AddNodes]: Start to refresh the children list');
                  ref.read(addNodesProvider.notifier).startRefresh();
                },
              ),
            ],
          ),
          AppGap.lg(),
          if (state.addedNodes?.isEmpty == true)
            GestureDetector(
              key: const ValueKey('troubleshoot'),
              onTap: () => _showTroubleshootNoNodesFoundModal(),
              child: AppText.bodyMedium(
                loc(context).addNodesNoNodesFound,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          AppGap.lg(),
          Column(
            children: [
              if (state.addedNodes?.isNotEmpty ?? false)
                ...state.childNodes?.map((e) {
                      final node = LinksysDevice.fromMap(e.toMap());
                      return AppNodeListCard(
                          leading: CustomTheme.of(context).getRouterImage(
                              routerIconTestByModel(
                                  modelNumber: node.modelNumber ?? ''),
                              false),
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
                      yield AppGap.lg();
                    }).toList() ??
                    []
            ],
          ),
          AppGap.lg(),
          AppButton.text(
            label: loc(context).tryAgain,
            onTap: () {
              logger.d('[AddNodes]: Retry to search for more nodes');
              ref.read(addNodesProvider.notifier).startAutoOnboarding();
            },
          ),
          AppGap.xxxl(),
          AppButton(
            label: loc(context).next,
            variant: SurfaceVariant.highlight,
            onTap: () {
              final callback = widget.args['callback'] as VoidCallback?;
              if (callback != null) {
                callback.call();
                context.pop(state.addedNodes?.isNotEmpty ?? false);
              } else {
                context.pop(state.addedNodes?.isNotEmpty ?? false);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _contentView() {
    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).addNodes,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStyledText(text: loc(context).addNodesDesc),
          AppGap.xxl(),
          SvgPicture(
            CustomTheme.of(context).images.imgAddNodes,
            semanticsLabel: 'add nodes image',
          ),
          LightInfoImageTile(
              image:
                  SvgPicture(CustomTheme.of(context).images.nodeLightSolidBlue),
              content: AppStyledText(text: loc(context).addNodesSolidBlueDesc)),
          AppGap.lg(),
          AppButton.text(
            key: const ValueKey('differentColorModal'),
            label: loc(context).addNodesLightDifferentColor,
            onTap: () {
              _showLightDifferentColorModal();
            },
          ),
          AppGap.xxxl(),
          AppButton(
            label: loc(context).next,
            variant: SurfaceVariant.highlight,
            onTap: () {
              logger.d('[AddNodes]: Start to search for more nodes');
              ref.read(addNodesProvider.notifier).startAutoOnboarding();
            },
          )
        ],
      ),
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
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 24, child: AppText.bodyMedium('1.')),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppText.bodyMedium(loc(context)
                                          .modalTroubleshootNoNodesFoundDesc1),
                                      AppGap.lg(),
                                      AppButton.text(
                                        label: loc(context)
                                            .addNodesLightDifferentColor,
                                        onTap: () {
                                          controller.goTo(index + 1);
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppGap.xxl(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 24, child: AppText.bodyMedium('2.')),
                                Expanded(
                                  child: AppText.bodyMedium(loc(context)
                                      .modalTroubleshootNoNodesFoundDesc2),
                                ),
                              ],
                            ),
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
              AppButton.text(
                label: loc(context).close,
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
      'onboarding' => (
          loc(context).addNodesOnboardingNodes,
          loc(context).addNodesOnboardingNodesDesc,
        ),
      _ => (
          loc(context).addNodesSearchingNodes,
          loc(context).addNodesSearchingNodesDesc
        )
    };
  }
}
