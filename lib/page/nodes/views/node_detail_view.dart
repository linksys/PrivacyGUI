import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/page/nodes/views/connected_device_widget.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/device_info_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'package:collection/collection.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_widgets/widgets/progress_bar/spinner.dart';

class NodeDetailView extends ArgumentsConsumerStatefulView {
  const NodeDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeDetailView> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends ConsumerState<NodeDetailView> {
  @override
  void initState() {
    super.initState();
    if (isServiceSupport(JNAPService.routerLEDs3)) {
      ref.read(nodeDetailProvider.notifier).getLEDLight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeDetailProvider);

    return LayoutBuilder(
      builder: (context, constraint) {
        return ResponsiveLayout(
          desktop: _desktopLayout(constraint, state),
          mobile: _mobileLayout(constraint, state),
        );
      },
    );
  }

  Widget _desktopLayout(BoxConstraints constraint, NodeDetailState state) {
    return StyledAppPageView(
      padding: const EdgeInsets.only(),
      title: loc(context).router,
      scrollable: true,
      child: AppBasicLayout(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: infoTab(state),
            ),
            const AppGap.regular(),
            Expanded(
                child: deviceTab(
                    state, constraint.maxHeight - kDefaultToolbarHeight))
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(BoxConstraints constraint, NodeDetailState state) {
    return StyledAppTabPageView(
      title: loc(context).router,
      tabs: [
        Tab(
          text: loc(context).info,
          height: 24,
        ),
        Tab(
          text: loc(context).devices,
          height: 24,
        ),
      ],
      tabContentViews: [
        StyledAppPageView(
          appBarStyle: AppBarStyle.none,
          scrollable: true,
          child: infoTab(state),
        ),
        StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            scrollable: true,
            child:
                deviceTab(state, constraint.maxHeight - kDefaultToolbarHeight))
      ],
      expandedHeight: 120,
    );
  }

  Widget infoTab(NodeDetailState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppGap.semiSmall(),
        _avatarCard(state),
        const AppGap.regular(),
        _detailSection(state),
        const AppGap.regular(),
        _lightCard(state),
        const Spacer(),
      ],
    );
  }

