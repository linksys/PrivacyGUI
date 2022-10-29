import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';

class SpeedTestView extends ArgumentsStatefulView {
  const SpeedTestView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends State<SpeedTestView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) => BasePageView(
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          header: const Text(
            'Speed Test',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: _content(state),
        ),
      ),
    );
  }

  Widget _content(NetworkState state) {
    return Column(
      children: [
        box48(),
        PrimaryButton(
          text: state.selected?.currentSpeedTestStatus == null
              ? 'Start speed test'
              : 'Testing',
          onPress: state.selected?.currentSpeedTestStatus == null
              ? () => context.read<NetworkCubit>().runHealthCheck()
              : null,
        ),
      ],
    );
  }
}
