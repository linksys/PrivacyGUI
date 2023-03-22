import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/gap.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'speed_test_button.dart';

class SpeedTestView extends ArgumentsStatefulView {
  const SpeedTestView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends State<SpeedTestView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _status = "IDLE";

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (_controller.isCompleted) {
          setState(() {
            _status = "COMPLETE";
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) => StyledLinksysPageView(
        child: LinksysBasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          header: const Text(
            'Speed Test',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: _content(context, state),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, NetworkState state) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AppTheme.of(context).images.speedtestBg,
              fit: BoxFit.fitWidth)),
      child: Stack(children: [
        Container(
          alignment: Alignment.bottomLeft,
          child: Image(
            image: AppTheme.of(context).images.speedtestPowered,
            fit: BoxFit.fitWidth,
          ),
        ),
        Container(
            alignment: Alignment.center,
            child: speedTestSection(context, _status))
      ]),
    );
  }

  Widget speedTestSection(BuildContext context, String status) {
    switch (status) {
      case "IDLE":
        return TriLayerButton(
          child: const Text('START'),
          onPressed: () {
            Future.delayed(const Duration(milliseconds: 500), () {
              setState(() {
                _status = "RUNNING";
                _controller.forward();
              });
              context.read<NetworkCubit>().runHealthCheck();
            });
          },
        );
      case "RUNNING":
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CircleProgressBar(
              progress: _animation.value,
              strokeWidth: 8.0,
              backgroundColor: Colors.white,
            );
          },
        );
      case "COMPLETE":
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                LinksysText.subhead('Upload'),
                LinksysText.subhead('Download'),
              ],
            ),
            const LinksysGap.regular(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                LinksysText.subhead('98Mbps'),
                LinksysText.subhead('24Mpbs'),
              ],
            ),
          ],
        );
      default:
        return Container();
    }
  }
}