  Widget deviceTab(NodeDetailState state, double listHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.labelLarge(
            loc(context).nDevices(state.connectedDevices.length)),
        const AppGap.semiSmall(),
        SizedBox(
          height: listHeight,
          child: ConnectedDeviceListWidget(
            devices: state.connectedDevices,
            physics: const NeverScrollableScrollPhysics(),
            onItemClick: (item) {
              ref.read(deviceDetailIdProvider.notifier).state = item.deviceID;
              context.pushNamed(RouteNamed.deviceDetails);
            },
          ),
        ),
      ],
    );
  }

  Widget _avatarCard(NodeDetailState state) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        // height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Image(
                  height: 120,
                  image: CustomTheme.of(context).images.devices.getByName(
                        routerIconTestByModel(modelNumber: state.modelNumber),
                      ),
                ),
              ),
            ),
            AppCard(
              showBorder: false,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.labelLarge(state.location),
                  AppIconButton(
                    icon: LinksysIcons.edit,
                    onTap: () {
                      _showEditNodeNameDialog(state);
                    },
                  ),
                ],
              ),
            ),
            // const AppGap.regular(),
            AppDeviceInfoCard(
              title: loc(context).connectTo,
              description: _checkEmptyValue(state.upstreamDevice),
              showBorder: false,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lightCard(NodeDetailState state) {
    final hasBlinkFunction = isServiceSupport(JNAPService.setup9);
    bool isSupportNightModeOnly = isServiceSupport(JNAPService.routerLEDs3);
    bool isSupportNodeLight = isServiceSupport(JNAPService.routerLEDs4);
    if (!hasBlinkFunction && !isSupportNightModeOnly && !isSupportNodeLight) {
      return const Center();
    }
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._createNodeLightTile(state.nodeLightSettings),
        ...hasBlinkFunction
            ? [
                const AppGap.regular(),
                const BlinkNodeLightWidget(),
              ]
            : [],
      ],
    ));
  }

  String _checkEmptyValue(String? value) {
    if (value == null) {
      return '--';
    }
    if (value.isEmpty) {
      return '--';
    }
    return value;
  }

  List<Widget> _createNodeLightTile(NodeLightSettings? nodeLightSettings) {
    bool isSupportNightModeOnly = isServiceSupport(JNAPService.routerLEDs3);
    bool isSupportNodeLight = isServiceSupport(JNAPService.routerLEDs4);
    if (!isSupportNodeLight && !isSupportNightModeOnly) {
      return [];
    } else {
      final title = isSupportNodeLight ? 'Node Light' : 'Night Mode';
      return [
        AppDeviceInfoCard(
          title: title,
          showBorder: false,
          padding: EdgeInsets.zero,
          trailing: AppText.bodySmall(
            NodeLightStatus.getStatus(nodeLightSettings).resolveString(context),
          ),
          onTap: () {
            context.pushNamed(RouteNamed.nodeLightSettings);
          },
        ),
      ];
    }
  }

  Widget _detailSection(NodeDetailState state) {
    final updateInfo = (ref.read(firmwareUpdateProvider).nodesStatus?.length ??
                0) >
            1
        ? ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus
            ?.firstWhereOrNull((element) => element is NodesFirmwareUpdateStatus
                ? element.deviceUUID == state.deviceId
                : false)))
        : ref.watch(firmwareUpdateProvider
            .select((value) => value.nodesStatus?.firstOrNull));
    final isFwUpToDate = updateInfo?.availableUpdate == null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDeviceInfoCard(
            showBorder: false,
            padding: EdgeInsets.zero,
            title: getAppLocalizations(context).ipAddress,
            description: state.lanIpAddress,
          ),
          if (state.isMaster) ...[
            const AppGap.semiSmall(),
            AppDeviceInfoCard(
              showBorder: false,
              padding: EdgeInsets.zero,
              title: getAppLocalizations(context).ipAddress,
              description: state.wanIpAddress,
            ),
          ],
          // AppDeviceInfoCard(
          //   title: loc(context).serialNumber,
          //   description: _checkEmptyValue(state.serialNumber),
          // ),
          // AppDeviceInfoCard(
          //   title: loc(context).modelNumber,
          //   description: _checkEmptyValue(state.modelNumber),
          // ),
          const AppGap.semiSmall(),

          AppDeviceInfoCard(
            showBorder: false,
            padding: EdgeInsets.zero,
            title:
                getAppLocalizations(context).node_detail_label_firmware_version,
            description: _checkEmptyValue(state.firmwareVersion),
            trailing: Visibility(
                visible: isFwUpToDate,
                replacement: AppText.bodyLarge(
                    updateInfo?.availableUpdate?.firmwareVersion ?? ''),
                child: AppText.labelSmall(
                    getAppLocalizations(context).up_to_date)),
          ),
          const AppGap.regular(),
          AppTextButton(
            loc(context).moreInfo,
            padding: const EdgeInsets.all(4),
            onTap: () {
              _showMoreRouterInfoModal(state);
            },
          )
        ],
      ),
    );
  }

  Future _showEditNodeNameDialog(NodeDetailState state) {
    final textController = TextEditingController()..text = state.location;
    final hasBlinkFunction = isServiceSupport(JNAPService.setup9);
    return showDialog(
        context: context,
        builder: (context) {
          bool isLoading = false;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: AppText.titleLarge(loc(context).nodeName),
              actions: isLoading
                  ? null
                  : [
                      AppTextButton.noPadding(
                        loc(context).cancel,
                        color: Theme.of(context).colorScheme.onSurface,
                        onTap: () {
                          context.pop();
                        },
                      ),
                      AppTextButton(
                        loc(context).save,
                        onTap: () async {
                          setState(() {
                            isLoading = true;
                          });
                          await ref
                              .read(nodeDetailProvider.notifier)
                              .updateDeviceName(textController.text);
                          setState(() {
                            isLoading = false;
                          });
                        },
                      ),
                    ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isLoading
                    ? [
                        const Center(
                          child: AppSpinner(
                            size: Size(200, 200),
                          ),
                        ),
                      ]
                    : [
                        AppTextField(
                          headerText: loc(context).nodeName,
                          border: const OutlineInputBorder(),
                          controller: textController,
                        ),
                        if (hasBlinkFunction) ...[
                          const AppGap.regular(),
                          const BlinkNodeLightWidget(),
                        ],
                      ],
              ),
            );
          });
        });
  }

  Future<void> _showMoreRouterInfoModal(NodeDetailState state) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).moreInfo.camelCapitalized()),
            actions: [
              AppTextButton.noPadding(
                loc(context).close,
                onTap: () {
                  context.pop();
                },
              )
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).model),
                AppText.bodyMedium(state.modelNumber),
                const AppGap.regular(),
                AppText.labelLarge(
                    loc(context).serialNumber.camelCapitalized()),
                AppText.bodyMedium(state.serialNumber),
              ],
            ),
          );
        });
  }
}

class BlinkNodeLightWidget extends ConsumerStatefulWidget {
  final int max;
  final EdgeInsets? padding;
  const BlinkNodeLightWidget({
    super.key,
    this.max = 20,
    this.padding,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BlinkNodeLightWidgetState();
}

class _BlinkNodeLightWidgetState extends ConsumerState<BlinkNodeLightWidget> {
  int _count = 0;
  bool _isBlinking = false;
  late StreamSubscription subscription;

  Stream<int> startCounting() =>
      Stream<int>.periodic(const Duration(seconds: 1), (count) => count)
          .take(widget.max);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(4.0),
      child: _isBlinking
          ? AppStyledText.link(
              loc(context).nodeDetailBlinkingCounting(_count),
              defaultTextStyle: Theme.of(context).textTheme.bodySmall!,
              tags: const ['u'],
              callbackTags: {
                'u': (String? text, Map<String?, String?> attrs) {
                  setState(() {
                    _isBlinking = false;
                  });
                  subscription.cancel();
                }
              },
            )
          : AppTextButton.noPadding(
              loc(context).nodeDetailBlinkNodeLightBtn,
              onTap: () {
                setState(() {
                  _count = widget.max;
                  _isBlinking = true;
                });
                subscription = startCounting()
                    .map((event) => widget.max - event)
                    .listen((event) {
                  setState(() {
                    _count = event;
                  });
                }, onDone: () {
                  setState(() {
                    _isBlinking = false;
                  });
                  subscription.cancel();
                });
              },
            ),
    );
  }
}
