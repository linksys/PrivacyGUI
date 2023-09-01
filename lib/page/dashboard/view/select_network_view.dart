import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/provider/select_network_provider.dart';
import 'package:linksys_app/service/cloud_network_service.dart';
import 'package:linksys_app/util/analytics.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class SelectNetworkView extends ArgumentsConsumerStatefulView {
  const SelectNetworkView({super.key});

  @override
  ConsumerState<SelectNetworkView> createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends ConsumerState<SelectNetworkView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SelectNetworkState> model =
        CloudNetworkService(ref).watchSelectNetwork();
    return model.when(data: (state) {
      return StyledAppPageView(
        scrollable: true,
        isCloseStyle: true,
        onBackTap: ref.read(networkProvider).selected != null
            ? null
            : () {
                ref.read(authProvider.notifier).logout();
              },
        child: AppBasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: _networkSection(state, title: 'Network'),
        ),
      );
    }, error: (error, stackTrace) {
      return Center(
        child: Text('Error - $error'),
      );
    }, loading: () {
      return AppFullScreenSpinner(
          text: getAppLocalizations(context).processing);
    });
  }

  Widget _networkSection(SelectNetworkState state, {String title = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleLarge(
          title,
        ),
        const AppGap.small(),
        SizedBox(
          height: 92.0 * state.networks.length,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.networks.length,
            itemBuilder: (context, index) => InkWell(
              onTap: state.networks[index].isOnline
                  ? () async {
                      await ref
                          .read(networkProvider.notifier)
                          .selectNetwork(state.networks[index]);
                      // _navigationNotifier.clearAndPush(PrepareDashboardPath());
                      logEvent(
                        eventName: 'ActionSelectNetwork',
                        parameters: {
                          'networkId': state.networks[index].network.networkId,
                        },
                      );
                      context.goNamed('prepareDashboard');
                    }
                  : null,
              child: Opacity(
                opacity: state.networks[index].isOnline ? 1 : 0.4,
                child: AppPadding(
                  padding: const AppEdgeInsets.symmetric(
                    vertical: AppGapSize.regular,
                  ),
                  child: Row(
                    children: [
                      Image(
                        image: AppTheme.of(context).images.devices.getByName(
                              routerIconTest(
                                modelNumber: state
                                    .networks[index].network.routerModelNumber,
                                hardwareVersion: state.networks[index].network
                                    .routerHardwareVersion,
                              ),
                            ),
                        width: 60,
                        height: 60,
                      ),
                      const AppGap.semiBig(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyLarge(
                            state.networks[index].network.friendlyName,
                            color: state.networks[index].isOnline
                                ? null
                                : ConstantColors.textBoxTextGray,
                          ),
                          const AppGap.small(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
