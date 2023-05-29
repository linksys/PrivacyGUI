import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/auth_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/provider/select_network_provider.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/service/cloud_network_service.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/icon_rules.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../components/styled/styled_page_view.dart';

class SelectNetworkView extends ArgumentsConsumerStatefulView {
  const SelectNetworkView({super.key});

  @override
  ConsumerState<SelectNetworkView> createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends ConsumerState<SelectNetworkView> {
  late final NetworkCubit _networkCubit;
  late final NavigationNotifier _navigationNotifier;

  @override
  void initState() {
    _networkCubit = context.read<NetworkCubit>();
    _navigationNotifier = ref.read(navigationsProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SelectNetworkModel> model =
        CloudNetworkService(ref).watchSelectNetwork();
    return model.when(data: (state) {
      return StyledAppPageView(
        scrollable: true,
        isCloseStyle: true,
        onBackTap: () {
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

  Widget _networkSection(SelectNetworkModel state, {String title = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.tags(
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
                      await _networkCubit.selectNetwork(state.networks[index]);
                      _navigationNotifier.clearAndPush(PrepareDashboardPath());
                    }
                  : null,
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
                        AppText.descriptionMain(
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
      ],
    );
  }
}
