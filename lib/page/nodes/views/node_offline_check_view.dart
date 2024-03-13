import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class NodeOfflineCheckView extends ArgumentsConsumerStatefulView {
  const NodeOfflineCheckView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeOfflineCheckView> createState() =>
      _NodeOfflineCheckViewState();
}

class _NodeOfflineCheckViewState extends ConsumerState<NodeOfflineCheckView> {
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(nodeDetailProvider);
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      scrollable: true,
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(),
              ),
            )
          : AppBasicLayout(
              header: BasicHeader(
                title: getAppLocalizations(context).node_offline_check_title,
              ),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Image(
                        image: CustomTheme.of(context).images.devices.getByName(
                              routerIconTestByModel(
                                  modelNumber: state.modelNumber),
                            ),
                        width: 74,
                        height: 74,
                      ),
                      const AppGap.regular(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyLarge(
                            state.location,
                          ),
                          AppText.bodyMedium(
                            getAppLocalizations(context).offline,
                          )
                        ],
                      )
                    ],
                  ),
                  const AppGap.big(),
                  AppText.bodyMedium(
                    getAppLocalizations(context).node_offline_power_is_on,
                  ),
                  const AppGap.semiSmall(),
                  AppText.bodyMedium(
                    getAppLocalizations(context)
                        .node_offline_power_is_on_description,
                  ),
                  const AppGap.regular(),
                  AppText.bodyMedium(
                    getAppLocalizations(context).node_offline_within_range,
                  ),
                  const AppGap.semiSmall(),
                  AppText.bodyMedium(
                    getAppLocalizations(context)
                        .node_offline_within_range_description,
                  ),
                  const AppGap.regular(),
                  AppText.bodyMedium(
                    getAppLocalizations(context).node_offline_still_offline,
                  ),
                  const AppGap.semiSmall(),
                  AppText.bodyMedium(
                    getAppLocalizations(context)
                        .node_offline_still_offline_description,
                  ),
                  const AppGap.big(),
                  GestureDetector(
                    onTap: () {
                      showAdaptiveDialog(
                        context: context,
                        builder: (context) => AlertDialog.adaptive(
                          title: const AppText.bodyLarge('Disconnect Node'),
                          content: const AppText.bodyLarge(
                              'Do you want to remove this node from your network?'),
                          actions: [
                            AppTextButton(
                              'Remove this node',
                              onTap: () {
                                context.pop();
                                setState(() {
                                  isLoading = true;
                                });
                                final targetId =
                                    ref.read(deviceDetailIdProvider);
                                ref
                                    .read(deviceManagerProvider.notifier)
                                    .deleteDevices(deviceIds: [targetId]).then(
                                        (value) {
                                  setState(() {
                                    isLoading = false;
                                    context.goNamed(RouteNamed.settingsNodes);
                                  });
                                }).onError((error, stackTrace) {
                                  logger.e(error.toString());
                                  setState(() {
                                    isLoading = false;
                                  });
                                });
                              },
                            ),
                            AppTextButton('Keep this node', onTap: () {
                              context.pop();
                            })
                          ],
                        ),
                      );
                    },
                    child: AppText.bodyMedium(
                      getAppLocalizations(context).remove_node_from_network,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
