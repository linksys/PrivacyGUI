import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/icon_rules.dart';
import 'package:linksys_widgets/theme/data/colors.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/event.dart';
import '../../../bloc/subscription/subscription_cubit.dart';
import '../../components/styled/styled_page_view.dart';

class SelectNetworkView extends ArgumentsStatefulView {
  const SelectNetworkView({
    Key? key,
  }) : super(key: key);

  @override
  State<SelectNetworkView> createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends State<SelectNetworkView> {
  // TODO: #REFACTOR : Need to refactor this page, only for demo now
  bool isLoading = false;
  late final NetworkCubit _networkCubit;
  late final SubscriptionCubit _subscriptionCubit;
  late final NavigationCubit _navigationCubit;

  @override
  void initState() {
    _networkCubit = context.read<NetworkCubit>();
    _subscriptionCubit = context.read<SubscriptionCubit>();
    _navigationCubit = NavigationCubit.of(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LinksysFullScreenSpinner(
            text: getAppLocalizations(context).processing)
        : BlocBuilder<NetworkCubit, NetworkState>(
            builder: (context, state) => StyledLinksysPageView(
                  scrollable: true,
                  isCloseStyle: true,
                  onBackTap: () {
                    context.read<AuthBloc>().add(Logout());
                  },
                  child: LinksysBasicLayout(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    content: _networkSection(state, title: 'Network'),
                  ),
                ));
  }

  Widget _networkSection(NetworkState state, {String title = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinksysText.tags(
          title,
        ),
        const LinksysGap.small(),
        SizedBox(
          height: 92.0 * state.networks.length,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.networks.length,
            itemBuilder: (context, index) => InkWell(
              onTap: state.networks[index].isOnline
                  ? () async {
                      setState(() {
                        isLoading = true;
                      });
                      await _networkCubit.selectNetwork(state.networks[index]);
                      await _subscriptionCubit.loadingProducts();
                      _navigationCubit.clearAndPush(PrepareDashboardPath());
                    }
                  : null,
              child: AppPadding(
                padding: const LinksysEdgeInsets.symmetric(
                    vertical: AppGapSize.regular),
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
                    const LinksysGap.semiBig(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinksysText.descriptionMain(
                          state.networks[index].network.friendlyName,
                          color: state.networks[index].isOnline
                              ? null
                              : ConstantColors.textBoxTextGray,
                        ),
                        const LinksysGap.small(),
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
