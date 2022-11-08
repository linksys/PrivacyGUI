import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/_route.dart';

import '../../../../bloc/network/cubit.dart';
import '../../../../bloc/subscription/subscription_cubit.dart';
import '../../../../bloc/subscription/subscription_state.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../util/logger.dart';

class SecuritySubscribeView extends StatelessWidget {
  const SecuritySubscribeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Linksys Secure',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            box16(),
            Text(
              '\$ XX.00 billed annually',
              style: Theme.of(context).textTheme.headline2?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            box36(),
            BlocListener<SubscriptionCubit, SubscriptionState>(
              listener: (context, state) {
                if(state.subscriptionOrderResponse !=null && state.networkEntitlementResponse != null) {
                  context.read<SecurityBloc>().add(SetFormalActiveEvent());
                  context.read<NavigationCubit>().popTo(DashboardSecurityPath());
                }
              },
              child: PrimaryButton(
                text: 'Subscribe',
                onPress: () {
                  //TODO resume real subscription
                  // final item =
                  //     context.read<SubscriptionCubit>().state.products?.first;
                  // logger.d(
                  //     'subscription products : ${context.read<SubscriptionCubit>().state.products?.length}');
                  // String serialNumber = context
                  //     .read<NetworkCubit>()
                  //     .state
                  //     .selected!
                  //     .deviceInfo
                  //     .serialNumber;
                  // if (item != null) {
                  //   context.read<SubscriptionCubit>().buy(item, serialNumber);
                  // }
                  context.read<SecurityBloc>().add(SetFormalActiveEvent());
                },
              ),
            ),
            const SizedBox(
              height: 88,
            ),
            Text(
              'What’s included in my subscription?',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            box16(),
            Text(
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            box16(),
            Text(
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            box16(),
            Text(
              'Cancel anytime',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            box16(),
            Text(
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            box24(),
            Text(
              'By continuing, you agree to the Linksys SecureTerms of Service and End-User License Agreement. View our Privacy Policy.',
              style: Theme.of(context).textTheme.headline4?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
    );
  }
}
