import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

class SelectNetworkView extends ArgumentsStatefulView {
  const SelectNetworkView({
    Key? key,
  }) : super(key: key);

  @override
  _SelectNetworkViewState createState() => _SelectNetworkViewState();
}

class _SelectNetworkViewState extends State<SelectNetworkView> {
  // TODO: #REFACTOR : Need to refactor this page, only for demo now
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? FullScreenSpinner(text: getAppLocalizations(context).processing)
        : BlocBuilder<NetworkCubit, NetworkState>(
            builder: (context, state) => BasePageView.withCloseButton(
                  context,
                  child: BasicLayout(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    content: Column(
                      children: [
                        _networkSection(state, title: 'Network'),
                      ],
                    ),
                  ),
                ));
  }

  Widget _networkSection(NetworkState state, {String title = ''}) {
    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          box8(),
          ListView.builder(
            shrinkWrap: true,
            itemCount: state.networks.length,
            itemBuilder: (context, index) => InkWell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/icon_device.png',
                      width: 40,
                      height: 40,
                    ),
                    box24(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.networks[index].serialNumber,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        box4(),
                        Text(
                          state.networks[index].macAddress,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: () async {
                setState(() {
                  isLoading = true;
                });
                await context
                    .read<NetworkCubit>()
                    .selectNetwork(state.networks[index])
                    .then((value) => NavigationCubit.of(context)
                        .clearAndPush(PrepareDashboardPath()));
              },
            ),
          )
        ],
      ),
    );
  }
}
